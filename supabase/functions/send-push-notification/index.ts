// Edge Function : envoie une vraie notification push (Firebase Cloud
// Messaging) quand un nouveau message ou une réponse de devis arrive.
// Déclenchée par un trigger Postgres (pg_net) sur les tables `messages`
// et `quote_messages` — voir supabase/phase17_schema.sql.
//
// Secrets nécessaires (à définir dans Supabase Dashboard -> Edge
// Functions -> Manage secrets) :
// - FIREBASE_SERVICE_ACCOUNT : contenu complet du fichier JSON du compte
//   de service Firebase (Paramètres du projet -> Comptes de service ->
//   Générer une nouvelle clé privée).
// - WEBHOOK_SECRET : chaîne aléatoire partagée avec le trigger SQL, pour
//   vérifier que l'appel vient bien de notre base et pas de n'importe qui
//   sur Internet (l'URL d'une Edge Function est publique par défaut).
//
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement
// par Supabase à toute Edge Function — pas besoin de les définir.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface WebhookPayload {
  table: string;
  record: Record<string, unknown>;
}

function base64url(input: ArrayBuffer | string): string {
  const bytes =
    typeof input === "string"
      ? new TextEncoder().encode(input)
      : new Uint8Array(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

/// Échange la clé privée du compte de service contre un token d'accès
/// OAuth valide 1h, en signant un JWT nous-mêmes (RS256) avec l'API Web
/// Crypto native de Deno — aucune librairie externe nécessaire pour ça.
async function getFirebaseAccessToken(
  serviceAccount: {
    client_email: string;
    private_key: string;
  },
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${
    base64url(JSON.stringify(claim))
  }`;

  const pem = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error("Échec d'obtention du token Firebase : " + JSON.stringify(data));
  }
  return data.access_token;
}

async function sendPush(
  serviceAccount: { project_id: string; client_email: string; private_key: string },
  fcmToken: string,
  title: string,
  body: string,
) {
  const accessToken = await getFirebaseAccessToken(serviceAccount);
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: { token: fcmToken, notification: { title, body } },
      }),
    },
  );
  if (!res.ok) {
    console.error("Échec envoi FCM :", await res.text());
  }
}

Deno.serve(async (req) => {
  // Vérifie que l'appel vient bien de notre trigger SQL, pas d'un tiers
  // qui aurait deviné l'URL publique de la fonction.
  const secretHeader = req.headers.get("x-webhook-secret");
  if (secretHeader !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const payload: WebhookPayload = await req.json();
    const record = payload.record;

    const serviceAccount = JSON.parse(
      Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
    );

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let recipientIds: string[] = [];
    let title = "AkoraHub";
    let body = "Vous avez une nouvelle notification";

    if (payload.table === "messages") {
      const { data: conv } = await supabase
        .from("conversations")
        .select("customer_id")
        .eq("id", record.conversation_id)
        .maybeSingle();

      if (record.sender_role === "client") {
        // Le client a écrit -> notifie toute l'équipe (Admin/Commercial).
        const { data: staff } = await supabase
          .from("profiles")
          .select("fcm_token")
          .in("role", ["admin", "commercial"])
          .not("fcm_token", "is", null);
        title = "Nouveau message client";
        body = String(record.content ?? "").slice(0, 100) ||
          "Nouveau message reçu";
        for (const s of staff ?? []) {
          if (s.fcm_token) await sendPush(serviceAccount, s.fcm_token, title, body);
        }
        return new Response("ok");
      } else if (conv?.customer_id) {
        recipientIds = [conv.customer_id as string];
        title = "Nouveau message";
        body = String(record.content ?? "").slice(0, 100) ||
          "Vous avez reçu une réponse";
      }
    } else if (payload.table === "quote_messages") {
      const { data: quote } = await supabase
        .from("quotes")
        .select("customer_id")
        .eq("id", record.quote_id)
        .maybeSingle();

      if (record.sender_role === "staff" && quote?.customer_id) {
        recipientIds = [quote.customer_id as string];
        title = "Réponse à votre devis";
        body = record.proposed_amount
          ? `Nouvelle proposition : ${record.proposed_amount} Ar`
          : String(record.content ?? "").slice(0, 100) ||
            "Votre devis a été mis à jour";
      }
    } else if (payload.table === "orders") {
      // Changement de statut d'une commande (expédiée/livrée) -> notifie
      // le client concerné. Le trigger SQL ne se déclenche déjà que sur
      // ces deux statuts précis (voir supabase/phase18_schema.sql), donc
      // pas besoin de revérifier ici.
      const statusLabels: Record<string, string> = {
        expediee: "Votre commande a été expédiée",
        livree: "Votre commande a été livrée",
      };
      const orderNumber = record.order_number ? ` (${record.order_number})` : "";
      title = "Suivi de commande";
      body =
        (statusLabels[record.status as string] ??
          "Le statut de votre commande a changé") + orderNumber;
      const customerId = record.customer_id as string | undefined;
      if (customerId) recipientIds = [customerId];
    } else if (payload.table === "quotes") {
      // Le client vient d'accepter/refuser un devis -> notifie toute
      // l'équipe (Admin/Commercial), pas juste le staff qui avait répondu.
      const { data: staff } = await supabase
        .from("profiles")
        .select("fcm_token")
        .in("role", ["admin", "commercial"])
        .not("fcm_token", "is", null);
      const accepted = record.status === "accepte";
      title = accepted ? "Devis accepté" : "Devis refusé";
      body = `Le devis ${record.quote_number ?? ""} a été ${
        accepted ? "accepté" : "refusé"
      } par le client.`;
      for (const s of staff ?? []) {
        if (s.fcm_token) await sendPush(serviceAccount, s.fcm_token, title, body);
      }
      return new Response("ok");
    }

    for (const id of recipientIds) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("fcm_token")
        .eq("id", id)
        .maybeSingle();
      if (profile?.fcm_token) {
        await sendPush(serviceAccount, profile.fcm_token, title, body);
      }
    }

    return new Response("ok");
  } catch (e) {
    console.error(e);
    return new Response("error: " + (e as Error).message, { status: 500 });
  }
});
