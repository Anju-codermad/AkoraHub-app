// Edge Function : reçoit une mise à jour de stock envoyée par ComptivA
// (logiciel de comptabilité, projet Supabase séparé — jxehggyclclssshorphd)
// quand le stock d'un produit LIÉ à un produit AkoraHub change côté
// ComptivA (voir StockSettingsRepo côté app + le message de relais
// donné à la conversation ComptivA pour le déclencheur côté ComptivA).
//
// Sens inverse de phase245_patch_sync_stock_comptiva.sql (AkoraHub ->
// ComptivA à chaque commande livrée) — ici c'est ComptivA qui pousse
// vers AkoraHub à chaque mouvement de stock qu'il enregistre pour un
// produit lié.
//
// Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - COMPTIVA_INBOUND_SECRET : chaîne aléatoire, à renseigner aussi côté
//   ComptivA (en-tête HTTP "x-akorahub-webhook-secret").
//
// Format de requête attendu (JSON) :
// {
//   "akorahub_product_id": "uuid du produit AkoraHub (products.id)",
//   "stock_quantity": 42
// }
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const secret = Deno.env.get("COMPTIVA_INBOUND_SECRET")!;
    const provided = req.headers.get("x-akorahub-webhook-secret");
    if (!provided || provided !== secret) {
      console.error("Secret ComptivA invalide ou absent.");
      return new Response("ignored", { status: 200 });
    }

    const payload = await req.json().catch(() => null);
    const productId: string | undefined = payload?.akorahub_product_id;
    const stockQuantity = Number(payload?.stock_quantity);

    if (!productId || !Number.isFinite(stockQuantity)) {
      return new Response("ignored", { status: 200 });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error } = await supabaseAdmin
      .from("products")
      .update({ stock_quantity: stockQuantity })
      .eq("id", productId);

    if (error) {
      console.error("Échec mise à jour stock depuis ComptivA", error);
      return new Response("ok", { status: 200 });
    }

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 });
  }
});
