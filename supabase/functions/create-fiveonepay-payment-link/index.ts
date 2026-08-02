// Edge Function : crée un paiement FiveOne Pay pour une commande
// existante — second fournisseur Mobile Money, en plus de Papi (voir
// create-papi-payment-link). La clé API FiveOne Pay ne doit jamais être
// présente côté client — cette fonction est le seul endroit qui la lit.
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - FIVEONEPAY_SECRET_KEY (Sandbox sk_test_... ou Production sk_live_...,
//   voir tableau de bord FiveOne Pay -> Clés API)
// (SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY sont
// fournis automatiquement.)
//
// Doc FiveOne Pay : POST /v1/payments — un seul endpoint pour les 3
// opérateurs (operator: MVOLA/ORANGE_MONEY/AIRTEL_MONEY), contrairement
// à Papi qui distingue Airtel Money par un typo ("ARTEL_MONEY") côté
// Papi seulement — ne pas confondre les deux mappings.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIVEONEPAY_ENDPOINT = "https://api.fiveonepay.com/v1/payments";

const operatorMap: Record<string, string> = {
  mvola: "MVOLA",
  orange_money: "ORANGE_MONEY",
  airtel_money: "AIRTEL_MONEY",
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
    // n'importe quel utilisateur connecté pourrait générer un paiement
    // pour la commande de quelqu'un d'autre.
    if (orderError || !order || order.customer_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Commande introuvable" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }

    const operator = operatorMap[order.payment_method as string];
    if (!operator) {
      return new Response(
        JSON.stringify({
          error: "Ce mode de paiement n'est pas pris en charge par FiveOne Pay",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Double vérification côté serveur : n'appelle FiveOne Pay que si
    // c'est bien lui qui est configuré pour cet opérateur (voir
    // supabase/phase59_patch_fiveonepay_payment.sql) — évite un appel
    // API erroné si le réglage Admin a changé entre le chargement de
    // l'écran client et la validation du paiement.
    const { data: settings } = await supabaseAdmin
      .from("payment_method_settings")
      .select("provider")
      .eq("method_id", order.payment_method)
      .maybeSingle();
    if (settings?.provider !== "fiveonepay") {
      return new Response(
        JSON.stringify({
          error: "Ce mode de paiement n'est pas configuré pour FiveOne Pay",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("phone")
      .eq("id", user.id)
      .maybeSingle();

    const fiveonepayRes = await fetch(FIVEONEPAY_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${Deno.env.get("FIVEONEPAY_SECRET_KEY")!}`,
        // Rejouable sans risque de double paiement après une coupure
        // réseau — un second appel avec la même clé renvoie le paiement
        // déjà créé au lieu d'en créer un nouveau.
        "Idempotency-Key": order.order_number,
      },
      body: JSON.stringify({
        amount: order.total_amount,
        reference: order.order_number,
        operator,
        description: `Commande ${order.order_number} - AkoraHub`,
        payerNumber: profile?.phone || undefined,
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
      return new Response(
        JSON.stringify({ error: "Impossible de créer le paiement." }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    await supabaseAdmin
      .from("orders")
      .update({
        fiveonepay_reference: fiveonepayData.fiveonepay_reference,
        fiveonepay_payment_url: fiveonepayData.payment_url,
      })
      .eq("id", orderId);

    return new Response(
      JSON.stringify({ paymentLink: fiveonepayData.payment_url }),
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
