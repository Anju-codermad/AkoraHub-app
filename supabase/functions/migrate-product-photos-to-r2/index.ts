// Edge Function : migre les photos produit déjà existantes depuis
// Supabase Storage (bucket "products") vers Cloudflare R2 — demande
// explicite de la propriétaire (12/10), pour faire baisser le "Cached
// Egress" Supabase (quota gratuit dépassé à 213%). Complète
// `r2-product-photo` (qui gère les NOUVELLES photos) : celle-ci ne
// s'occupe que de celles déjà en ligne avant la bascule.
//
// À appeler manuellement, une ou plusieurs fois (traite un lot à la
// fois, voir `limit`) jusqu'à ce que la réponse indique `remaining: 0` —
// idempotent : une ligne déjà migrée (image_url commençant déjà par
// R2_PUBLIC_BASE_URL) est ignorée, donc rappeler la fonction sans risque
// de doublon ou de perte si un appel précédent s'est arrêté en cours de
// route (timeout, coupure réseau...).
//
// Body JSON optionnel : { "limit": 20 } (défaut 20 — rester prudent sur
// le temps d'exécution d'un Edge Function).
//
// Mêmes secrets que `r2-product-photo` (R2_ACCOUNT_ID, R2_ACCESS_KEY_ID,
// R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_PUBLIC_BASE_URL) + protégée
// par le même contrôle "staff uniquement" (profils non-client).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") ?? "";
const R2_PUBLIC_BASE_URL = Deno.env.get("R2_PUBLIC_BASE_URL") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

const supabaseAdmin = createClient(
  SUPABASE_URL,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

const r2Endpoint = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
const r2 = new AwsClient({
  accessKeyId: R2_ACCESS_KEY_ID,
  secretAccessKey: R2_SECRET_ACCESS_KEY,
  service: "s3",
  region: "auto",
});

const OLD_BASE = `${SUPABASE_URL}/storage/v1/object/public/products/`;

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

async function migrateOnePath(path: string): Promise<string> {
  const { data: fileBlob, error: dlErr } = await supabaseAdmin.storage
    .from("products")
    .download(path);
  if (dlErr || !fileBlob) {
    throw new Error(`Téléchargement Supabase Storage échoué : ${dlErr?.message}`);
  }
  const bytes = new Uint8Array(await fileBlob.arrayBuffer());
  const objectUrl = `${r2Endpoint}/${R2_BUCKET_NAME}/${path}`;
  const putRes = await r2.fetch(objectUrl, {
    method: "PUT",
    body: bytes,
    headers: { "Content-Type": fileBlob.type || "image/jpeg" },
  });
  if (!putRes.ok) {
    throw new Error(`Upload R2 échoué (${putRes.status})`);
  }
  return `${R2_PUBLIC_BASE_URL}/${path}`;
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

  if (!(await callerIsStaff(req.headers.get("Authorization")))) {
    return new Response(JSON.stringify({ error: "Non autorisé" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  let limit = 20;
  try {
    const body = await req.json();
    if (typeof body?.limit === "number" && body.limit > 0) {
      limit = Math.min(body.limit, 100);
    }
  } catch (_) {
    // Pas de corps JSON fourni : on garde la limite par défaut.
  }

  const migrated: string[] = [];
  const failed: { table: string; id: string; error: string }[] = [];

  // Migre une table à la fois (même colonne `image_url` dans les deux) :
  // 1) product_images : la galerie (jusqu'à 10 photos par produit).
  // 2) product_variants : la photo spécifique d'une variante (format/
  //    parfum/concentration/couleur), voir product_variants_screen.dart.
  async function migrateTable(table: "product_images" | "product_variants") {
    const { data: rows, error: selErr } = await supabaseAdmin
      .from(table)
      .select("id, image_url")
      .like("image_url", `${OLD_BASE}%`)
      .limit(limit);
    if (selErr) throw new Error(selErr.message);

    for (const row of rows ?? []) {
      const path = (row.image_url as string).slice(OLD_BASE.length);
      try {
        const newUrl = await migrateOnePath(path);
        await supabaseAdmin
          .from(table)
          .update({ image_url: newUrl })
          .eq("id", row.id);
        if (table === "product_images") {
          // Photo de couverture : `products.image_url` duplique la
          // première photo de la galerie (voir
          // phase8_patch_product_images.sql) — mise à jour en même temps
          // si elle pointait vers ce même fichier.
          await supabaseAdmin
            .from("products")
            .update({ image_url: newUrl })
            .eq("image_url", row.image_url);
        }
        migrated.push(`${table}:${row.id}`);
      } catch (err) {
        failed.push({ table, id: row.id as string, error: String(err) });
      }
    }
  }

  try {
    await migrateTable("product_images");
    await migrateTable("product_variants");
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const [{ count: remainingImages }, { count: remainingVariants }] =
    await Promise.all([
      supabaseAdmin
        .from("product_images")
        .select("id", { count: "exact", head: true })
        .like("image_url", `${OLD_BASE}%`),
      supabaseAdmin
        .from("product_variants")
        .select("id", { count: "exact", head: true })
        .like("image_url", `${OLD_BASE}%`),
    ]);

  return new Response(
    JSON.stringify({
      migrated: migrated.length,
      failed,
      remaining: (remainingImages ?? 0) + (remainingVariants ?? 0),
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
