// Edge Function : suppression réelle et immédiate du compte du client
// qui l'appelle (self-service). Nécessaire pour être honnête dans le
// formulaire "Data safety" de Google Play (question "les utilisateurs
// peuvent-ils demander la suppression de leurs données ?").
//
// Un client normal (clé anon + JWT utilisateur) ne peut PAS supprimer sa
// propre ligne dans auth.users ni contourner les policies RLS d'autres
// utilisateurs — seule la clé service_role peut le faire, d'où le besoin
// d'une Edge Function plutôt qu'un simple appel Supabase côté app.
//
// Aucun secret à configurer : SUPABASE_URL, SUPABASE_ANON_KEY et
// SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement par Supabase à
// toute Edge Function.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Non authentifié" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // Client "utilisateur" : sert uniquement à vérifier QUI appelle,
    // via son propre JWT (respecte les policies RLS normales).
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await supabaseUser.auth
      .getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Utilisateur introuvable ou session expirée" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // Client "admin" (service_role) : seul habilité à supprimer
    // réellement le compte et à passer outre les policies RLS.
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // La plupart des tables liées (orders, quotes, favorites,
    // conversations, wall posts...) référencent profiles(id) avec
    // `on delete cascade` — supprimer le profil suffit à tout nettoyer
    // pour ces tables-là. On le fait explicitement avant de supprimer
    // l'utilisateur auth, par sécurité si jamais une table n'a pas la
    // cascade.
    await supabaseAdmin.from("profiles").delete().eq("id", user.id);

    const { error: deleteError } = await supabaseAdmin.auth.admin
      .deleteUser(user.id);
    if (deleteError) {
      return new Response(
        JSON.stringify({ error: deleteError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
