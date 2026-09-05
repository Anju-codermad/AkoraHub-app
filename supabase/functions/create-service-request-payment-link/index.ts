// Edge Function : crée un lien de paiement (Papi ou FiveOne Pay, selon
// `payment_method_settings.provider` — même réglage partagé que les
// commandes produits, voir phase59) pour l'ACOMPTE d'une demande de
// service du site web (`website_service_requests`, aujourd'hui
// uniquement le diagnostic qualité de l'eau).
//
// Contrairement à create-papi-payment-link/create-fiveonepay-payment-link
// (une fonction par fournisseur, car le mode de paiement est déjà choisi
// et stocké sur la commande au moment de l'insert), ici le client choisit
// son mode de paiement Mobile Money au moment de payer l'acompte — cette
// fonction route donc elle-même vers le bon fournisseur, pour éviter de
// dupliquer deux fonctions quasi identiques pour un seul nouveau cas
// d'usage.
//
// Secrets nécessaires (déjà configurés pour les commandes, réutilisés
// tels quels) : PAPI_API_KEY, FIVEONEPAY_SECRET_KEY.
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

const papiProviderMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
  airtel_money: "ARTEL_MONEY",
};
const fiveonepayOperatorMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
  airtel_money: "AIRTEL_MONEY",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
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
    if (!papiProviderMap[paymentMethod as string]) {
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

    const { data: settings } = await supabaseAdmin
      .from("payment_method_settings")
      .select("provider")
      .eq("method_id", paymentMethod)
      .maybeSingle();
    const provider = settings?.provider === "fiveonepay" ? "fiveonepay" : "papi";

    const description = `Acompte diagnostic eau - ${request.name}`;
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
