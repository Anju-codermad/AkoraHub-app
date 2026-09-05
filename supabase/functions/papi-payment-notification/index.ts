// Edge Function : reçoit la confirmation de paiement envoyée par Papi.mg
// (notificationUrl, voir create-papi-payment-link) — endpoint public
// appelé directement par les serveurs de Papi, jamais par l'app.
//
// Depuis phase217 (05/09) : une référence peut aussi correspondre à
// l'acompte d'une demande de service du site web
// (`website_service_requests`, voir create-service-request-payment-link)
// plutôt qu'à une commande produit (`orders`) — la référence envoyée à
// Papi est dans les deux cas l'uuid de la ligne elle-même, donc on essaie
// `orders` d'abord (cas le plus fréquent), puis `website_service_requests`
// si aucune commande ne correspond.
//
// Vérification d'authenticité recommandée par la doc Papi
// (https://docs.papi.mg/fr/docs/quickstart/) : le paymentReference reçu
// doit correspondre à la commande, ET le notificationToken doit
// correspondre à celui reçu lors de la création du lien — sans ce
// contrôle, n'importe qui connaissant un numéro de commande pourrait
// forger une fausse confirmation de paiement.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Comparaison en temps constant (25/08, audit de sécurité) — un simple
// `!==` retourne dès le premier caractère différent, ce qui laisse
// théoriquement deviner le token octet par octet via le temps de
// réponse. Même principe que la vérification HMAC de
// fiveonepay-payment-notification, adapté à une comparaison directe de
// chaînes (Papi ne signe pas tout le corps de la requête).
function timingSafeEqual(a: string, b: string): boolean {
  const maxLength = Math.max(a.length, b.length);
  let diff = a.length === b.length ? 0 : 1;
  for (let i = 0; i < maxLength; i++) {
    diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const paymentReference = body.paymentReference as string | undefined;
    const notificationToken = body.notificationToken as string | undefined;
    const paymentStatus = body.paymentStatus as string | undefined;

    if (!paymentReference || !notificationToken || !paymentStatus) {
      return new Response(
        JSON.stringify({ error: "Payload invalide" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: order } = await supabaseAdmin
      .from("orders")
      .select("id, papi_notification_token, payment_status")
      .eq("order_number", paymentReference)
      .maybeSingle();

    if (
      order &&
      order.papi_notification_token &&
      timingSafeEqual(order.papi_notification_token, notificationToken)
    ) {
      if (paymentStatus === "PENDING") return new Response("ok", { status: 200 });
      const newStatus = paymentStatus === "SUCCESS" ? "paye" : "echoue";
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
      .select("id, papi_notification_token, payment_status")
      .eq("id", paymentReference)
      .maybeSingle();

    if (
      !serviceRequest ||
      !serviceRequest.papi_notification_token ||
      !timingSafeEqual(serviceRequest.papi_notification_token, notificationToken)
    ) {
      // Ne répond jamais par une erreur ici : Papi réessaierait
      // indéfiniment un webhook en échec. On journalise seulement côté
      // serveur (Logs de cette fonction) pour investigation manuelle.
      console.error(
        "Notification Papi non authentifiée pour la référence",
        paymentReference,
      );
      return new Response("ignored", { status: 200 });
    }

    if (paymentStatus === "PENDING") {
      return new Response("ok", { status: 200 });
    }

    const newStatus = paymentStatus === "SUCCESS" ? "paye" : "echoue";
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
