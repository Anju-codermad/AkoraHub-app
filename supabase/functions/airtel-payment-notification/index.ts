// Edge Function : reçoit la confirmation de paiement envoyée par Airtel
// Money (callback configuré dans Application settings -> Callback
// Authentication sur le portail développeur) — endpoint public appelé
// directement par les serveurs Airtel, jamais par l'app.
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - AIRTEL_CALLBACK_PRIVATE_KEY (portail Airtel -> Mes Applications ->
//   Paramètres -> Callback Authentication -> clé privée ; distincte de
//   AIRTEL_CLIENT_SECRET)
// - AIRTEL_CLIENT_ID, AIRTEL_CLIENT_SECRET, AIRTEL_API_BASE_URL (déjà
//   présents, communs aux autres fonctions Airtel) : utilisés pour
//   redemander le statut à Airtel quand la signature ne peut pas être
//   vérifiée.
//
// Authenticité — deux niveaux :
// 1. Champ `hash` = Base64(HmacSHA256(message, clé privée)). Constaté en
//    production le 23/11 (callback de 15:13, « corps sans hash / clé
//    texte ») : Airtel Madagascar signe le JSON compact
//    {"transaction":{...}} — tout le corps SAUF le champ hash — avec la clé
//    telle qu'affichée (texte), et non l'objet transaction seul comme le
//    laisse entendre la doc. Les autres variantes restent essayées par
//    prudence (au cas où Airtel change de format).
// 2. Si aucune variante ne correspond : on NE fait PAS confiance au
//    contenu du callback, mais on redemande le statut directement à Airtel
//    (Transaction Enquiry, appel authentifié par nos identifiants). Seul ce
//    statut-là est enregistré. Un faux callback ne peut donc rien valider :
//    au pire il déclenche une vérification auprès d'Airtel, et seulement
//    pour une transaction qui existe chez nous.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function cleanEnv(name: string): string {
  return (Deno.env.get(name) ?? "").trim();
}
const AIRTEL_BASE_URL = (cleanEnv("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg").replace(/\/+$/, "");

function timingSafeEqual(a: string, b: string): boolean {
  const maxLength = Math.max(a.length, b.length);
  let diff = a.length === b.length ? 0 : 1;
  for (let i = 0; i < maxLength; i++) {
    diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  }
  return diff === 0;
}

// Texte EXACT d'un objet JSON tel qu'envoyé par Airtel (espaces et ordre
// compris), repéré par sa clé puis l'accolade fermante correspondante.
function rawObjectText(rawBody: string, keyName: string): string | null {
  const keyIndex = rawBody.search(new RegExp(`"${keyName}"\\s*:`));
  if (keyIndex === -1) return null;
  const start = rawBody.indexOf("{", keyIndex);
  if (start === -1) return null;
  let depth = 0;
  let inString = false;
  for (let i = start; i < rawBody.length; i++) {
    const c = rawBody[i];
    if (inString) {
      if (c === "\\") i++;
      else if (c === '"') inString = false;
      continue;
    }
    if (c === '"') inString = true;
    else if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return rawBody.slice(start, i + 1);
    }
  }
  return null;
}

function sortedJson(obj: Record<string, unknown>): string {
  const sorted: Record<string, unknown> = {};
  for (const k of Object.keys(obj).sort()) sorted[k] = obj[k];
  return JSON.stringify(sorted);
}

async function hmacBase64(message: string, keyBytes: Uint8Array): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)));
}

// Encodages possibles de la clé privée affichée sur le portail.
function keyVariants(privateKey: string): Array<[string, Uint8Array]> {
  const variants: Array<[string, Uint8Array]> = [["texte", new TextEncoder().encode(privateKey)]];
  if (/^[0-9a-f]+$/i.test(privateKey) && privateKey.length % 2 === 0) {
    variants.push(["hexadécimal", new Uint8Array(privateKey.match(/../g)!.map((h) => parseInt(h, 16)))]);
  }
  if (/^[A-Za-z0-9+/]+=*$/.test(privateKey) && privateKey.length % 4 === 0) {
    try {
      variants.push(["base64", Uint8Array.from(atob(privateKey), (c) => c.charCodeAt(0))]);
    } catch (_) { /* pas du base64 */ }
  }
  return variants;
}

// Renvoie le nom de la variante qui correspond, ou null.
async function verifyHash(
  rawBody: string,
  transaction: Record<string, unknown>,
  receivedHash: string,
  privateKey: string,
): Promise<string | null> {
  if (!privateKey) return null;
  // En premier : la variante confirmée en production (23/11).
  const messages: Array<[string, string]> = [
    ["corps sans hash", JSON.stringify({ transaction })],
    ["JSON transaction", JSON.stringify(transaction)],
  ];
  const rawTx = rawObjectText(rawBody, "transaction");
  if (rawTx) messages.push(["texte transaction reçu", rawTx]);
  messages.push(["transaction triée", sortedJson(transaction)]);
  const { hash: _ignored, ...bodyWithoutHash } = JSON.parse(rawBody);
  messages.push(["corps reçu sans hash", JSON.stringify(bodyWithoutHash)]);
  for (const field of ["id", "airtel_money_id"]) {
    if (typeof transaction[field] === "string") messages.push([`champ ${field}`, transaction[field] as string]);
  }
  for (const [keyName, keyBytes] of keyVariants(privateKey)) {
    for (const [messageName, message] of messages) {
      if (timingSafeEqual(await hmacBase64(message, keyBytes), receivedHash)) {
        return `${messageName} / clé ${keyName}`;
      }
    }
  }
  return null;
}

// Transaction Enquiry : statut officiel demandé directement à Airtel.
async function airtelEnquiry(transactionId: string): Promise<{ code: string; airtelMoneyId: string | null; message: string }> {
  const tokenRes = await fetch(`${AIRTEL_BASE_URL}/auth/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "*/*" },
    body: JSON.stringify({
      client_id: cleanEnv("AIRTEL_CLIENT_ID"),
      client_secret: cleanEnv("AIRTEL_CLIENT_SECRET"),
      grant_type: "client_credentials",
    }),
  });
  const tokenData = await tokenRes.json().catch(() => null);
  if (!tokenRes.ok || !tokenData?.access_token) {
    throw new Error(`Authentification Airtel refusée (HTTP ${tokenRes.status})`);
  }
  const res = await fetch(`${AIRTEL_BASE_URL}/standard/v1/payments/${encodeURIComponent(transactionId)}`, {
    method: "GET",
    headers: {
      "Accept": "*/*",
      "X-Country": "MG",
      "X-Currency": "MGA",
      "Authorization": `Bearer ${tokenData.access_token}`,
    },
  });
  const data = await res.json().catch(() => null);
  console.log("Vérification Airtel :", transactionId, "HTTP", res.status, JSON.stringify(data)?.slice(0, 300));
  const tx = data?.data?.transaction;
  return {
    code: String(tx?.status ?? "").toUpperCase(),
    airtelMoneyId: tx?.airtel_money_id ?? null,
    message: String(tx?.message ?? ""),
  };
}

// Où se trouve cette transaction chez nous : commande produit, acompte
// diagnostic-eau ou paiement direct (page « Payer Akora Fanadiovana »).
// public.payments en premier (table unique depuis la phase 310 : un
// trigger y reporte le statut sur la commande / l'acompte) ; les autres
// tables restent pour les paiements lancés avant cette phase.
const TARGETS = [
  { table: "payments", statusColumn: "status" },
  { table: "orders", statusColumn: "payment_status" },
  { table: "website_service_requests", statusColumn: "payment_status" },
  { table: "direct_payments", statusColumn: "status" },
] as const;

Deno.serve(async (req) => {
  try {
    const rawBody = await req.text();
    const payload = JSON.parse(rawBody);
    const transaction = payload.transaction as
      | { id?: string; status_code?: string; airtel_money_id?: string }
      | undefined;
    const receivedHash = payload.hash as string | undefined;

    if (!transaction?.id || !transaction?.status_code || !receivedHash) {
      return new Response("ignored", { status: 200 });
    }

    console.log("Callback Airtel reçu :", transaction.id, transaction.status_code);

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let found: { table: string; statusColumn: string; id: string; status: string } | null = null;
    for (const target of TARGETS) {
      const { data } = await supabaseAdmin
        .from(target.table)
        .select(`id, ${target.statusColumn}`)
        .eq("airtel_transaction_id", transaction.id)
        .maybeSingle();
      if (data) {
        const row = data as unknown as Record<string, string>;
        found = { table: target.table, statusColumn: target.statusColumn, id: row.id, status: row[target.statusColumn] };
        break;
      }
    }
    if (!found) {
      console.error("Commande/demande/paiement direct introuvable pour la transaction Airtel", transaction.id);
      return new Response("ok", { status: 200 });
    }
    // Déjà payé : rien à faire (et jamais de retour en arrière).
    if (found.status === "paye") return new Response("ok", { status: 200 });

    const privateKey = cleanEnv("AIRTEL_CALLBACK_PRIVATE_KEY");
    const matchedVariant = await verifyHash(rawBody, transaction as Record<string, unknown>, receivedHash, privateKey);

    let code: string;
    let airtelMoneyId: string | null;
    let airtelMessage = "";
    if (matchedVariant) {
      console.log("Signature Airtel valide :", matchedVariant);
      code = transaction.status_code.toUpperCase();
      airtelMoneyId = transaction.airtel_money_id ?? null;
    } else {
      // Signature non vérifiable : le contenu du callback est ignoré, le
      // statut vient uniquement d'Airtel.
      console.log(
        "Signature Airtel non reconnue (clé : " + privateKey.length + " car.) -> vérification directe auprès d'Airtel",
      );
      try {
        const enquiry = await airtelEnquiry(transaction.id);
        code = enquiry.code;
        airtelMoneyId = enquiry.airtelMoneyId;
        airtelMessage = enquiry.message;
      } catch (e) {
        console.error("Vérification Airtel impossible :", e);
        return new Response("ok", { status: 200 });
      }
    }

    // TS = réussi ; TF = échoué ; TE = expiré. Tout autre code : en cours.
    let newStatus: string | null = null;
    if (code === "TS") newStatus = "paye";
    if (code === "TF" || code === "TE") newStatus = "echoue";
    if (!newStatus || newStatus === found.status) return new Response("ok", { status: 200 });

    const update: Record<string, unknown> = {
      [found.statusColumn]: newStatus,
      airtel_money_transaction_ref: airtelMoneyId,
    };
    if ((found.table === "direct_payments" || found.table === "payments") && newStatus === "echoue") {
      update.error_message = `Airtel : ${code} ${airtelMessage}`.trim();
    }
    await supabaseAdmin
      .from(found.table)
      .update(update)
      .eq("id", found.id)
      .or(`${found.statusColumn}.is.null,${found.statusColumn}.neq.paye`);
    console.log("Paiement Airtel enregistré :", found.table, found.id, "->", newStatus);

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
