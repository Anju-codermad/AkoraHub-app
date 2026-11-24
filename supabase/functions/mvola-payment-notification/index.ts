// Edge Function mvola-payment-notification : adresse de retour (callback)
// appelée par MVola quand un paiement marchand est terminé (préparée le
// 24/11, voir payment-mvola et phase312_patch_mvola_en_ligne.sql).
//
// MVola NE SIGNE PAS ses callbacks. Deux protections :
// 1. l'adresse de retour contient ?p=<id du paiement>&s=<signature>,
//    signature HMAC-SHA256 calculée par payment-mvola avec
//    MVOLA_CALLBACK_SECRET : une adresse inventée est refusée ;
// 2. le contenu du callback n'est jamais cru : le statut est toujours
//    redemandé à MVola (GET .../status/{serverCorrelationId}) avant
//    d'enregistrer quoi que ce soit.
// Répond toujours 200 (un faux appel ne mérite qu'une ligne de journal).
// "Verify JWT" désactivé : appelée par les serveurs MVola.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function cleanEnv(name: string): string {
  return (Deno.env.get(name) ?? "").trim();
}
const MVOLA_BASE_URL = (cleanEnv("MVOLA_API_BASE_URL") || "https://devapi.mvola.mg").replace(/\/+$/, "");
const MERCHANT_PATH = "/mvola/mm/transactions/type/merchantpay/1.0.0";

function timingSafeEqual(a: string, b: string): boolean {
  const maxLength = Math.max(a.length, b.length);
  let diff = a.length === b.length ? 0 : 1;
  for (let i = 0; i < maxLength; i++) diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  return diff === 0;
}

async function hmacHex(message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(cleanEnv("MVOLA_CALLBACK_SECRET") || cleanEnv("SUPABASE_SERVICE_ROLE_KEY")),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function getMvolaToken(): Promise<string> {
  const basic = btoa(`${cleanEnv("MVOLA_CONSUMER_KEY")}:${cleanEnv("MVOLA_CONSUMER_SECRET")}`);
  const res = await fetch(`${MVOLA_BASE_URL}/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "Cache-Control": "no-cache",
    },
    body: "grant_type=client_credentials&scope=EXT_INT_MVOLA_SCOPE",
  });
  const data = await res.json().catch(() => null);
  if (!res.ok || !data?.access_token) throw new Error(`Authentification MVola refusée (HTTP ${res.status})`);
  return data.access_token as string;
}

const ok = () => new Response("ok", { status: 200 });

Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);
    const paymentId = url.searchParams.get("p") ?? "";
    const signature = url.searchParams.get("s") ?? "";
    const rawBody = await req.text().catch(() => "");
    console.log("Callback MVola reçu :", req.method, paymentId, rawBody.slice(0, 300));

    if (!/^[0-9a-f-]{36}$/i.test(paymentId) || !timingSafeEqual(await hmacHex(paymentId), signature)) {
      console.error("Callback MVola refusé : adresse de retour non signée ou invalide");
      return ok();
    }

    const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: payment } = await db
      .from("payments")
      .select("id, status, method, provider_correlation_id")
      .eq("id", paymentId)
      .maybeSingle();
    if (!payment || payment.method !== "mvola") {
      console.error("Paiement MVola introuvable :", paymentId);
      return ok();
    }
    if (payment.status !== "en_attente") return ok();

    // serverCorrelationId : enregistré au lancement ; à défaut, celui du callback.
    let correlationId = payment.provider_correlation_id as string | null;
    if (!correlationId) {
      try { correlationId = JSON.parse(rawBody)?.serverCorrelationId ?? null; } catch (_) { /* corps non JSON */ }
    }
    if (!correlationId) return ok();

    const token = await getMvolaToken();
    const res = await fetch(`${MVOLA_BASE_URL}${MERCHANT_PATH}/status/${encodeURIComponent(correlationId)}`, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Version": "1.0",
        "X-CorrelationID": crypto.randomUUID(),
        "UserLanguage": "FR",
        "UserAccountIdentifier": `msisdn;${cleanEnv("MVOLA_MERCHANT_NUMBER")}`,
        "partnerName": cleanEnv("MVOLA_PARTNER_NAME") || "Akora Fanadiovana",
        "Cache-Control": "no-cache",
      },
    });
    const data = await res.json().catch(() => null);
    console.log("Vérification MVola :", correlationId, "HTTP", res.status, JSON.stringify(data)?.slice(0, 300));
    const raw = String(data?.status ?? "").toLowerCase();
    let newStatus: string | null = null;
    if (raw === "completed" || raw === "success") newStatus = "paye";
    if (raw === "failed" || raw === "rejected" || raw === "cancelled") newStatus = "echoue";
    if (!newStatus) return ok();

    await db
      .from("payments")
      .update({
        status: newStatus,
        provider_correlation_id: correlationId,
        provider_transaction_ref: data?.objectReference ? String(data.objectReference) : null,
        ...(newStatus === "echoue" ? { error_message: `MVola : ${raw}` } : {}),
      })
      .eq("id", payment.id)
      .eq("status", "en_attente");
    console.log("Paiement MVola enregistré :", payment.id, "->", newStatus);
    return ok();
  } catch (e) {
    console.error(e);
    return ok();
  }
});
