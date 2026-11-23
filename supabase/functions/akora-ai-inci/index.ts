// Edge Function : Akora AI propose le nom INCI d'un produit — demande
// explicite (12/11) : "laisser Akora AI gérer ça, lui donner juste la
// fonctionnalité pour la proposition". Même moteur (Gemini) que
// l'assistant Akora AI de la messagerie.
//
// Akora AI PROPOSE seulement : la proposition est rangée dans
// `products.inci_suggestion` (jamais affichée aux clients) ; c'est le
// staff qui la valide dans l'App (fiche produit -> "Valider"), ce qui la
// copie dans `products.inci`, la seule colonne affichée sur le site et
// dans l'App. Un nom INCI faux sur une fiche produit engage l'entreprise :
// il doit toujours être vérifié sur la fiche technique du fournisseur.
//
// Body JSON :
// - { "action": "suggest", "productId": "<uuid>" }
//   -> { inci, confidence, note } (et enregistre la proposition)
// - { "action": "batch", "exclude": ["<uuid>", ...] }
//   -> { done, failed, remaining } : traite UN produit sans INCI ni
//   proposition ; l'App rappelle en boucle (bouton "Akora AI : proposer
//   les INCI" dans Produits).
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Secrets) :
// - GEMINI_API_KEY : la même clé Gemini que l'assistant Akora AI
//   (Google AI Studio -> Get API key).
// - GEMINI_MODEL (optionnel, défaut "gemini-2.5-flash").
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement.
//
// Prérequis : supabase/phase308_patch_inci_akora_ai.sql exécuté.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

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

type Suggestion = { inci: string; confidence: string; note: string };

const INSTRUCTIONS = `Tu es Akora AI, l'assistant de Groupe Akora (Madagascar), qui vend des
matières premières (huiles essentielles, huiles végétales, beurres,
extraits, actifs cosmétiques, produits chimiques) et des produits finis.

On te donne un produit du catalogue. Propose son nom INCI (International
Nomenclature of Cosmetic Ingredients) UNIQUEMENT s'il s'agit d'un
ingrédient identifiable à lui seul (ex. "Huile essentielle de ravintsara"
-> "Cinnamomum Camphora Leaf Oil" ; "Beurre de karité" -> "Butyrospermum
Parkii Butter" ; "Glycérine végétale" -> "Glycerin").

Règles :
- Produit fini, mélange, formule, produit non cosmétique (eau en bidon,
  emballage, matériel, service...) ou ingrédient trop vague : réponds
  avec "inci" vide et explique pourquoi dans "note".
- N'invente jamais. En cas de doute entre plusieurs noms (espèce, partie
  de plante, forme), donne le plus probable, mets "confidence": "faible"
  et précise dans "note" ce qu'il faut vérifier.
- Écris le nom INCI avec la casse officielle (majuscule à chaque mot).
- "note" : une phrase courte en français.

Réponds UNIQUEMENT en JSON :
{"inci": "...", "confidence": "haute" | "moyenne" | "faible", "note": "..."}`;

async function askAkoraAi(product: Record<string, unknown>): Promise<Suggestion> {
  const productText = [
    `Nom : ${product.name ?? ""}`,
    product.category ? `Catégorie : ${product.category}` : null,
    product.description ? `Description : ${product.description}` : null,
  ].filter(Boolean).join("\n");

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: INSTRUCTIONS }] },
        contents: [{ role: "user", parts: [{ text: productText }] }],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: "application/json",
        },
      }),
    },
  );
  if (!res.ok) {
    throw new Error(`Akora AI indisponible (${res.status}) : ${(await res.text()).slice(0, 200)}`);
  }
  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  const parsed = JSON.parse(text);
  return {
    inci: String(parsed.inci ?? "").trim(),
    confidence: String(parsed.confidence ?? "faible"),
    note: String(parsed.note ?? "").trim(),
  };
}

async function suggestFor(productId: string): Promise<Suggestion> {
  const { data: product, error } = await supabaseAdmin
    .from("products")
    .select("id, name, category, description")
    .eq("id", productId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!product) throw new Error("Produit introuvable");

  const suggestion = await askAkoraAi(product);
  const note = `Confiance ${suggestion.confidence}${
    suggestion.note ? ` — ${suggestion.note}` : ""
  }`;
  const { error: upErr } = await supabaseAdmin
    .from("products")
    .update({ inci_suggestion: suggestion.inci, inci_note: note })
    .eq("id", productId);
  if (upErr) throw new Error(upErr.message);
  return suggestion;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!GEMINI_API_KEY) {
    return json({ error: "GEMINI_API_KEY manquant (secrets Edge Functions)" }, 500);
  }
  if (!(await callerIsStaff(req.headers.get("Authorization")))) {
    return json({ error: "Non autorisé" }, 403);
  }

  try {
    const body = await req.json().catch(() => ({}));

    if (body.action === "suggest") {
      if (body.productId) {
        return json(await suggestFor(String(body.productId)));
      }
      // Produit pas encore enregistré (création dans l'App) : proposition
      // à partir du nom saisi, sans rien écrire en base.
      if (!body.name) return json({ error: "productId ou name manquant" }, 400);
      return json(
        await askAkoraAi({
          name: body.name,
          category: body.category,
          description: body.description,
        }),
      );
    }

    if (body.action === "batch") {
      const exclude = new Set<string>(
        Array.isArray(body.exclude) ? body.exclude.map(String) : [],
      );
      const pending = () =>
        supabaseAdmin
          .from("products")
          .select("id", { count: "exact" })
          .is("inci", null)
          .is("inci_suggestion", null);

      const { data: rows, error } = await pending().limit(exclude.size + 1);
      if (error) throw new Error(error.message);

      let done = 0;
      const failed: { ref: string; error: string }[] = [];
      const next = (rows ?? []).find((r) => !exclude.has(r.id as string));
      if (next) {
        try {
          await suggestFor(next.id as string);
          done = 1;
        } catch (err) {
          failed.push({ ref: next.id as string, error: String(err) });
        }
      }

      const { count } = await pending().limit(1);
      return json({ done, failed, remaining: count ?? 0 });
    }

    return json({ error: "action inconnue" }, 400);
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
