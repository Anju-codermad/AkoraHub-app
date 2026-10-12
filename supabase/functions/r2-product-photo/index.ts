// Edge Function : upload des photos produit vers Cloudflare R2 au lieu de
// Supabase Storage — demande explicite de la propriétaire (12/10), pour
// réduire le "Cached Egress" (quota gratuit Supabase dépassé à 213% :
// https://supabase.com/dashboard/org/.../usage). R2 n'a AUCUN frais de
// sortie/egress, contrairement à Supabase Storage — déjà utilisé pour
// l'APK (voir .github/workflows/build-apk.yml, bucket "akorahub-releases").
//
// Le client Flutter ne peut pas uploader directement sur R2 (pas de clé
// secrète dans l'app) : cette fonction génère une URL signée temporaire
// (PUT, valable 5 min) que l'app utilise ensuite pour envoyer le fichier
// directement à R2, sans faire transiter l'image par Supabase.
//
// Body JSON attendu :
// - { "action": "presign-upload", "fileName": "...", "contentType": "image/jpeg" }
//   -> { uploadUrl, publicUrl }
// - { "action": "delete", "imageUrl": "https://pub-xxxx.r2.dev/..." }
//   -> { ok: true } (le chemin R2 est déduit de l'URL publique complète,
//      pour que le client n'ait pas besoin de connaître R2_PUBLIC_BASE_URL)
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - R2_ACCOUNT_ID : identifiant de compte Cloudflare (visible dans l'URL
//   du Dashboard R2, ou Cloudflare Dashboard -> R2 -> Vue d'ensemble).
// - R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY : jeton API R2 (Cloudflare
//   Dashboard -> R2 -> Gérer les jetons API -> Créer un jeton API,
//   permissions "Lecture et écriture" limitées au bucket ci-dessous).
// - R2_BUCKET_NAME : nom du bucket R2 dédié aux photos produit (ex.
//   "akorahub-product-images" — différent du bucket "akorahub-releases"
//   utilisé pour l'APK, pour ne jamais mélanger les deux).
// - R2_PUBLIC_BASE_URL : URL publique du bucket (Cloudflare Dashboard ->
//   R2 -> le bucket -> Paramètres -> Accès public -> "Activer l'accès
//   public" -> domaine r2.dev fourni, ex. "https://pub-xxxx.r2.dev"),
//   SANS slash final.
//
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") ?? "";
const R2_PUBLIC_BASE_URL = Deno.env.get("R2_PUBLIC_BASE_URL") ?? "";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

const r2Endpoint = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;

function r2Client() {
  return new AwsClient({
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: "s3",
    region: "auto",
  });
}

// Seul le staff (role != 'client') peut gérer les photos produit — même
// restriction que la policy RLS `product_images_write_staff` côté
// Supabase Storage qu'on remplace ici.
async function callerIsStaff(authHeader: string | null): Promise<boolean> {
  if (!authHeader) return false;
  const jwt = authHeader.replace("Bearer ", "");
  const { data: userData, error: userErr } = await supabaseAdmin.auth.getUser(
    jwt,
  );
  if (userErr || !userData?.user) return false;
  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .single();
  return profile?.role != null && profile.role !== "client";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  if (
    !R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY ||
    !R2_BUCKET_NAME || !R2_PUBLIC_BASE_URL
  ) {
    return new Response(
      JSON.stringify({ error: "R2 non configuré (secrets manquants)" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!(await callerIsStaff(authHeader))) {
    return new Response(JSON.stringify({ error: "Non autorisé" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json();

    if (body.action === "delete") {
      const imageUrl = body.imageUrl as string | undefined;
      if (!imageUrl || !imageUrl.startsWith(`${R2_PUBLIC_BASE_URL}/`)) {
        return new Response(JSON.stringify({ error: "imageUrl invalide" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
      const fileName = imageUrl.slice(R2_PUBLIC_BASE_URL.length + 1);
      const objectUrl = `${r2Endpoint}/${R2_BUCKET_NAME}/${fileName}`;
      const res = await r2Client().fetch(objectUrl, { method: "DELETE" });
      if (!res.ok && res.status !== 404) {
        throw new Error(`R2 delete a échoué (${res.status})`);
      }
      return new Response(JSON.stringify({ ok: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const fileName = body.fileName as string | undefined;
    if (!fileName || fileName.includes("..")) {
      return new Response(JSON.stringify({ error: "fileName invalide" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    const objectUrl = `${r2Endpoint}/${R2_BUCKET_NAME}/${fileName}`;

    if (body.action === "presign-upload") {
      const contentType = (body.contentType as string | undefined) ??
        "application/octet-stream";
      const signed = await r2Client().sign(
        new Request(objectUrl, {
          method: "PUT",
          headers: { "Content-Type": contentType },
        }),
        { aws: { signQuery: true, service: "s3" } },
      );
      // Validité limitée côté aws4fetch par défaut (~15 min) ; suffisant
      // pour l'upload immédiat déclenché par l'app juste après.
      return new Response(
        JSON.stringify({
          uploadUrl: signed.url,
          publicUrl: `${R2_PUBLIC_BASE_URL}/${fileName}`,
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({ error: "action inconnue" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
