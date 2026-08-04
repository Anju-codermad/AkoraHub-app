// Edge Function : enregistre la dernière version disponible de l'app
// (appelée par la CI GitHub Actions après chaque build réussi) — l'app
// cliente compare ensuite sa propre version à celle-ci au démarrage
// pour proposer une mise à jour (voir core/updates/update_checker.dart).
// Contourne totalement le Play Store, en attendant sa publication :
// pas de vraie mise à jour automatique tant qu'on distribue par
// GitHub Releases/Firebase App Distribution, juste une invite claire.
//
// Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
// secrets), et le MÊME secret doit être configuré côté GitHub Actions
// (Settings -> Secrets and variables -> Actions) :
// - UPDATE_VERSION_WEBHOOK_SECRET (chaîne aléatoire partagée)
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const secretHeader = req.headers.get("x-webhook-secret");
    if (secretHeader !== Deno.env.get("UPDATE_VERSION_WEBHOOK_SECRET")) {
      return new Response(
        JSON.stringify({ error: "Non autorisé" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const { versionName, buildNumber, downloadUrl, releaseNotes } = await req
      .json();
    if (!versionName || !buildNumber || !downloadUrl) {
      return new Response(
        JSON.stringify({ error: "versionName/buildNumber/downloadUrl requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    await supabaseAdmin.from("app_latest_version").update({
      version_name: versionName,
      build_number: buildNumber,
      download_url: downloadUrl,
      release_notes: releaseNotes ?? null,
      updated_at: new Date().toISOString(),
    }).eq("id", 1);

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
