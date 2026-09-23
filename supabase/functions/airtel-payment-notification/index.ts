// Edge Function : reçoit la confirmation de paiement envoyée par Airtel
// Money (callback configuré dans Application settings -> Callback
// Authentication sur le portail développeur) — endpoint public appelé
// directement par les serveurs Airtel, jamais par l'app.
//
// Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - AIRTEL_CALLBACK_PRIVATE_KEY (portail Airtel -> Mes Applications ->
//   Paramètres -> Callback Authentication -> copier la clé privée après
//   l'avoir activée ; distincte de AIRTEL_CLIENT_SECRET)
//
// Vérification d'authenticité (doc Airtel "Callback Encryption") : le
// corps reçoit un champ `hash` = Base64(HmacSHA256(JSON du champ
// `transaction`, clé privée)) — sans ce contrôle, n'importe qui
// connaissant un numéro de commande pourrait forger une fausse
// confirmation de paiement. Même principe que fiveonepay-payment-
// notification, adapté au format Airtel (hash sur `transaction` seul,
// pas sur tout le corps, et sortie en Base64 plutôt qu'en hexadécimal).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function timingSafeEqual(a: string, b: string): boolean {
  const maxLength = Math.max(a.length, b.length);
  let diff = a.length === b.length ? 0 : 1;
  for (let i = 0; i < maxLength; i++) {
    diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  }
  return diff === 0;
}

async function computeTransactionHash(
  transaction: unknown,
  privateKey: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(privateKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(JSON.stringify(transaction)),
  );
  return btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)));
}

Deno.serve(async (req) => {
  try {
    const rawBody = await req.text();
    const payload = JSON.parse(rawBody);
    const transaction = payload.transaction as
      | { id?: string; status_code?: string; airtel_money_id?: string }
      | undefined;
    const receivedHash = payload.hash as string | undefined;

    if (!transaction?.id || !transaction?.status_code || !receivedHash) {
      return new Response("ignored", { status: 200 });
    }

    const privateKey = Deno.env.get("AIRTEL_CALLBACK_PRIVATE_KEY")!;
    const expectedHash = await computeTransactionHash(transaction, privateKey);

    if (!timingSafeEqual(expectedHash, receivedHash)) {
      // Ne répond jamais par une erreur ici : un vrai callback Airtel en
      // échec serait réessayé indéfiniment, et une requête forgée ne
      // mérite qu'un journal, pas un indice sur ce qui a cloché (même
      // principe que papi-payment-notification).
      console.error(
        "Hash de callback Airtel invalide pour la transaction",
        transaction.id,
      );
      return new Response("ignored", { status: 200 });
    }

    // TS = Transaction Success, TF = Transaction Failed (seuls statuts
    // documentés) — tout autre code est un statut intermédiaire éventuel,
    // sans action à prendre avant la confirmation finale.
    if (transaction.status_code !== "TS" && transaction.status_code !== "TF") {
      return new Response("ok", { status: 200 });
    }
    const newStatus = transaction.status_code === "TS" ? "paye" : "echoue";

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: order } = await supabaseAdmin
      .from("orders")
      .select("id, payment_status")
      .eq("airtel_transaction_id", transaction.id)
      .maybeSingle();

    if (!order) {
      console.error(
        "Commande introuvable pour la transaction Airtel",
        transaction.id,
      );
      return new Response("ok", { status: 200 });
    }

    if (order.payment_status !== newStatus) {
      await supabaseAdmin
        .from("orders")
        .update({
          payment_status: newStatus,
          airtel_money_transaction_ref: transaction.airtel_money_id ?? null,
        })
        .eq("id", order.id);
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
