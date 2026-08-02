// Edge Function : envoie une notification push manuelle à une liste de
// clients choisie par le staff (CRM Lot 4 — segmentation & marketing,
// ex : relancer tous les clients "inactifs"). Contrairement à
// send-push-notification (déclenchée par des triggers SQL via
// x-webhook-secret), celle-ci est appelée directement par l'app admin
// et vérifie donc le JWT + le rôle staff de l'appelant.
//
// Les briques Firebase (échange de token OAuth, envoi FCM) sont
// dupliquées depuis send-push-notification — ce projet n'a pas de
// dossier `_shared` entre Edge Functions, voir le même choix pour
// create-fiveonepay-payment-link/create-papi-payment-link.
//
// Secrets nécessaires (déjà définis pour send-push-notification) :
// - FIREBASE_SERVICE_ACCOUNT
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY fournis
// automatiquement.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_RECIPIENTS = 500;

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function getFirebaseAccessToken(
  serviceAccount: { client_email: string; private_key: string },
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
    throw new Error(
      "Échec d'obtention du token Firebase : " + JSON.stringify(data),
    );
  }
  return data.access_token;
}

async function sendPush(
  serviceAccount: {
    project_id: string;
    client_email: string;
    private_key: string;
  },
  fcmToken: string,
  title: string,
  body: string,
  soundId: string,
) {
  const accessToken = await getFirebaseAccessToken(serviceAccount);
  await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          android: {
            notification: {
              channel_id: `akorahub_produit_${soundId}`,
              sound: soundId,
            },
          },
        },
      }),
    },
  );
}

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

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: callerProfile } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();
    if (
      !callerProfile ||
      !["admin", "commercial"].includes(callerProfile.role as string)
    ) {
      return new Response(
        JSON.stringify({ error: "Réservé au staff" }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

    const { customerIds, title, body } = await req.json();
    if (
      !Array.isArray(customerIds) || customerIds.length === 0 ||
      typeof title !== "string" || !title.trim() ||
      typeof body !== "string" || !body.trim()
    ) {
      return new Response(
        JSON.stringify({ error: "customerIds, title et body requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    const ids = customerIds.slice(0, MAX_RECIPIENTS);

    const serviceAccount = JSON.parse(
      Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
    );

    const { data: recipients } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token, notification_sound_produit")
      .in("id", ids)
      .not("fcm_token", "is", null);

    let sent = 0;
    for (const r of recipients ?? []) {
      await sendPush(
        serviceAccount,
        r.fcm_token as string,
        title,
        body,
        (r.notification_sound_produit as string | null) ??
          "notif_bulle_eau",
      );
      sent++;
    }

    return new Response(
      JSON.stringify({ sent, targeted: ids.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
