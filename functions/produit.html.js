// Injecte des balises Open Graph propres à CHAQUE produit (photo, nom, prix)
// dans produit.html avant que Facebook/WhatsApp/Messenger ne génère
// l'aperçu du lien partagé — indispensable car ces robots ne lisent que le
// HTML brut, jamais le JavaScript qui charge normalement le produit une
// fois la page ouverte dans un vrai navigateur (25/08, demande explicite :
// la photo du produit doit apparaître dans l'aperçu du lien partagé).
//
// SUPABASE_URL/SUPABASE_ANON_KEY viennent des mêmes variables
// d'environnement déjà configurées sur le projet Cloudflare Pages (utilisées
// par ailleurs pour la commande de build) — rien de nouveau à créer.

function escapeHtml(s) {
  return (s || "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[c]));
}

export async function onRequestGet(context) {
  const { request, next, env } = context;
  const url = new URL(request.url);
  const id = url.searchParams.get("id");

  const response = await next();
  if (!id || !env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) return response;

  let product;
  try {
    const res = await fetch(
      `${env.SUPABASE_URL}/rest/v1/products?id=eq.${encodeURIComponent(id)}&select=name,price_detail,image_url,visibility`,
      { headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_ANON_KEY}` } }
    );
    const rows = await res.json();
    product = rows && rows[0];
  } catch (e) {
    return response;
  }
  if (!product || product.visibility === false) return response;

  // Produits à variantes (Format/Parfum/Concentration, ex. Eau de Javel,
  // Peroxyde d'hydrogène) : la fiche produit elle-même n'a ni photo ni
  // prix (price_detail reste à 0 par défaut, image_url à vide) — tout est
  // sur `product_variants`. Repli sur la variante la moins chère pour
  // qu'un tel produit ait quand même une vraie photo/un vrai prix dans
  // l'aperçu de lien (25/08, demande explicite : "tout le produit... doit
  // avoir un lien correspondant").
  let variant;
  if (!product.image_url || !product.price_detail) {
    try {
      const vres = await fetch(
        `${env.SUPABASE_URL}/rest/v1/product_variants?product_id=eq.${encodeURIComponent(id)}&select=price_detail,image_url&order=price_detail.asc&limit=1`,
        { headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_ANON_KEY}` } }
      );
      const vrows = await vres.json();
      variant = vrows && vrows[0];
    } catch (e) {
      // Repli silencieux : la fiche produit garde ses propres valeurs.
    }
  }

  const title = `${product.name} — Akora Fanadiovana`;
  const effectivePrice = product.price_detail || variant?.price_detail;
  const price = typeof effectivePrice === "number" && effectivePrice > 0
    ? effectivePrice.toLocaleString("fr-FR") + " Ar"
    : "";
  const description = price ? `${price} — Commandez sur AkoraHub.` : "Commandez sur AkoraHub.";
  const image = product.image_url || variant?.image_url || "https://akorahub-app.pages.dev/logo.jpg";

  const tags = `
    <meta property="og:type" content="product" />
    <meta property="og:site_name" content="Akora Fanadiovana" />
    <meta property="og:title" content="${escapeHtml(title)}" />
    <meta property="og:description" content="${escapeHtml(description)}" />
    <meta property="og:image" content="${escapeHtml(image)}" />
    <meta property="og:url" content="${escapeHtml(url.toString())}" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${escapeHtml(title)}" />
    <meta name="twitter:description" content="${escapeHtml(description)}" />
    <meta name="twitter:image" content="${escapeHtml(image)}" />
    <meta name="description" content="${escapeHtml(description)}" />
  `;

  return new HTMLRewriter()
    .on("title", { element(el) { el.setInnerContent(title); } })
    .on("head", { element(el) { el.append(tags, { html: true }); } })
    .transform(response);
}
