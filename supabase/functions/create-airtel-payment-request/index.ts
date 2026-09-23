// Edge Function : initie un paiement Airtel Money direct (push USSD) pour
// une commande existante — le client reçoit une notification sur son
// téléphone pour approuver le paiement ; la confirmation finale arrive de
// façon asynchrone via airtel-payment-notification (callback Airtel), pas
// dans la réponse de cette fonction.
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - AIRTEL_CLIENT_ID / AIRTEL_CLIENT_SECRET (developers.airtel.mg ->
//   Mes Applications -> Gestion des clés)
// - AIRTEL_API_BASE_URL (optionnel) : "https://openapiuat.airtel.mg" par
//   défaut (sandbox) — remplacer par "https://openapi.airtel.mg" pour
//   passer en production, une fois l'application Airtel approuvée.
// (SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY sont
// fournis automatiquement.)
//
// Doc Airtel : developers.airtel.mg -> Documentation -> Collection-APIs
// -> "Payments - USSD Push".
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AIRTEL_BASE_URL = Deno.env.get("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg";

// Appelée directement par le navigateur (panier.html) — même raison que
// create-papi-payment-link : sans ces en-têtes, le préflight CORS bloque
// la requête avant qu'elle n'atteigne cette fonction.
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

// L'API Airtel exige le MSISDN SANS indicatif pays (ex: "340874696", pas
// "+261340874696" ni "0340874696") — voir note "Do not send country code
// in msisdn" de la doc Payments - USSD Push.
function normalizeMsisdn(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  let local = digits;
  if (local.startsWith("261")) local = local.slice(3);
  if (local.startsWith("0")) local = local.slice(1);
  if (!/^3[2-9]\d{7}$/.test(local)) return null;
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
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json(401, { error: "Non authentifié" });

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await supabaseUser.auth
      .getUser();
    if (userError || !user) return json(401, { error: "Session invalide" });

    const { orderId, phone } = await req.json();
    if (!orderId || typeof orderId !== "string") {
      return json(400, { error: "orderId requis" });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: order, error: orderError } = await supabaseAdmin
      .from("orders")
      .select("id, order_number, customer_id, total_amount, payment_method")
      .eq("id", orderId)
      .maybeSingle();

    // Même contrôle que create-papi-payment-link : sans ça, n'importe
    // quel utilisateur connecté pourrait déclencher un paiement pour la
    // commande de quelqu'un d'autre.
    if (orderError || !order || order.customer_id !== user.id) {
      return json(404, { error: "Commande introuvable" });
    }

    if (order.payment_method !== "airtel_money") {
      return json(400, {
        error: "Cette commande n'est pas réglée par Airtel Money",
      });
    }

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("phone")
      .eq("id", user.id)
      .maybeSingle();

    const msisdn = normalizeMsisdn(
      (typeof phone === "string" && phone) || profile?.phone || "",
    );
    if (!msisdn) {
      return json(400, { error: "Numéro de téléphone Airtel Money invalide" });
    }

    const airtelTransactionId = crypto.randomUUID();
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
        reference: order.order_number,
        subscriber: { country: "MG", currency: "MGA", msisdn },
        transaction: {
          amount: order.total_amount,
          country: "MG",
          currency: "MGA",
          id: airtelTransactionId,
        },
      }),
    });

    const paymentData = await paymentRes.json();
    if (!paymentRes.ok || paymentData?.status?.success !== true) {
      console.error(
        "Échec de la demande de paiement Airtel :",
        JSON.stringify(paymentData),
      );
      return json(502, { error: "Impossible d'initier le paiement Airtel Money." });
    }

    // airtel_transaction_id conservé pour retrouver la commande à la
    // réception du callback (voir airtel-payment-notification) — sans
    // ça, impossible de savoir quelle commande une notification concerne.
    await supabaseAdmin
      .from("orders")
      .update({ airtel_transaction_id: airtelTransactionId })
      .eq("id", orderId);

    return json(200, { pending: true, msisdn });
  } catch (e) {
    console.error(e);
    return json(500, { error: String(e) });
  }
});
