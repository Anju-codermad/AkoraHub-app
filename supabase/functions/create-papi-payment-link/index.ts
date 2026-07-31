// Edge Function : crée un lien de paiement Papi.mg pour une commande
// existante. La clé API Papi ne doit jamais être présente côté client —
// cette fonction est le seul endroit qui la lit.
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - PAPI_API_KEY (voir tableau de bord Papi -> Applications -> onglet
//   Développeur)
// (SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY sont
// fournis automatiquement.)
//
// Doc Papi : https://docs.papi.mg/fr/docs/quickstart/ — un seul
// endpoint pour sandbox ET production, différencié uniquement par la clé
// API utilisée (celle d'une application configurée en Sandbox ou en
// Production côté tableau de bord Papi).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PAPI_ENDPOINT = "https://app.papi.mg/dashboard/api/payment-links";

const providerMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
  airtel_money: "ARTEL_MONEY",
};

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Non authentifié" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await supabaseUser.auth
      .getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Session invalide" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const { orderId } = await req.json();
    if (!orderId || typeof orderId !== "string") {
      return new Response(
        JSON.stringify({ error: "orderId requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
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

    // Vérifie que la commande appartient bien à l'appelant — sans ça,
    // n'importe quel utilisateur connecté pourrait générer un lien de
    // paiement pour la commande de quelqu'un d'autre.
    if (orderError || !order || order.customer_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Commande introuvable" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }

    const provider = providerMap[order.payment_method as string];
    if (!provider) {
      return new Response(
        JSON.stringify({
          error: "Ce mode de paiement n'est pas pris en charge par Papi",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("full_name, company_name, phone")
      .eq("id", user.id)
      .maybeSingle();
    const clientName = profile?.company_name || profile?.full_name ||
      "Client AkoraHub";

    const papiRes = await fetch(PAPI_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Token": Deno.env.get("PAPI_API_KEY")!,
      },
      body: JSON.stringify({
        amount: order.total_amount,
        clientName,
        reference: order.order_number,
        description: `Commande ${order.order_number} - AkoraHub`,
        // Reçoit la confirmation finale du paiement (voir
        // supabase/functions/papi-payment-notification).
        notificationUrl:
          `${Deno.env.get("SUPABASE_URL")}/functions/v1/papi-payment-notification`,
        validDuration: 30,
        provider,
        payerPhone: profile?.phone || undefined,
      }),
    });

    const papiData = await papiRes.json();
    if (!papiRes.ok || !papiData?.data?.paymentLink) {
      console.error("Échec création lien Papi :", JSON.stringify(papiData));
      return new Response(
        JSON.stringify({ error: "Impossible de créer le lien de paiement." }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    // notificationToken conservé pour vérifier l'authenticité du webhook
    // à la réception (voir papi-payment-notification) — sans ça,
    // n'importe qui connaissant le numéro de commande pourrait forger une
    // fausse confirmation de paiement.
    await supabaseAdmin
      .from("orders")
      .update({
        papi_notification_token: papiData.data.notificationToken,
        papi_payment_link: papiData.data.paymentLink,
      })
      .eq("id", orderId);

    return new Response(
      JSON.stringify({ paymentLink: papiData.data.paymentLink }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error(e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
