// Edge Function : reçoit chaque SMS de confirmation Mobile Money
// (Mvola/Orange Money/Airtel Money) relayé par un téléphone Android
// dédié (SIM marchande + appli "SMS vers webhook" du Play Store — pas
// de code natif nécessaire côté téléphone) et tente de le rapprocher
// automatiquement d'une commande en attente de paiement (voir
// supabase/phase180_patch_mobile_money_sms_reconciliation.sql).
//
// Pourquoi cette approche plutôt que les API marchandes officielles :
// leurs tarifs sont trop élevés pour le volume actuel d'AkoraHub. Le
// client paie manuellement par USSD comme aujourd'hui (voir
// phase27/28/29) ; ce webhook automatise seulement la CONFIRMATION.
//
// Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - MOBILE_MONEY_GATEWAY_SECRET : chaîne aléatoire, à renseigner aussi
//   dans l'en-tête HTTP personnalisé de l'appli SMS-vers-webhook du
//   téléphone passerelle (en-tête "x-gateway-secret").
//
// ⚠️ Les expressions régulières ci-dessous (montant, numéro expéditeur)
// sont une PREMIÈRE ESTIMATION basée sur les formats habituels des SMS
// Mvola/Orange Money/Airtel Money à Madagascar — elles n'ont PAS encore
// été validées sur de vrais SMS. Dès que possible, envoyer 2-3 exemples
// réels de chaque opérateur pour ajuster précisément ces motifs.
//
// Format de requête attendu (JSON, tolérant sur les noms de champs pour
// s'adapter à l'appli SMS-vers-webhook réellement installée) :
// {
//   "operator": "mvola" | "orange_money" | "airtel_money",  // optionnel,
//                                                            // déduit du
//                                                            // texte sinon
//   "sender": "Mvola",              // ou "from" — nom/numéro expéditeur SMS
//   "text": "Vous avez recu Ar 20 000,00 de 034 12 345 67 ...",
//   "timestamp": "2026-08-25T20:00:00Z"  // optionnel, défaut = maintenant
// }
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Operator = "mvola" | "orange_money" | "airtel_money";

const OPERATOR_KEYWORDS: Record<Operator, RegExp> = {
  mvola: /mvola/i,
  orange_money: /orange\s*money/i,
  airtel_money: /airtel\s*money/i,
};

function detectOperator(
  declared: string | undefined,
  sender: string,
  text: string,
): Operator | null {
  const normalized = (declared || "").toLowerCase().replace(/\s+/g, "_");
  if (normalized === "mvola" || normalized === "orange_money" || normalized === "airtel_money") {
    return normalized;
  }
  const haystack = `${sender} ${text}`;
  for (const [op, re] of Object.entries(OPERATOR_KEYWORDS)) {
    if (re.test(haystack)) return op as Operator;
  }
  return null;
}

// Montant : une suite de chiffres (espaces/points/virgules tolérés comme
// séparateurs de milliers) suivie de "Ar"/"AR"/"MGA". Les centimes
// (",00" ou ".00" final) sont ignorés — les montants AkoraHub sont
// toujours des nombres entiers d'ariary.
function parseAmount(text: string): number | null {
  const match = text.match(/(\d[\d\s.,]{1,12}\d|\d)\s*(?:Ar\b|AR\b|MGA\b)/);
  if (!match) return null;
  let digits = match[1].replace(/[.,](\d{2})$/, "").replace(/[^\d]/g, "");
  if (!digits) return null;
  const amount = Number(digits);
  return Number.isFinite(amount) && amount > 0 ? amount : null;
}

// Numéro malgache : 03 + 8 chiffres (espaces tolérés dans le SMS).
function parsePhone(text: string): string | null {
  const match = text.replace(/[\s.-]/g, "").match(/(03\d{8})/);
  return match ? match[1] : null;
}

const MATCH_WINDOW_HOURS = 6;

Deno.serve(async (req) => {
  try {
    const secret = Deno.env.get("MOBILE_MONEY_GATEWAY_SECRET")!;
    const provided = req.headers.get("x-gateway-secret");
    if (!provided || provided !== secret) {
      console.error("Secret passerelle SMS invalide ou absent.");
      return new Response("ignored", { status: 200 });
    }

    const payload = await req.json().catch(() => null);
    if (!payload) return new Response("ignored", { status: 200 });

    const text: string | undefined = payload.text ?? payload.message ?? payload.body;
    const sender: string = payload.sender ?? payload.from ?? "";
    const timestampRaw: string | undefined = payload.timestamp ?? payload.sentStamp;
    if (!text) return new Response("ignored", { status: 200 });

    const operator = detectOperator(payload.operator, sender, text);
    const parsedAmount = parseAmount(text);
    const parsedSenderPhone = parsePhone(text);
    const smsReceivedAt = timestampRaw && !isNaN(Date.parse(timestampRaw))
      ? new Date(timestampRaw).toISOString()
      : new Date().toISOString();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    if (!operator) {
      // Le téléphone-passerelle relaie TOUS les SMS reçus (déclencheur
      // "Tout numéro", car les opérateurs envoient depuis un nom
      // d'expéditeur, pas un numéro classique) — un SMS personnel, un
      // code OTP ou une pub n'a donc aucun rapport avec un paiement.
      // Ignoré silencieusement, sans même l'enregistrer, pour ne pas
      // polluer l'écran admin de rapprochement.
      return new Response("ok", { status: 200 });
    }

    if (!parsedAmount) {
      // Ici en revanche, l'opérateur EST reconnu (mot-clé Mvola/Orange
      // Money/Airtel Money dans le texte) mais le montant n'a pas pu être
      // extrait — probablement un SMS opérateur qui n'est pas une
      // confirmation de réception (solde, pub...), ou un format qui a
      // changé. On le garde en "unmatched" pour vérification manuelle et
      // pour repérer si l'analyse du texte doit être ajustée.
      await supabaseAdmin.from("mobile_money_sms_events").insert({
        operator,
        raw_text: text,
        parsed_amount: null,
        parsed_sender_phone: parsedSenderPhone,
        sms_received_at: smsReceivedAt,
        match_status: "unmatched",
      });
      return new Response("ok", { status: 200 });
    }

    const windowStart = new Date(
      Date.now() - MATCH_WINDOW_HOURS * 60 * 60 * 1000,
    ).toISOString();

    const { data: candidates } = await supabaseAdmin
      .from("orders")
      .select("id")
      .eq("payment_status", "en_attente")
      .eq("payment_method", operator)
      .eq("total_amount", parsedAmount)
      .gte("created_at", windowStart);

    const { data: inserted, error: insertError } = await supabaseAdmin
      .from("mobile_money_sms_events")
      .insert({
        operator,
        raw_text: text,
        parsed_amount: parsedAmount,
        parsed_sender_phone: parsedSenderPhone,
        sms_received_at: smsReceivedAt,
        matched_order_id: candidates?.length === 1 ? candidates[0].id : null,
        match_status: candidates?.length === 1 ? "auto_matched" : "unmatched",
      })
      .select("id")
      .single();

    if (insertError || !inserted) {
      console.error("Échec insertion mobile_money_sms_events", insertError);
      return new Response("ok", { status: 200 });
    }

    if (candidates?.length === 1) {
      await supabaseAdmin
        .from("orders")
        .update({ payment_status: "paye" })
        .eq("id", candidates[0].id)
        .eq("payment_status", "en_attente");
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
