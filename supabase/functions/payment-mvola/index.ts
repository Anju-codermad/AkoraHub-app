// Edge Function payment-mvola : paiement MVola en ligne (API Merchant Pay
// de Telma) depuis la page de paiement unique du site — commandes (avec
// ou sans compte), acomptes, liens de paiement. Préparée le 24/11 en
// attendant les identifiants API MVola ; même fonctionnement que
// payment-airtel (table public.payments, phase310 + phase312).
//
// Actions (body JSON) : identiques à payment-airtel
//   { action: "start", source, targetId?, payerName?, reference?, amount?, phone, website? }
//   { action: "check", paymentId }   -> statut redemandé à MVola
//
// Format de l'API (guide MVola, confirmé par les SDK publics « mvola » et
// « mvola-client ») :
//   POST {base}/token  (Basic base64(key:secret), grant_type=client_credentials,
//                       scope=EXT_INT_MVOLA_SCOPE)
//   POST {base}/mvola/mm/transactions/type/merchantpay/1.0.0/
//   GET  {base}/mvola/mm/transactions/type/merchantpay/1.0.0/status/{serverCorrelationId}
// MVola ne signe pas ses callbacks : l'adresse de retour porte une
// signature (MVOLA_CALLBACK_SECRET) et le statut est toujours redemandé à
// MVola avant d'enregistrer un paiement (voir mvola-payment-notification).
//
// Secrets (Supabase -> Edge Functions -> Secrets) :
//   MVOLA_CONSUMER_KEY, MVOLA_CONSUMER_SECRET  : identifiants API MVola
//   MVOLA_MERCHANT_NUMBER : numéro du compte marchand (ex. 0341234567)
//   MVOLA_PARTNER_NAME    : nom du partenaire (ex. Akora Fanadiovana)
//   MVOLA_API_BASE_URL    : https://api.mvola.mg (production) ou l'adresse
//                           de test (sandbox) donnée par MVola
//   MVOLA_CALLBACK_SECRET : texte aléatoire long (signature des retours)
// "Verify JWT" désactivé : appelée aussi par des visiteurs sans compte.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function cleanEnv(name: string): string {
  return (Deno.env.get(name) ?? "").trim();
}
const MVOLA_BASE_URL = (cleanEnv("MVOLA_API_BASE_URL") || "https://devapi.mvola.mg").replace(/\/+$/, "");
const MERCHANT_PATH = "/mvola/mm/transactions/type/merchantpay/1.0.0";

const MIN_AMOUNT = 100;
const MAX_AMOUNT = Number(cleanEnv("MVOLA_MAX_AMOUNT")) || 5_000_000;
const MAX_PER_NUMBER_15_MIN = 3;
const MAX_TOTAL_PER_HOUR = 60;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

// Numéro MVola (Telma) : 034 ou 038, au format local 0341234567.
function normalizeMvolaMsisdn(raw: string): string | null {
  let local = raw.replace(/\D/g, "");
  if (local.startsWith("261")) local = local.slice(3);
  if (local.startsWith("0")) local = local.slice(1);
  return /^3[48]\d{7}$/.test(local) ? `0${local}` : null;
}

function isUuid(v: unknown): v is string {
  return typeof v === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
}

// descriptionText : 50 caractères max, sans caractères spéciaux sauf - . _ ,
function cleanText(s: string, max = 50): string {
  return s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^A-Za-z0-9 ,._-]/g, " ")
    .replace(/\s+/g, " ").trim().slice(0, max);
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
  const text = await res.text();
  let data: Record<string, unknown> | null = null;
  try { data = JSON.parse(text); } catch (_) { /* réponse non JSON */ }
  if (!res.ok || !data?.access_token) {
    // MVola renvoie parfois l'identifiant dans ses erreurs : jamais de clé dans le journal.
    const safe = text.split(cleanEnv("MVOLA_CONSUMER_KEY") || "§").join("[clé]").slice(0, 200);
    throw new Error(`Authentification MVola refusée (HTTP ${res.status}) ${safe}`);
  }
  return data.access_token as string;
}

function merchantHeaders(token: string): Record<string, string> {
  return {
    "Authorization": `Bearer ${token}`,
    "Version": "1.0",
    "X-CorrelationID": crypto.randomUUID(),
    "UserLanguage": "FR",
    "UserAccountIdentifier": `msisdn;${cleanEnv("MVOLA_MERCHANT_NUMBER")}`,
    "partnerName": cleanEnv("MVOLA_PARTNER_NAME") || "Akora Fanadiovana",
    "Cache-Control": "no-cache",
  };
}

async function hmacHex(message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(cleanEnv("MVOLA_CALLBACK_SECRET") || cleanEnv("SUPABASE_SERVICE_ROLE_KEY")),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function adminClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
}

// Statut MVola -> statut de payments ("completed" | "failed" | "pending").
async function refreshMvolaPayment(db: ReturnType<typeof adminClient>, payment: {
  id: string; status: string; provider_correlation_id: string | null; created_at: string;
}): Promise<string> {
  if (payment.status !== "en_attente" || !payment.provider_correlation_id) return payment.status;
  const token = await getMvolaToken();
  const res = await fetch(`${MVOLA_BASE_URL}${MERCHANT_PATH}/status/${encodeURIComponent(payment.provider_correlation_id)}`, {
    method: "GET",
    headers: merchantHeaders(token),
  });
  const data = await res.json().catch(() => null);
  console.log("Vérification MVola :", payment.provider_correlation_id, "HTTP", res.status, JSON.stringify(data)?.slice(0, 300));
  const raw = String(data?.status ?? "").toLowerCase();
  let newStatus: string | null = null;
  if (raw === "completed" || raw === "success") newStatus = "paye";
  if (raw === "failed" || raw === "rejected" || raw === "cancelled") newStatus = "echoue";
  if (!newStatus) return "en_attente";
  await db
    .from("payments")
    .update({
      status: newStatus,
      provider_transaction_ref: data?.objectReference ? String(data.objectReference) : null,
      ...(newStatus === "echoue" ? { error_message: `MVola : ${raw}` } : {}),
    })
    .eq("id", payment.id)
    .eq("status", "en_attente");
  return newStatus;
}

async function checkPayment(paymentId: string): Promise<Record<string, unknown>> {
  if (!isUuid(paymentId)) return { status: "inconnu" };
  const db = adminClient();
  const { data: payment } = await db
    .from("payments")
    .select("id, status, method, mode, provider_correlation_id, created_at")
    .eq("id", paymentId)
    .maybeSingle();
  if (!payment || payment.method !== "mvola") return { status: payment ? payment.status : "inconnu" };
  if (payment.status !== "en_attente" || payment.mode !== "en_ligne") return { status: payment.status };
  const ageMs = Date.now() - new Date(payment.created_at).getTime();
  if (ageMs < 10_000 || ageMs > 30 * 60_000) return { status: payment.status };
  try {
    return { status: await refreshMvolaPayment(db, payment) };
  } catch (e) {
    console.error("Vérification MVola impossible :", e);
    return { status: "en_attente" };
  }
}

type Target = {
  source: "commande" | "acompte" | "lien";
  orderId?: string;
  serviceRequestId?: string;
  customerId?: string | null;
  reference: string | null;
  payerName: string | null;
  amount: number;
};

async function resolveTarget(req: Request, body: Record<string, unknown>): Promise<Target | Response> {
  const db = adminClient();
  const source = String(body.source ?? "");

  if (source === "commande") {
    if (!isUuid(body.targetId)) return json(400, { error: "Commande introuvable." });
    const { data: order } = await db
      .from("orders")
      .select("id, order_number, customer_id, guest_name, total_amount, payment_status")
      .eq("id", body.targetId)
      .maybeSingle();
    if (!order) return json(404, { error: "Commande introuvable." });
    let payerName: string | null = order.guest_name ?? null;
    // Commande d'un client connecté : réservée à ce client. Commande sans
    // compte (phase311, customer_id vide) : l'identifiant suffit.
    if (order.customer_id) {
      const authHeader = req.headers.get("Authorization") ?? "";
      const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: { user } } = await userClient.auth.getUser();
      if (!user) return json(401, { error: "Connectez-vous pour payer cette commande." });
      if (order.customer_id !== user.id) return json(404, { error: "Commande introuvable." });
      const { data: profile } = await db.from("profiles").select("full_name").eq("id", user.id).maybeSingle();
      payerName = profile?.full_name ?? null;
    }
    if (order.payment_status === "paye") return json(409, { error: "Cette commande est déjà payée." });
    return {
      source: "commande", orderId: order.id, customerId: order.customer_id ?? null, reference: order.order_number,
      payerName, amount: Math.round(Number(order.total_amount)),
    };
  }

  if (source === "acompte") {
    if (!isUuid(body.targetId)) return json(400, { error: "Demande introuvable." });
    const { data: request } = await db
      .from("website_service_requests")
      .select("id, name, proforma_number, deposit_amount, payment_status")
      .eq("id", body.targetId)
      .maybeSingle();
    if (!request) return json(404, { error: "Demande introuvable." });
    if (request.payment_status === "paye") return json(409, { error: "Cet acompte est déjà payé." });
    return {
      source: "acompte", serviceRequestId: request.id, reference: request.proforma_number ?? "Acompte diagnostic eau",
      payerName: request.name ?? null, amount: Math.round(Number(request.deposit_amount)),
    };
  }

  if (source === "lien") {
    const payerName = String(body.payerName ?? "").trim().slice(0, 120);
    if (!payerName) return json(400, { error: "Indiquez votre nom." });
    return {
      source: "lien", reference: String(body.reference ?? "").trim().slice(0, 60) || null,
      payerName, amount: Math.round(Number(body.amount)),
    };
  }

  return json(400, { error: "Origine du paiement invalide." });
}

async function startPayment(req: Request, body: Record<string, unknown>): Promise<Response> {
  if (typeof body.website === "string" && body.website.trim() !== "") {
    return json(200, { paymentId: crypto.randomUUID(), msisdn: "" });
  }
  if (!cleanEnv("MVOLA_CONSUMER_KEY") || !cleanEnv("MVOLA_MERCHANT_NUMBER")) {
    return json(503, { error: "Le paiement MVola en ligne n'est pas encore disponible." });
  }
  const msisdn = normalizeMvolaMsisdn(String(body.phone ?? ""));
  if (!msisdn) {
    return json(400, { error: "Numéro MVola invalide : il doit commencer par 034 ou 038 (ex. 034 12 345 67)." });
  }

  const target = await resolveTarget(req, body);
  if (target instanceof Response) return target;
  if (!Number.isFinite(target.amount) || target.amount < MIN_AMOUNT || target.amount > MAX_AMOUNT) {
    return json(400, {
      error: `Montant invalide pour MVola (entre ${MIN_AMOUNT} et ${MAX_AMOUNT.toLocaleString("fr-FR")} Ar).`,
    });
  }

  const db = adminClient();
  const { data: setting } = await db
    .from("payment_method_settings")
    .select("enabled")
    .eq("method_id", "mvola")
    .maybeSingle();
  if (setting && setting.enabled === false) {
    return json(403, { error: "Le paiement MVola est momentanément indisponible." });
  }

  const since15 = new Date(Date.now() - 15 * 60 * 1000).toISOString();
  const since60 = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const [{ count: recentForNumber }, { count: recentTotal }] = await Promise.all([
    db.from("payments").select("id", { count: "exact", head: true })
      .eq("mode", "en_ligne").eq("payer_phone", msisdn).gte("created_at", since15),
    db.from("payments").select("id", { count: "exact", head: true })
      .eq("mode", "en_ligne").gte("created_at", since60),
  ]);
  if ((recentForNumber ?? 0) >= MAX_PER_NUMBER_15_MIN) {
    return json(429, { error: "Trop de demandes pour ce numéro. Réessayez dans quelques minutes." });
  }
  if ((recentTotal ?? 0) >= MAX_TOTAL_PER_HOUR) {
    return json(429, { error: "Service très sollicité. Réessayez un peu plus tard." });
  }

  const { data: payment, error: insertError } = await db
    .from("payments")
    .insert({
      source: target.source,
      order_id: target.orderId ?? null,
      service_request_id: target.serviceRequestId ?? null,
      customer_id: target.customerId ?? null,
      reference: target.reference,
      payer_name: target.payerName,
      payer_phone: msisdn,
      method: "mvola",
      mode: "en_ligne",
      amount: target.amount,
    })
    .select("id")
    .single();
  if (insertError || !payment) {
    throw new Error("Enregistrement du paiement impossible : " + insertError?.message);
  }

  // Référence de transaction : identifiant interne (50 car. max, sans
  // caractères spéciaux) — sert aussi de X-CorrelationID.
  const reference = `AKORA-${payment.id.replace(/-/g, "").slice(0, 24)}`;
  const callbackUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/mvola-payment-notification` +
    `?p=${payment.id}&s=${await hmacHex(payment.id)}`;
  const partnerName = cleanEnv("MVOLA_PARTNER_NAME") || "Akora Fanadiovana";

  try {
    const token = await getMvolaToken();
    const res = await fetch(`${MVOLA_BASE_URL}${MERCHANT_PATH}/`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Version": "1.0",
        "X-CorrelationID": reference,
        "UserLanguage": "FR",
        "UserAccountIdentifier": `msisdn;${msisdn}`,
        "partnerName": partnerName,
        "Content-Type": "application/json",
        "Cache-Control": "no-cache",
        "X-Callback-URL": callbackUrl,
      },
      body: JSON.stringify({
        amount: String(target.amount),
        currency: "Ar",
        descriptionText: cleanText(`Akora ${target.reference ?? "paiement"}`) || "Akora paiement",
        requestDate: new Date().toISOString(),
        debitParty: [{ key: "msisdn", value: msisdn }],
        creditParty: [{ key: "msisdn", value: cleanEnv("MVOLA_MERCHANT_NUMBER") }],
        // L'ordre compte : MVola lit ces métadonnées par position (guide API).
        metadata: [
          { key: "partnerName", value: partnerName },
          { key: "fc", value: "USD" },
          { key: "amountFc", value: "1" },
        ],
        requestingOrganisationTransactionReference: reference,
        originalTransactionReference: reference,
      }),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok || typeof data?.serverCorrelationId !== "string") {
      throw new Error(`HTTP ${res.status} ${JSON.stringify(data).slice(0, 400)}`);
    }
    await db.from("payments").update({ provider_correlation_id: data.serverCorrelationId }).eq("id", payment.id);
  } catch (mvolaError) {
    console.error("Échec de la demande de paiement MVola :", mvolaError);
    await db
      .from("payments")
      .update({ status: "echoue", error_message: String(mvolaError).slice(0, 1000) })
      .eq("id", payment.id);
    return json(502, { error: "Impossible d'envoyer la demande de paiement MVola. Réessayez." });
  }

  return json(200, { paymentId: payment.id, msisdn, amount: target.amount, fee: null });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS_HEADERS });
  if (req.method !== "POST") return json(405, { error: "Méthode non autorisée" });
  try {
    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    if (body.action === "check") return json(200, await checkPayment(String(body.paymentId ?? "")));
    if (body.action === "start") return await startPayment(req, body);
    return json(400, { error: "Action inconnue." });
  } catch (e) {
    console.error(e);
    return json(500, { error: "Erreur inattendue. Réessayez." });
  }
});
