// Edge Function : reçoit la confirmation de paiement envoyée par Papi.mg
// (notificationUrl, voir create-papi-payment-link) — endpoint public
// appelé directement par les serveurs de Papi, jamais par l'app.
//
// Vérification d'authenticité recommandée par la doc Papi
// (https://docs.papi.mg/fr/docs/quickstart/) : le paymentReference reçu
// doit correspondre à la commande, ET le notificationToken doit
// correspondre à celui reçu lors de la création du lien — sans ce
// contrôle, n'importe qui connaissant un numéro de commande pourrait
// forger une fausse confirmation de paiement.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    if (!order || order.papi_notification_token !== notificationToken) {
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
    if (order.payment_status !== newStatus) {
      await supabaseAdmin
        .from("orders")
        .update({ payment_status: newStatus })
        .eq("id", order.id);
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
