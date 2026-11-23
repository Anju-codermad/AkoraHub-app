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


// Texte EXACT de l'objet "transaction" tel qu'envoyé par Airtel (espaces et
// ordre compris) : Airtel signe ce texte-là, pas notre JSON.stringify()
// reformaté. Repère `"transaction"` puis l'accolade fermante correspondante.
function rawTransactionText(rawBody: string): string | null {
  const keyIndex = rawBody.search(/"transaction"\s*:/);
  if (keyIndex === -1) return null;
  const start = rawBody.indexOf("{", keyIndex);
  if (start === -1) return null;
  let depth = 0;
  let inString = false;
  for (let i = start; i < rawBody.length; i++) {
    const c = rawBody[i];
    if (inString) {
      if (c === "\\") i++;
      else if (c === '"') inString = false;
      continue;
    }
    if (c === '"') inString = true;
    else if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return rawBody.slice(start, i + 1);
    }
  }
  return null;
}

async function hmacBase64(message: string, privateKey: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(privateKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
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

    // Trace de chaque callback reçu (diagnostic : sans elle, impossible de
    // savoir si Airtel a appelé ou non).
    console.log("Callback Airtel reçu :", transaction.id, transaction.status_code);

    // Clé nettoyée : un espace / retour à la ligne collé par erreur dans le
    // Dashboard rendrait tous les hash invalides (voir 23/11).
    const privateKey = (Deno.env.get("AIRTEL_CALLBACK_PRIVATE_KEY") ?? "").trim();
    // Signature vérifiée sur plusieurs écritures du même objet : notre
    // JSON reformaté, le texte exact reçu, et ce texte sans espaces.
    const rawTx = rawTransactionText(rawBody);
    const candidates = [JSON.stringify(transaction)];
    if (rawTx) candidates.push(rawTx, rawTx.replace(/\s+(?=(?:[^"]*"[^"]*")*[^"]*$)/g, ""));
    let hashOk = false;
    for (const message of candidates) {
      if (timingSafeEqual(await hmacBase64(message, privateKey), receivedHash)) {
        hashOk = true;
        break;
      }
    }

    if (!hashOk) {
      console.error("Corps du callback refusé :", rawBody.slice(0, 600), "| hash reçu :", receivedHash.slice(0, 12) + "…");
      // Ne répond jamais par une erreur ici : un vrai callback Airtel en
      // échec serait réessayé indéfiniment, et une requête forgée ne
      // mérite qu'un journal, pas un indice sur ce qui a cloché (même
      // principe que papi-payment-notification).
      console.error(
        "Hash de callback Airtel invalide pour la transaction",
        transaction.id,
        `(clé AIRTEL_CALLBACK_PRIVATE_KEY : ${privateKey.length} car., ` +
          `commence par « ${privateKey.slice(0, 2)}… »)`,
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

    if (order) {
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
    }

    // Pas une commande produit : essaie l'acompte diagnostic-eau (même
    // transaction.id, table différente — voir create-service-request-
    // payment-link et phase307_patch_airtel_direct_diagnostic_eau.sql).
    const { data: serviceRequest } = await supabaseAdmin
      .from("website_service_requests")
      .select("id, payment_status")
      .eq("airtel_transaction_id", transaction.id)
      .maybeSingle();

    if (!serviceRequest) {
      // Ni commande ni acompte : paiement direct depuis la page publique
      // « Payer Akora Fanadiovana » (create-airtel-direct-payment, voir
      // phase309_patch_airtel_wallet_marchand.sql — colonne `status`).
      const { data: directPayment } = await supabaseAdmin
        .from("direct_payments")
        .select("id, status")
        .eq("airtel_transaction_id", transaction.id)
        .maybeSingle();

      if (!directPayment) {
        console.error(
          "Commande/demande/paiement direct introuvable pour la transaction Airtel",
          transaction.id,
        );
        return new Response("ok", { status: 200 });
      }

      if (directPayment.status !== newStatus) {
        await supabaseAdmin
          .from("direct_payments")
          .update({
            status: newStatus,
            airtel_money_transaction_ref: transaction.airtel_money_id ?? null,
          })
          .eq("id", directPayment.id);
      }
      return new Response("ok", { status: 200 });
    }

    if (serviceRequest.payment_status !== newStatus) {
      await supabaseAdmin
        .from("website_service_requests")
        .update({
          payment_status: newStatus,
          airtel_money_transaction_ref: transaction.airtel_money_id ?? null,
        })
        .eq("id", serviceRequest.id);
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
