// Edge Function : paiement Airtel Money direct depuis la page publique
// « Payer Akora Fanadiovana » (groupe-akora.com/payer) — demande explicite
// du 23/11 : le client saisit le montant et la référence de son devis /
// facture / commande WhatsApp, reçoit une notification sur son téléphone
// (push USSD) et l'argent arrive directement sur le wallet marchand
// Airtel. Pas de compte client nécessaire (comme la page devis).
//
// La confirmation finale arrive de façon asynchrone via
// airtel-payment-notification (callback Airtel), qui met à jour
// direct_payments.status ; la page suit l'avancement avec la fonction SQL
// get_direct_payment_status (voir phase309_patch_airtel_wallet_marchand.sql).
//
// Body JSON : { payerName, reference?, amount, phone, website? }
//   - website = champ piège invisible (anti-robot) : rempli -> ignoré.
// Réponse : { paymentId, msisdn } ou { error }.
//
// Anti-abus (page publique, et un push USSD sonne sur le téléphone de la
// personne visée) : au plus 3 demandes par numéro sur 15 minutes et 60
// demandes au total sur une heure ; montant borné.
//
// Secrets : les mêmes que create-airtel-payment-request (AIRTEL_CLIENT_ID,
// AIRTEL_CLIENT_SECRET, AIRTEL_API_BASE_URL) — rien de nouveau.
// "Verify JWT" désactivé : page publique, protections propres ci-dessous.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Valeurs nettoyées : un espace ou un retour à la ligne invisible collé
// avec une clé dans le Dashboard Supabase suffit à faire répondre
// « invalid_client » à Airtel (constaté le 23/11 en production).
function cleanEnv(name: string): string {
  return (Deno.env.get(name) ?? "").trim();
}
const AIRTEL_BASE_URL = (cleanEnv("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg").replace(/\/+$/, "");
const AIRTEL_CLIENT_ID = cleanEnv("AIRTEL_CLIENT_ID");
const AIRTEL_CLIENT_SECRET = cleanEnv("AIRTEL_CLIENT_SECRET");

// Pour le diagnostic (journal + administration) : jamais la clé en clair.
function mask(value: string): string {
  if (value.length <= 8) return `${"•".repeat(value.length)} (${value.length} car.)`;
  return `${value.slice(0, 4)}…${value.slice(-4)} (${value.length} car.)`;
}

const MIN_AMOUNT = 300; // Airtel refuse 100 Ar (« inférieur à la limite autorisée », test du 23/11) ; 300 Ar accepté.
const MAX_AMOUNT = 5_000_000;
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

// MSISDN sans indicatif (règle Airtel, comme create-airtel-payment-request),
// et uniquement un numéro Airtel Madagascar (033… ou 035…) : un push USSD Airtel
// envoyé vers un numéro Orange/Telma ne peut pas aboutir.
function normalizeMsisdn(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  let local = digits;
  if (local.startsWith("261")) local = local.slice(3);
  if (local.startsWith("0")) local = local.slice(1);
  if (!/^3[35]\d{7}$/.test(local)) return null;
  return local;
}

async function getAirtelAccessToken(): Promise<string> {
  const url = `${AIRTEL_BASE_URL}/auth/oauth2/token`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "*/*" },
    body: JSON.stringify({
      client_id: AIRTEL_CLIENT_ID,
      client_secret: AIRTEL_CLIENT_SECRET,
      grant_type: "client_credentials",
    }),
  });
  const text = await res.text();
  let data: Record<string, unknown> | null = null;
  try { data = JSON.parse(text); } catch (_) { /* réponse non JSON */ }
  if (!res.ok || !data?.access_token) {
    // Détail complet (sans secret) pour le support Airtel : requête,
    // statut HTTP, en-têtes utiles et corps de la réponse.
    const headersOfInterest = ["date", "server", "x-request-id", "x-correlation-id", "via"]
      .map((h) => res.headers.get(h) ? `${h}=${res.headers.get(h)}` : "")
      .filter(Boolean).join(", ");
    throw new Error(
      `Échec d'authentification Airtel : POST ${url} ` +
        `{client_id: ${mask(AIRTEL_CLIENT_ID)}, client_secret: ${mask(AIRTEL_CLIENT_SECRET)}, grant_type: client_credentials} ` +
        `-> HTTP ${res.status}${headersOfInterest ? ` [${headersOfInterest}]` : ""} ${text.slice(0, 300)}`,
    );
  }
  return data.access_token as string;
}

// Statuts Airtel : TS = réussi, TF = échoué, TE = expiré ; TIP / TA =
// en cours ou ambigu (on attend).
async function checkPaymentStatus(paymentId: string): Promise<{ status: string }> {
  if (!/^[0-9a-f-]{36}$/i.test(paymentId)) return { status: "inconnu" };
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: payment } = await supabaseAdmin
    .from("direct_payments")
    .select("id, status, airtel_transaction_id, created_at")
    .eq("id", paymentId)
    .maybeSingle();
  if (!payment) return { status: "inconnu" };
  if (payment.status !== "en_attente" || !payment.airtel_transaction_id) {
    return { status: payment.status };
  }
  // Rien à demander pendant les premières secondes, ni après 30 minutes.
  const ageMs = Date.now() - new Date(payment.created_at).getTime();
  if (ageMs < 10_000 || ageMs > 30 * 60_000) return { status: payment.status };

  try {
    const accessToken = await getAirtelAccessToken();
    const res = await fetch(
      `${AIRTEL_BASE_URL}/standard/v1/payments/${payment.airtel_transaction_id}`,
      {
        method: "GET",
        headers: {
          "Accept": "*/*",
          "X-Country": "MG",
          "X-Currency": "MGA",
          "Authorization": `Bearer ${accessToken}`,
        },
      },
    );
    const data = await res.json().catch(() => null);
    console.log("Vérification Airtel :", payment.airtel_transaction_id, "HTTP", res.status, JSON.stringify(data)?.slice(0, 300));
    const tx = data?.data?.transaction;
    const code = String(tx?.status ?? "").toUpperCase();
    let newStatus: string | null = null;
    if (code === "TS") newStatus = "paye";
    if (code === "TF" || code === "TE") newStatus = "echoue";
    if (!newStatus) return { status: "en_attente" };

    // Ne met à jour que si le callback n'est pas passé entre-temps.
    await supabaseAdmin
      .from("direct_payments")
      .update({
        status: newStatus,
        airtel_money_transaction_ref: tx?.airtel_money_id ?? null,
        ...(newStatus === "echoue" ? { error_message: `Airtel : ${code} ${tx?.message ?? ""}`.trim() } : {}),
      })
      .eq("id", payment.id)
      .eq("status", "en_attente");
    return { status: newStatus };
  } catch (e) {
    console.error("Vérification Airtel (enquiry) impossible :", e);
    return { status: "en_attente" };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") return json(405, { error: "Méthode non autorisée" });

  try {
    const body = await req.json().catch(() => ({}));

    // Vérification du statut auprès d'Airtel (« Transaction Enquiry »),
    // appelée par la page d'attente : ne dépend plus uniquement du callback
    // Airtel, qui peut tarder ou ne jamais arriver (constaté le 23/11).
    if (body.action === "check") {
      return json(200, await checkPaymentStatus(String(body.paymentId ?? "")));
    }

    // Robot : on répond comme si tout allait bien, sans rien déclencher.
    if (typeof body.website === "string" && body.website.trim() !== "") {
      return json(200, { paymentId: crypto.randomUUID(), msisdn: "" });
    }

    const payerName = String(body.payerName ?? "").trim().slice(0, 120);
    const reference = String(body.reference ?? "").trim().slice(0, 60);
    const amount = Math.round(Number(body.amount));
    const msisdn = normalizeMsisdn(String(body.phone ?? ""));

    if (!payerName) return json(400, { error: "Indiquez votre nom." });
    if (!Number.isFinite(amount) || amount < MIN_AMOUNT || amount > MAX_AMOUNT) {
      return json(400, {
        error: `Montant invalide (entre ${MIN_AMOUNT} et ${MAX_AMOUNT.toLocaleString("fr-FR")} Ar).`,
      });
    }
    if (!msisdn) {
      return json(400, { error: "Numéro Airtel Money invalide : il doit commencer par 033 ou 035 (ex. 033 12 345 67)." });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Airtel Money désactivé par l'Admin (Moyens de paiement) : rien
    // n'est envoyé.
    const { data: setting } = await supabaseAdmin
      .from("payment_method_settings")
      .select("enabled")
      .eq("method_id", "airtel_money")
      .maybeSingle();
    if (setting && setting.enabled === false) {
      return json(403, { error: "Le paiement Airtel Money est momentanément indisponible." });
    }

    const since15 = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    const since60 = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const [{ count: recentForNumber }, { count: recentTotal }] = await Promise.all([
      supabaseAdmin.from("direct_payments").select("id", { count: "exact", head: true })
        .eq("msisdn", msisdn).gte("created_at", since15),
      supabaseAdmin.from("direct_payments").select("id", { count: "exact", head: true })
        .gte("created_at", since60),
    ]);
    if ((recentForNumber ?? 0) >= MAX_PER_NUMBER_15_MIN) {
      return json(429, {
        error: "Trop de demandes pour ce numéro. Réessayez dans quelques minutes.",
      });
    }
    if ((recentTotal ?? 0) >= MAX_TOTAL_PER_HOUR) {
      return json(429, { error: "Service très sollicité. Réessayez un peu plus tard." });
    }

    // Identifiant de transaction Airtel : alphanumérique uniquement (un
    // UUID avec tirets a déjà été refusé par Airtel, statut TF).
    const airtelTransactionId = crypto.randomUUID().replace(/-/g, "");

    const { data: payment, error: insertError } = await supabaseAdmin
      .from("direct_payments")
      .insert({
        payer_name: payerName,
        reference: reference || null,
        amount,
        msisdn,
        airtel_transaction_id: airtelTransactionId,
      })
      .select("id")
      .single();
    if (insertError || !payment) {
      throw new Error("Enregistrement du paiement impossible : " + insertError?.message);
    }

    try {
      const accessToken = await getAirtelAccessToken();
      const paymentRes = await fetch(`${AIRTEL_BASE_URL}/merchant/v1/payments/`, {
        method: "POST",
        headers: {
          "Accept": "*/*",
          "Content-Type": "application/json",
          "X-Country": "MG",
          "X-Currency": "MGA",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          // Référence alphanumérique exigée par Airtel (visible côté
          // Airtel) : préfixe + début de l'identifiant de transaction.
          reference: `AKORA${airtelTransactionId.slice(0, 12)}`,
          subscriber: { country: "MG", currency: "MGA", msisdn },
          transaction: {
            amount,
            country: "MG",
            currency: "MGA",
            id: airtelTransactionId,
          },
        }),
      });
      const paymentData = await paymentRes.json();
      if (!paymentRes.ok || paymentData?.status?.success !== true) {
        throw new Error(JSON.stringify(paymentData).slice(0, 400));
      }
    } catch (airtelError) {
      console.error("Échec de la demande de paiement Airtel (direct) :", airtelError);
      await supabaseAdmin
        .from("direct_payments")
        .update({ status: "echoue", error_message: String(airtelError).slice(0, 1000) })
        .eq("id", payment.id);
      return json(502, {
        error: "Impossible d'envoyer la demande de paiement Airtel Money. Réessayez.",
      });
    }

    return json(200, { paymentId: payment.id, msisdn });
  } catch (e) {
    console.error(e);
    return json(500, { error: "Erreur inattendue. Réessayez." });
  }
});
