// Edge Function : génère un token Agora RTC (appels audio/vidéo) pour un
// canal donné. Le certificat Agora ne doit JAMAIS être présent côté
// client (il permettrait de générer des tokens pour n'importe quel
// canal) — cette fonction est le seul endroit qui le lit.
//
// ⚠️ Nom déployé : `super-endpoint`, pas `generate-agora-token` — le
// Dashboard Supabase (déploiement via l'éditeur en ligne) a de nouveau
// assigné un nom aléatoire malgré une tentative de nommage explicite
// (même situation que hyper-endpoint/secure-login) ; l'app appelle ce
// nom tel quel (voir lib/core/calls/agora_token_repo.dart).
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - AGORA_APP_ID
// - AGORA_APP_CERTIFICATE
// (SUPABASE_URL et SUPABASE_ANON_KEY sont fournis automatiquement.)
//
// uid = 0 volontairement (au lieu d'un uid par utilisateur) : Agora
// laisse alors le SDK choisir un uid côté client au moment de rejoindre
// le canal. Simplifie l'implémentation (pas besoin de convertir un uuid
// Supabase en entier 32 bits) au prix d'un contrôle un peu moins strict
// (le token n'est pas lié à un uid précis) — acceptable ici puisque
// l'accès au canal est de toute façon conditionné à une ligne
// `call_invitations` valide (voir phase37) et à une session Supabase
// authentifiée pour appeler cette fonction.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { RtcTokenBuilder, Role } from "https://esm.sh/agora-token@2.0.5";

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

    const { channelName } = await req.json();
    if (!channelName || typeof channelName !== "string") {
      return new Response(
        JSON.stringify({ error: "channelName requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const appId = Deno.env.get("AGORA_APP_ID")!;
    const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE")!;
    // 1h de validité — largement suffisant pour un appel, et un nouveau
    // token est de toute façon régénéré à chaque nouvel appel.
    const expireSeconds = 3600;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      0,
      Role.PUBLISHER,
      expireSeconds,
      expireSeconds,
    );

    return new Response(
      JSON.stringify({ appId, token, channelName }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
