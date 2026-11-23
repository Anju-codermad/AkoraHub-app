// Edge Function : incruste un filigrane discret (logo Groupe Akora +
// "groupe-akora.com", en bas à droite) sur les photos produit — demande
// explicite de la propriétaire (12/11) : les photos du site et de l'App
// doivent pouvoir être vues et partagées, mais une copie récupérée doit
// porter la marque.
//
// Le filigrane est INCRUSTÉ dans le fichier (pas un simple calque CSS ou
// Flutter par-dessus l'image) : c'est la seule protection qui suit la
// photo quand quelqu'un la récupère (capture, lien direct, clic droit
// contourné...).
//
// Deux actions (Body JSON) :
// - { "action": "watermark-one", "imageUrl": "https://..." }
//   -> { publicUrl } : nouvelle photo avec filigrane (préfixe `wm/` dans le
//   bucket R2). Appelée par l'App juste après l'upload d'une NOUVELLE
//   photo (voir lib/core/storage/r2_photo_uploader.dart).
// - { "action": "batch", "exclude": ["<table>:<id>", ...] }
//   -> { done, failed, remaining } : traite UNE photo déjà en ligne
//   (products / product_images / product_variants) et met à jour son URL
//   en base. L'App rappelle en boucle jusqu'à `remaining: 0` (bouton
//   "Ajouter le filigrane" dans Produits). Une seule photo par appel :
//   le décodage/encodage d'image consomme du temps CPU, limité par appel
//   sur les Edge Functions.
//
// ⚠️ Ne supprime JAMAIS la photo d'origine : la version filigranée est
// écrite à côté (`wm/...`), seule l'URL en base change. Idempotent : une
// URL contenant déjà `/wm/` est ignorée.
//
// Secrets : les mêmes que `r2-product-photo` (R2_ACCOUNT_ID,
// R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME,
// R2_PUBLIC_BASE_URL) — rien de nouveau à créer. Optionnel :
// WATERMARK_URL (défaut : https://groupe-akora.com/assets/watermark.png).
//
// ⚠️ Nom de fonction : si le Dashboard Supabase attribue un autre nom au
// déploiement (déjà arrivé, voir hyper-endpoint/super-endpoint), mettre
// à jour `_functionName` dans r2_photo_uploader.dart et l'appel dans
// product_management_real.dart.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") ?? "";
const R2_PUBLIC_BASE_URL = Deno.env.get("R2_PUBLIC_BASE_URL") ?? "";
const WATERMARK_URL = Deno.env.get("WATERMARK_URL") ??
  "https://groupe-akora.com/assets/watermark.png";

// Taille du filigrane : 20 % de la largeur de la photo (discret, demande
// explicite "pas beaucoup affiché"), marge 2,5 % du bord.
const WM_WIDTH_RATIO = 0.2;
const WM_MARGIN_RATIO = 0.025;
// Les photos plus grandes sont réduites avant traitement (temps CPU, et
// aucun écran n'affiche plus large de toute façon).
const MAX_WIDTH = 1600;

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

const r2Endpoint = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
const r2 = new AwsClient({
  accessKeyId: R2_ACCESS_KEY_ID,
  secretAccessKey: R2_SECRET_ACCESS_KEY,
  service: "s3",
  region: "auto",
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

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

// Orientation EXIF (tag 0x0112) d'un JPEG : les photos prises au
// téléphone sont souvent stockées "couchées" avec ce tag pour les
// redresser à l'affichage. imagescript ne le lit pas : sans cette
// correction, la photo filigranée sortirait tournée de 90°.
function jpegExifOrientation(bytes: Uint8Array): number {
  if (bytes[0] !== 0xff || bytes[1] !== 0xd8) return 1;
  let offset = 2;
  while (offset + 4 < bytes.length) {
    if (bytes[offset] !== 0xff) return 1;
    const marker = bytes[offset + 1];
    const size = (bytes[offset + 2] << 8) | bytes[offset + 3];
    if (marker === 0xe1) {
      const start = offset + 4;
      // "Exif\0\0"
      if (
        bytes[start] === 0x45 && bytes[start + 1] === 0x78 &&
        bytes[start + 2] === 0x69 && bytes[start + 3] === 0x66
      ) {
        const tiff = start + 6;
        const little = bytes[tiff] === 0x49;
        const u16 = (p: number) =>
          little ? bytes[p] | (bytes[p + 1] << 8) : (bytes[p] << 8) | bytes[p + 1];
        const u32 = (p: number) =>
          little
            ? (bytes[p] | (bytes[p + 1] << 8) | (bytes[p + 2] << 16) |
              (bytes[p + 3] << 24)) >>> 0
            : ((bytes[p] << 24) | (bytes[p + 1] << 16) | (bytes[p + 2] << 8) |
              bytes[p + 3]) >>> 0;
        const ifd = tiff + u32(tiff + 4);
        const entries = u16(ifd);
        for (let i = 0; i < entries; i++) {
          const entry = ifd + 2 + i * 12;
          if (u16(entry) === 0x0112) return u16(entry + 8);
        }
      }
      return 1;
    }
    if (marker === 0xda) return 1; // début des données image
    offset += 2 + size;
  }
  return 1;
}

// Rotation d'un quart de tour, pixel par pixel : `Image.rotate(90/270)`
// d'imagescript 1.3.0 produit une image brouillée (testé le 12/11),
// seul `rotate(180)` est fiable.
function rotate90(src: Image, clockwise: boolean): Image {
  const w = src.width, h = src.height;
  const out = new Image(h, w);
  const s = src.bitmap, d = out.bitmap;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const nx = clockwise ? h - 1 - y : y;
      const ny = clockwise ? x : w - 1 - x;
      const si = (y * w + x) * 4, di = (ny * h + nx) * 4;
      d[di] = s[si];
      d[di + 1] = s[si + 1];
      d[di + 2] = s[si + 2];
      d[di + 3] = s[si + 3];
    }
  }
  return out;
}

let watermarkCache: Image | null = null;
async function loadWatermark(): Promise<Image> {
  if (watermarkCache) return watermarkCache;
  const res = await fetch(WATERMARK_URL);
  if (!res.ok) throw new Error(`Filigrane introuvable (${res.status})`);
  watermarkCache = await Image.decode(new Uint8Array(await res.arrayBuffer()));
  return watermarkCache;
}

// Chemin R2 de la version filigranée : `wm/<chemin d'origine>.jpg` pour
// une photo déjà sur R2, `wm/ext/<horodatage>.jpg` sinon (ancienne
// photo restée sur Supabase Storage, par exemple).
function watermarkedKey(imageUrl: string): string {
  if (imageUrl.startsWith(`${R2_PUBLIC_BASE_URL}/`)) {
    const path = imageUrl.slice(R2_PUBLIC_BASE_URL.length + 1)
      .replace(/\.[a-z0-9]+$/i, "");
    return `wm/${path}.jpg`;
  }
  return `wm/ext/${Date.now()}_${crypto.randomUUID().slice(0, 8)}.jpg`;
}

async function watermarkOne(imageUrl: string): Promise<string> {
  if (imageUrl.includes("/wm/")) return imageUrl;

  const res = await fetch(imageUrl);
  if (!res.ok) throw new Error(`Photo introuvable (${res.status})`);
  const bytes = new Uint8Array(await res.arrayBuffer());

  let photo = await Image.decode(bytes);
  switch (jpegExifOrientation(bytes)) {
    case 3:
      photo = photo.rotate(180);
      break;
    case 6:
      photo = rotate90(photo, true);
      break;
    case 8:
      photo = rotate90(photo, false);
      break;
  }
  if (photo.width > MAX_WIDTH) photo = photo.resize(MAX_WIDTH, Image.RESIZE_AUTO);

  const wm = (await loadWatermark()).clone().resize(
    Math.max(120, Math.round(photo.width * WM_WIDTH_RATIO)),
    Image.RESIZE_AUTO,
  );
  const margin = Math.round(photo.width * WM_MARGIN_RATIO);
  photo.composite(
    wm,
    photo.width - wm.width - margin,
    photo.height - wm.height - margin,
  );

  const out = await photo.encodeJPEG(88);
  const key = watermarkedKey(imageUrl);
  const putRes = await r2.fetch(`${r2Endpoint}/${R2_BUCKET_NAME}/${key}`, {
    method: "PUT",
    body: out,
    headers: { "Content-Type": "image/jpeg" },
  });
  if (!putRes.ok) throw new Error(`Upload R2 échoué (${putRes.status})`);
  return `${R2_PUBLIC_BASE_URL}/${key}`;
}

type Table = "product_images" | "product_variants" | "products";
const TABLES: Table[] = ["product_images", "product_variants", "products"];

// Photos encore sans filigrane : URL renseignée, pas déjà sous `wm/`.
function pendingQuery(table: Table) {
  return supabaseAdmin
    .from(table)
    .select("id, image_url", { count: "exact" })
    .not("image_url", "is", null)
    .neq("image_url", "")
    .not("image_url", "like", "%/wm/%");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (
    !R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY ||
    !R2_BUCKET_NAME || !R2_PUBLIC_BASE_URL
  ) {
    return json({ error: "R2 non configuré (secrets manquants)" }, 500);
  }
  if (!(await callerIsStaff(req.headers.get("Authorization")))) {
    return json({ error: "Non autorisé" }, 403);
  }

  try {
    const body = await req.json().catch(() => ({}));

    if (body.action === "watermark-one") {
      const imageUrl = body.imageUrl as string | undefined;
      if (!imageUrl || !/^https:\/\//.test(imageUrl)) {
        return json({ error: "imageUrl invalide" }, 400);
      }
      return json({ publicUrl: await watermarkOne(imageUrl) });
    }

    if (body.action === "batch") {
      const exclude = new Set<string>(
        Array.isArray(body.exclude) ? body.exclude.map(String) : [],
      );
      let done = 0;
      // `ref` à renvoyer dans `exclude` au prochain appel, pour ne pas
      // retomber indéfiniment sur une photo illisible (format WebP non
      // pris en charge, lien mort...).
      const failed: { ref: string; error: string }[] = [];

      // Une seule photo traitée par appel (voir en-tête).
      outer: for (const table of TABLES) {
        const { data: rows, error } = await pendingQuery(table).limit(
          exclude.size + 1,
        );
        if (error) throw new Error(`${table} : ${error.message}`);
        for (const row of rows ?? []) {
          const ref = `${table}:${row.id}`;
          if (exclude.has(ref)) continue;
          const oldUrl = row.image_url as string;
          try {
            const newUrl = await watermarkOne(oldUrl);
            await supabaseAdmin.from(table).update({ image_url: newUrl }).eq(
              "id",
              row.id,
            );
            // `products.image_url` (couverture) duplique souvent la 1re
            // photo de la galerie : mise à jour en même temps pour ne pas
            // refiligraner le même fichier une deuxième fois.
            if (table !== "products") {
              await supabaseAdmin.from("products").update({ image_url: newUrl })
                .eq("image_url", oldUrl);
            }
            done++;
          } catch (err) {
            failed.push({ ref, error: String(err) });
          }
          break outer;
        }
      }

      const counts = await Promise.all(
        TABLES.map((t) => pendingQuery(t).limit(1)),
      );
      const remaining = counts.reduce((sum, r) => sum + (r.count ?? 0), 0);
      // `remaining` compte aussi les photos exclues (en échec) : l'App
      // s'arrête quand un appel ne traite plus rien.
      return json({ done, failed, remaining });
    }

    return json({ error: "action inconnue" }, 400);
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
