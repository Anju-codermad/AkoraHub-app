// Edge Function : paiement Airtel Money en ligne depuis la page de paiement
// unique du site (groupe-akora.com/paiement) — commandes, acomptes du
// diagnostic eau et paiements libres (« lien Payer »). Demande du 23/11 :
// une page de paiement indépendante et une table unique des paiements
// (public.payments, voir phase310_patch_paiements_unifies.sql).
//
// Actions (body JSON) :
//   { action: "start", source: "commande", targetId, phone }
//       -> client connecté (en-tête Authorization), propriétaire de la commande ;
//          commande sans compte (phase311) : l'identifiant suffit
//   { action: "start", source: "acompte", targetId, phone }
//       -> identifiant de la demande (UUID) suffisant, comme le lien envoyé
//   { action: "start", source: "lien", payerName, reference?, amount, phone, website? }
//       -> paiement libre, sans compte ; `website` = champ piège anti-robot
//   { action: "check", paymentId }
//       -> statut redemandé à Airtel (Transaction Enquiry) pour un paiement
//          en attente depuis 10 s à 30 min
// Réponse « start » : { paymentId, msisdn, amount, fee } ou { error }.
//
// Le montant n'est jamais pris dans la requête pour une commande ou un
// acompte : il est relu dans la base. La confirmation finale arrive par le
// callback Airtel (airtel-payment-notification), qui met à jour
// payments.status ; un trigger reporte le statut sur la commande/l'acompte.
//
// Secrets : AIRTEL_CLIENT_ID, AIRTEL_CLIENT_SECRET, AIRTEL_API_BASE_URL
// (les mêmes que les autres fonctions Airtel). "Verify JWT" désactivé :
// appelée aussi par des visiteurs sans compte ; contrôles propres ci-dessous.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function cleanEnv(name: string): string {
  return (Deno.env.get(name) ?? "").trim();
}
const AIRTEL_BASE_URL = (cleanEnv("AIRTEL_API_BASE_URL") ||
  "https://openapiuat.airtel.mg").replace(/\/+$/, "");

// Limites confirmées par Airtel (23/11) : 300 Ar à 5 000 000 Ar.
const MIN_AMOUNT = 300;
const MAX_AMOUNT = 5_000_000;
const MAX_PER_NUMBER_15_MIN = 3;
const MAX_TOTAL_PER_HOUR = 60;

// Grille Airtel « Frais d'achat auprès d'un commerçant » (à la charge du
// client, relevée le 23/11) — même grille que site/assets/airtel-fees.js.
const FEES: Array<[number, number]> = [
  [1000, 100], [5000, 150], [10000, 250], [20000, 350], [25000, 400], [30000, 400],
  [40000, 500], [50000, 600], [60000, 600], [80000, 800], [100000, 900],
  [250000, 1500], [500000, 2000], [1000000, 5000], [2000000, 10000],
  [3000000, 12000], [4000000, 16000], [5000000, 20000],
];
function airtelFee(amount: number): number | null {
  if (amount < 100) return null;
  for (const [max, fee] of FEES) if (amount <= max) return fee;
  return null;
}

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

// MSISDN sans indicatif, numéro Airtel Madagascar (033 ou 035) uniquement.
function normalizeMsisdn(raw: string): string | null {
  let local = raw.replace(/\D/g, "");
  if (local.startsWith("261")) local = local.slice(3);
  if (local.startsWith("0")) local = local.slice(1);
  return /^3[35]\d{7}$/.test(local) ? local : null;
}

function isUuid(v: unknown): v is string {
  return typeof v === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
}

async function getAirtelAccessToken(): Promise<string> {
  const res = await fetch(`${AIRTEL_BASE_URL}/auth/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "*/*" },
    body: JSON.stringify({
      client_id: cleanEnv("AIRTEL_CLIENT_ID"),
      client_secret: cleanEnv("AIRTEL_CLIENT_SECRET"),
      grant_type: "client_credentials",
    }),
  });
  const text = await res.text();
  let data: Record<string, unknown> | null = null;
  try { data = JSON.parse(text); } catch (_) { /* réponse non JSON */ }
  if (!res.ok || !data?.access_token) {
    throw new Error(`Authentification Airtel refusée (HTTP ${res.status}) ${text.slice(0, 200)}`);
  }
  return data.access_token as string;
}

function adminClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
}

// ---------- Vérification du statut (Transaction Enquiry) ----------
async function checkPayment(paymentId: string): Promise<Record<string, unknown>> {
  if (!isUuid(paymentId)) return { status: "inconnu" };
  const db = adminClient();
  const { data: payment } = await db
    .from("payments")
    .select("id, status, mode, airtel_transaction_id, created_at")
    .eq("id", paymentId)
    .maybeSingle();
  if (!payment) return { status: "inconnu" };
  if (payment.status !== "en_attente" || payment.mode !== "en_ligne" || !payment.airtel_transaction_id) {
    return { status: payment.status };
  }
  const ageMs = Date.now() - new Date(payment.created_at).getTime();
  if (ageMs < 10_000 || ageMs > 30 * 60_000) return { status: payment.status };

  try {
    const accessToken = await getAirtelAccessToken();
    const res = await fetch(`${AIRTEL_BASE_URL}/standard/v1/payments/${payment.airtel_transaction_id}`, {
      method: "GET",
      headers: { "Accept": "*/*", "X-Country": "MG", "X-Currency": "MGA", "Authorization": `Bearer ${accessToken}` },
    });
    const data = await res.json().catch(() => null);
    console.log("Vérification Airtel :", payment.airtel_transaction_id, "HTTP", res.status, JSON.stringify(data)?.slice(0, 300));
    const tx = data?.data?.transaction;
    const code = String(tx?.status ?? "").toUpperCase();
    let newStatus: string | null = null;
    if (code === "TS") newStatus = "paye";
    if (code === "TF" || code === "TE") newStatus = "echoue";
    if (!newStatus) return { status: "en_attente" };
    await db
      .from("payments")
      .update({
        status: newStatus,
        airtel_money_transaction_ref: tx?.airtel_money_id ?? null,
        ...(newStatus === "echoue" ? { error_message: `Airtel : ${code} ${tx?.message ?? ""}`.trim() } : {}),
      })
      .eq("id", payment.id)
      .eq("status", "en_attente");
    return { status: newStatus };
  } catch (e) {
    console.error("Vérification Airtel impossible :", e);
    return { status: "en_attente" };
  }
}

// ---------- Démarrage d'un paiement ----------
type Target = {
  source: "commande" | "acompte" | "lien";
  orderId?: string;
  serviceRequestId?: string;
  customerId?: string | null;
  reference: string | null;
  payerName: string | null;
  amount: number;
};

async function resolveTarget(req: Request, body: Record<string, unknown>): Promise<Target | Response> {
  const db = adminClient();
  const source = String(body.source ?? "");

  if (source === "commande") {
    if (!isUuid(body.targetId)) return json(400, { error: "Commande introuvable." });
    const { data: order } = await db
      .from("orders")
      .select("id, order_number, customer_id, guest_name, total_amount, payment_status")
      .eq("id", body.targetId)
      .maybeSingle();
    if (!order) return json(404, { error: "Commande introuvable." });
    let payerName: string | null = order.guest_name ?? null;
    // Commande d'un client connecté : réservée à ce client. Commande sans
    // compte (phase311, customer_id vide) : l'identifiant suffit.
    if (order.customer_id) {
      const authHeader = req.headers.get("Authorization") ?? "";
      const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: { user } } = await userClient.auth.getUser();
      if (!user) return json(401, { error: "Connectez-vous pour payer cette commande." });
      if (order.customer_id !== user.id) return json(404, { error: "Commande introuvable." });
      const { data: profile } = await db.from("profiles").select("full_name").eq("id", user.id).maybeSingle();
      payerName = profile?.full_name ?? null;
    }
    if (order.payment_status === "paye") return json(409, { error: "Cette commande est déjà payée." });
    return {
      source: "commande", orderId: order.id, customerId: order.customer_id ?? null, reference: order.order_number,
      payerName, amount: Math.round(Number(order.total_amount)),
    };
  }

  if (source === "acompte") {
    if (!isUuid(body.targetId)) return json(400, { error: "Demande introuvable." });
    const { data: request } = await db
      .from("website_service_requests")
      .select("id, name, proforma_number, deposit_amount, payment_status")
      .eq("id", body.targetId)
      .maybeSingle();
    if (!request) return json(404, { error: "Demande introuvable." });
    if (request.payment_status === "paye") return json(409, { error: "Cet acompte est déjà payé." });
    return {
      source: "acompte", serviceRequestId: request.id, reference: request.proforma_number ?? "Acompte diagnostic eau",
      payerName: request.name ?? null, amount: Math.round(Number(request.deposit_amount)),
    };
  }

  if (source === "lien") {
    const payerName = String(body.payerName ?? "").trim().slice(0, 120);
    if (!payerName) return json(400, { error: "Indiquez votre nom." });
    return {
      source: "lien", reference: String(body.reference ?? "").trim().slice(0, 60) || null,
      payerName, amount: Math.round(Number(body.amount)),
    };
  }

  return json(400, { error: "Origine du paiement invalide." });
}

async function startPayment(req: Request, body: Record<string, unknown>): Promise<Response> {
  // Robot (champ piège rempli) : réponse neutre, rien n'est déclenché.
  if (typeof body.website === "string" && body.website.trim() !== "") {
    return json(200, { paymentId: crypto.randomUUID(), msisdn: "" });
  }
  const msisdn = normalizeMsisdn(String(body.phone ?? ""));
  if (!msisdn) {
    return json(400, { error: "Numéro Airtel Money invalide : il doit commencer par 033 ou 035 (ex. 033 12 345 67)." });
  }

  const target = await resolveTarget(req, body);
  if (target instanceof Response) return target;
  if (!Number.isFinite(target.amount) || target.amount < MIN_AMOUNT || target.amount > MAX_AMOUNT) {
    return json(400, {
      error: `Montant invalide pour Airtel Money (entre ${MIN_AMOUNT} et ${MAX_AMOUNT.toLocaleString("fr-FR")} Ar).`,
    });
  }

  const db = adminClient();
  const { data: setting } = await db
    .from("payment_method_settings")
    .select("enabled")
    .eq("method_id", "airtel_money")
    .maybeSingle();
  if (setting && setting.enabled === false) {
    return json(403, { error: "Le paiement Airtel Money est momentanément indisponible." });
  }

  const since15 = new Date(Date.now() - 15 * 60 * 1000).toISOString();
  const since60 = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const [{ count: recentForNumber }, { count: recentTotal }] = await Promise.all([
    db.from("payments").select("id", { count: "exact", head: true })
      .eq("mode", "en_ligne").eq("payer_phone", msisdn).gte("created_at", since15),
    db.from("payments").select("id", { count: "exact", head: true })
      .eq("mode", "en_ligne").gte("created_at", since60),
  ]);
  if ((recentForNumber ?? 0) >= MAX_PER_NUMBER_15_MIN) {
    return json(429, { error: "Trop de demandes pour ce numéro. Réessayez dans quelques minutes." });
  }
  if ((recentTotal ?? 0) >= MAX_TOTAL_PER_HOUR) {
    return json(429, { error: "Service très sollicité. Réessayez un peu plus tard." });
  }

  // Identifiant de transaction Airtel : alphanumérique (UUID sans tirets).
  const airtelTransactionId = crypto.randomUUID().replace(/-/g, "");
  const fee = airtelFee(target.amount);
  const { data: payment, error: insertError } = await db
    .from("payments")
    .insert({
      source: target.source,
      order_id: target.orderId ?? null,
      service_request_id: target.serviceRequestId ?? null,
      customer_id: target.customerId ?? null,
      reference: target.reference,
      payer_name: target.payerName,
      payer_phone: msisdn,
      method: "airtel_money",
      mode: "en_ligne",
      amount: target.amount,
      fee,
      airtel_transaction_id: airtelTransactionId,
    })
    .select("id")
    .single();
  if (insertError || !payment) {
    throw new Error("Enregistrement du paiement impossible : " + insertError?.message);
  }

  try {
    const accessToken = await getAirtelAccessToken();
    const airtelReference = (target.reference ?? "").replace(/[^a-zA-Z0-9]/g, "").slice(0, 20) ||
      `AKORA${airtelTransactionId.slice(0, 12)}`;
    const res = await fetch(`${AIRTEL_BASE_URL}/merchant/v1/payments/`, {
      method: "POST",
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "X-Country": "MG",
        "X-Currency": "MGA",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        reference: airtelReference,
        subscriber: { country: "MG", currency: "MGA", msisdn },
        transaction: { amount: target.amount, country: "MG", currency: "MGA", id: airtelTransactionId },
      }),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok || data?.status?.success !== true) {
      throw new Error(JSON.stringify(data).slice(0, 400));
    }
  } catch (airtelError) {
    console.error("Échec de la demande de paiement Airtel :", airtelError);
    await db
      .from("payments")
      .update({ status: "echoue", error_message: String(airtelError).slice(0, 1000) })
      .eq("id", payment.id);
    return json(502, { error: "Impossible d'envoyer la demande de paiement Airtel Money. Réessayez." });
  }

  return json(200, { paymentId: payment.id, msisdn, amount: target.amount, fee });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS_HEADERS });
  if (req.method !== "POST") return json(405, { error: "Méthode non autorisée" });
  try {
    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    if (body.action === "check") return json(200, await checkPayment(String(body.paymentId ?? "")));
    if (body.action === "start") return await startPayment(req, body);
    return json(400, { error: "Action inconnue." });
  } catch (e) {
    console.error(e);
    return json(500, { error: "Erreur inattendue. Réessayez." });
  }
});
