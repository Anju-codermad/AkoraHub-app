// Edge Function : initie le paiement de l'ACOMPTE d'une demande de
// service du site web (`website_service_requests`, aujourd'hui
// uniquement le diagnostic qualité de l'eau).
//
// Mvola et Orange Money passent par Papi ou FiveOne Pay (selon
// `payment_method_settings.provider` — même réglage partagé que les
// commandes produits, voir phase59) : le client choisit son mode de
// paiement au moment de payer l'acompte, cette fonction route donc
// elle-même vers le bon fournisseur.
//
// Airtel Money passe par l'API Collection Airtel EN DIRECT (push USSD),
// comme pour les commandes produits (voir create-airtel-payment-request)
// — Papi/FiveOne Pay ne sont plus des intermédiaires pour cet opérateur
// (retiré le 10/11, l'intégration directe étant désormais certifiée).
// Voir phase307_patch_airtel_direct_diagnostic_eau.sql pour les colonnes
// ajoutées à website_service_requests à cette occasion.
//
// Secrets nécessaires :
// - PAPI_API_KEY, FIVEONEPAY_SECRET_KEY (déjà configurés pour les
//   commandes, réutilisés tels quels)
// - AIRTEL_CLIENT_ID / AIRTEL_CLIENT_SECRET / AIRTEL_API_BASE_URL (déjà
//   configurés pour create-airtel-payment-request, réutilisés tels quels)
//
// Sécurité : vérifie que l'appelant est bien authentifié ET que la
// demande a été associée à son compte au préalable via
// `claim_water_diagnostic_request` (colonne `claimed_by`, voir
// phase217_patch_water_diagnostic_pricing.sql) — sans ça, n'importe quel
// utilisateur connecté pourrait payer (ou voir le montant de) la demande
// de quelqu'un d'autre.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PAPI_ENDPOINT = "https://app.papi.mg/dashboard/api/payment-links";
const FIVEONEPAY_ENDPOINT = "https://api.fiveonepay.com/v1/payments";
const AIRTEL_BASE_URL = Deno.env.get("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg";

const papiProviderMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
};
const fiveonepayOperatorMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
};

// Appelée directement par le navigateur (services.html) — sans ces
// en-têtes, le navigateur bloque la requête au stade du preflight CORS
// avant même qu'elle n'atteigne cette fonction (aucune invocation
// visible dans les logs Supabase, symptôme qui a permis de trouver ce
// bug : "Impossible de démarrer le paiement" côté client, silencieux
// côté serveur).
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

// Même contrainte que create-airtel-payment-request : l'API Airtel
// exige le MSISDN SANS indicatif pays.
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

    const { requestId, paymentMethod } = await req.json();
    if (!requestId || typeof requestId !== "string") {
      return json(400, { error: "requestId requis" });
    }
    const isAirtel = paymentMethod === "airtel_money";
    if (!isAirtel && !papiProviderMap[paymentMethod as string]) {
      return json(400, { error: "Mode de paiement non pris en charge" });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: request, error: requestError } = await supabaseAdmin
      .from("website_service_requests")
      .select(
        "id, name, phone, service_slug, claimed_by, deposit_amount, payment_status",
      )
      .eq("id", requestId)
      .maybeSingle();

    // Vérifie que la demande appartient bien à l'appelant — sans ça,
    // n'importe quel utilisateur connecté pourrait générer un lien de
    // paiement (et en voir le montant) pour la demande de quelqu'un
    // d'autre.
    if (
      requestError || !request || request.claimed_by !== user.id ||
      request.service_slug !== "diagnostic-eau"
    ) {
      return json(404, { error: "Demande introuvable" });
    }
    if (request.payment_status === "paye") {
      return json(400, { error: "L'acompte de cette demande est déjà réglé." });
    }
    if (!request.deposit_amount) {
      return json(400, {
        error:
          "Le montant de l'acompte n'est pas encore défini pour cette demande (devis en préparation).",
      });
    }

    const description = `Acompte diagnostic eau - ${request.name}`;

    if (isAirtel) {
      const msisdn = normalizeMsisdn(request.phone || "");
      if (!msisdn) {
        return json(400, { error: "Numéro de téléphone Airtel Money invalide" });
      }

      // Sans tirets : Airtel rejette un UUID standard ("ID de transaction
      // est invalide", statut TF) — même contrainte que reference
      // (alphanumérique, voir plus bas).
      const airtelTransactionId = crypto.randomUUID().replace(/-/g, "");
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
          // Airtel exige une référence purement alphanumérique — l'id de
          // la demande (UUID) est nettoyé de ses tirets pour l'envoi,
          // la valeur stockée en base reste inchangée.
          reference: request.id.replace(/[^a-zA-Z0-9]/g, ""),
          subscriber: { country: "MG", currency: "MGA", msisdn },
          transaction: {
            amount: request.deposit_amount,
            country: "MG",
            currency: "MGA",
            id: airtelTransactionId,
          },
        }),
      });

      const paymentData = await paymentRes.json();
      if (!paymentRes.ok || paymentData?.status?.success !== true) {
        console.error(
          "Échec de la demande de paiement Airtel (diagnostic eau) :",
          JSON.stringify(paymentData),
        );
        return json(502, { error: "Impossible d'initier le paiement Airtel Money." });
      }

      // airtel_transaction_id conservé pour retrouver la demande à la
      // réception du callback (voir airtel-payment-notification).
      await supabaseAdmin
        .from("website_service_requests")
        .update({ payment_method: paymentMethod, airtel_transaction_id: airtelTransactionId })
        .eq("id", requestId);

      return json(200, { pending: true, msisdn });
    }

    const { data: settings } = await supabaseAdmin
      .from("payment_method_settings")
      .select("provider")
      .eq("method_id", paymentMethod)
      .maybeSingle();
    const provider = settings?.provider === "fiveonepay" ? "fiveonepay" : "papi";

    let paymentLink: string;

    if (provider === "papi") {
      const papiRes = await fetch(PAPI_ENDPOINT, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Token": Deno.env.get("PAPI_API_KEY")!,
        },
        body: JSON.stringify({
          amount: request.deposit_amount,
          clientName: request.name,
          reference: request.id,
          description,
          notificationUrl:
            `${Deno.env.get("SUPABASE_URL")}/functions/v1/papi-payment-notification`,
          validDuration: 30,
          provider: papiProviderMap[paymentMethod],
          payerPhone: request.phone,
        }),
      });
      const papiData = await papiRes.json();
      if (!papiRes.ok || !papiData?.data?.paymentLink) {
        console.error("Échec création lien Papi :", JSON.stringify(papiData));
        return json(502, { error: "Impossible de créer le lien de paiement." });
      }
      paymentLink = papiData.data.paymentLink;
      await supabaseAdmin
        .from("website_service_requests")
        .update({
          payment_method: paymentMethod,
          papi_notification_token: papiData.data.notificationToken,
          papi_payment_link: paymentLink,
        })
        .eq("id", requestId);
    } else {
      const fiveonepayRes = await fetch(FIVEONEPAY_ENDPOINT, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${Deno.env.get("FIVEONEPAY_SECRET_KEY")!}`,
          // Rejouable sans risque de double paiement après une coupure
          // réseau — un second appel avec la même clé renvoie le
          // paiement déjà créé au lieu d'en créer un nouveau.
          "Idempotency-Key": request.id,
        },
        body: JSON.stringify({
          amount: request.deposit_amount,
          reference: request.id,
          operator: fiveonepayOperatorMap[paymentMethod],
          description,
          payerNumber: request.phone,
          callbackUrl:
            `${Deno.env.get("SUPABASE_URL")}/functions/v1/fiveonepay-payment-notification`,
        }),
      });
      const fiveonepayData = await fiveonepayRes.json();
      if (!fiveonepayRes.ok || !fiveonepayData?.payment_url) {
        console.error(
          "Échec création paiement FiveOne Pay :",
          JSON.stringify(fiveonepayData),
        );
        return json(502, { error: "Impossible de créer le paiement." });
      }
      paymentLink = fiveonepayData.payment_url;
      await supabaseAdmin
        .from("website_service_requests")
        .update({
          payment_method: paymentMethod,
          fiveonepay_reference: fiveonepayData.fiveonepay_reference,
          fiveonepay_payment_url: paymentLink,
        })
        .eq("id", requestId);
    }

    return json(200, { paymentLink });
  } catch (e) {
    console.error(e);
    return json(500, { error: String(e) });
  }
});
