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
// "Verify JWT" peut rester activé : le site envoie la clé anon.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AIRTEL_BASE_URL = Deno.env.get("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg";

const MIN_AMOUNT = 100;
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
// et uniquement un numéro Airtel Madagascar (033…) : un push USSD Airtel
// envoyé vers un numéro Orange/Telma ne peut pas aboutir.
function normalizeMsisdn(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  let local = digits;
  if (local.startsWith("261")) local = local.slice(3);
  if (local.startsWith("0")) local = local.slice(1);
  if (!/^33\d{7}$/.test(local)) return null;
  return local;
}

async function getAirtelAccessToken(): Promise<string> {
  const res = await fetch(`${AIRTEL_BASE_URL}/auth/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "*/*" },
    body: JSON.stringify({
      client_id: Deno.env.get("AIRTEL_CLIENT_ID")!,
      client_secret: Deno.env.get("AIRTEL_CLIENT_SECRET")!,
      grant_type: "client_credentials",
    }),
  });
  const data = await res.json();
  if (!res.ok || !data?.access_token) {
    throw new Error("Échec d'authentification Airtel : " + JSON.stringify(data));
  }
  return data.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") return json(405, { error: "Méthode non autorisée" });

  try {
    const body = await req.json().catch(() => ({}));

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
      return json(400, { error: "Numéro Airtel Money invalide : il doit commencer par 033 (ex. 033 12 345 67)." });
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
        .update({ status: "echoue", error_message: String(airtelError).slice(0, 500) })
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
