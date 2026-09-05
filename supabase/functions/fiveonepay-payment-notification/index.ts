// Edge Function : reçoit la confirmation de paiement envoyée par
// FiveOne Pay (callbackUrl, voir create-fiveonepay-payment-link) —
// endpoint public appelé directement par les serveurs de FiveOne Pay,
// jamais par l'app.
//
// Depuis phase217 (05/09) : une référence peut aussi correspondre à
// l'acompte d'une demande de service du site web
// (`website_service_requests`, voir create-service-request-payment-link)
// plutôt qu'à une commande produit (`orders`) — on essaie `orders`
// d'abord (cas le plus fréquent), puis `website_service_requests` si
// aucune commande ne correspond.
//
// Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - FIVEONEPAY_WEBHOOK_SECRET (whsec_..., voir tableau de bord FiveOne
//   Pay -> Webhooks)
//
// Contrairement à Papi (papi-payment-notification, qui vérifie un
// token stocké par commande faute de signature disponible), FiveOne Pay
// signe TOUT le corps de la requête en HMAC-SHA256
// (en-tête X-FiveOne-Signature) — l'authenticité du webhook ne dépend
// donc que du secret, pas d'une valeur à retrouver par commande.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

async function isValidSignature(
  rawBody: string,
  signatureHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(rawBody),
  );
  const expectedHex = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Comparaison en temps constant — évite de laisser deviner la
  // signature attendue octet par octet via le temps de réponse.
  if (expectedHex.length !== signatureHeader.length) return false;
  let diff = 0;
  for (let i = 0; i < expectedHex.length; i++) {
    diff |= expectedHex.charCodeAt(i) ^ signatureHeader.charCodeAt(i);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  try {
    // Corps BRUT requis pour la vérification HMAC — un objet déjà
    // parsé/re-sérialisé ne redonnerait pas exactement les mêmes octets
    // que ceux signés par FiveOne Pay.
    const rawBody = await req.text();
    const signatureHeader = req.headers.get("x-fiveone-signature");
    const secret = Deno.env.get("FIVEONEPAY_WEBHOOK_SECRET")!;

    const valid = await isValidSignature(rawBody, signatureHeader, secret);
    if (!valid) {
      // Ne répond jamais par une erreur ici : un vrai webhook FiveOne
      // Pay en échec serait réessayé indéfiniment (backoff), et une
      // requête forgée ne mérite qu'un journal, pas un indice sur ce
      // qui a cloché (voir papi-payment-notification, même principe).
      console.error("Signature FiveOne Pay invalide ou absente.");
      return new Response("ignored", { status: 200 });
    }

    const payload = JSON.parse(rawBody);
    const eventId = payload.id as string | undefined;
    const eventType = payload.event as string | undefined;
    const data = payload.data as Record<string, unknown> | undefined;

    if (!eventId || !eventType || !data) {
      return new Response("ignored", { status: 200 });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Déduplication — FiveOne Pay garantit un retry jusqu'à un 2xx, un
    // même événement peut donc arriver plusieurs fois. L'insertion
    // échoue silencieusement (conflit sur event_id) si déjà traité ;
    // dans ce cas count est 0 et on s'arrête là, sans retraiter.
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from("fiveonepay_webhook_events")
      .insert({ event_id: eventId })
      .select("event_id");
    if (insertError || !inserted || inserted.length === 0) {
      return new Response("ok", { status: 200 });
    }

    if (eventType !== "payment.success" && eventType !== "payment.expired") {
      // payout.*/invoice.*/subscription.* : pas utilisés par AkoraHub
      // aujourd'hui (pas de liens de paiement ni d'abonnements créés
      // depuis l'app) — accusé de réception sans traitement.
      return new Response("ok", { status: 200 });
    }

    const reference = data.reference as string | undefined;
    if (!reference) {
      return new Response("ok", { status: 200 });
    }

    // Un paiement EXPIRED peut repasser à SUCCESS si l'argent arrive
    // après le délai (confirmation Mobile Money tardive) — traiter
    // toujours payment.success comme faisant foi, y compris après un
    // payment.expired déjà reçu pour la même commande/demande.
    const newStatus = eventType === "payment.success" ? "paye" : "echoue";

    const { data: order } = await supabaseAdmin
      .from("orders")
      .select("id, payment_status")
      .eq("order_number", reference)
      .maybeSingle();
    if (order) {
      if (order.payment_status !== newStatus) {
        await supabaseAdmin
          .from("orders")
          .update({ payment_status: newStatus })
          .eq("id", order.id);
      }
      return new Response("ok", { status: 200 });
    }

    const { data: serviceRequest } = await supabaseAdmin
      .from("website_service_requests")
      .select("id, payment_status")
      .eq("id", reference)
      .maybeSingle();
    if (!serviceRequest) {
      console.error("Commande/demande introuvable pour la référence", reference);
      return new Response("ok", { status: 200 });
    }
    if (serviceRequest.payment_status !== newStatus) {
      await supabaseAdmin
        .from("website_service_requests")
        .update({ payment_status: newStatus })
        .eq("id", serviceRequest.id);
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
