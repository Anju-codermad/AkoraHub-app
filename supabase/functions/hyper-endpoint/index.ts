// Edge Function : proxy de connexion email/mot de passe, avec blocage
// après 5 échecs en 15 minutes pour un même email.
//
// ⚠️ Nom déployé : `hyper-endpoint`, pas `secure-login`. Le Dashboard
// Supabase (déploiement via l'éditeur en ligne, sur mobile) a assigné un
// nom aléatoire à la création malgré plusieurs tentatives pour le nommer
// explicitement — plutôt que de continuer à lutter contre l'UI, l'app
// appelle ce nom tel quel (voir authentication_screen.dart, `_handleLogin`).
// Le dossier local a été renommé pour correspondre.
//
// Contexte (31/07) : le hook officiel Supabase Auth "Password
// Verification Attempt" (voir supabase/phase34_patch_security_audit_log.sql)
// s'est révélé réservé aux plans Team/Enterprise — indisponible sur notre
// plan. Cette fonction obtient une protection équivalente sans dépendre
// de ce hook : l'app appelle CETTE fonction au lieu d'appeler
// `auth.signInWithPassword` directement, ce qui nous laisse vérifier le
// nombre d'échecs récents AVANT de relayer la tentative à Supabase Auth.
//
// Secrets : aucun à configurer, SUPABASE_URL/SUPABASE_ANON_KEY/
// SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement.
//
// Contrat de réponse (toujours HTTP 200 sauf erreur interne inattendue,
// pour que le client n'ait qu'un seul chemin de lecture à gérer) :
//   succès           -> { ok: true, access_token, refresh_token }
//   échec attendu    -> { ok: false, error: "message en français" }
//   erreur interne   -> HTTP 500 { ok: false, error: "..." }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILED_ATTEMPTS = 5;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  try {
    const { email: rawEmail, password } = await req.json();
    const email = String(rawEmail ?? "").trim().toLowerCase();

    if (!email || !password) {
      return jsonResponse({ ok: false, error: "Email et mot de passe requis." });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const now = new Date();

    const { data: tracker } = await supabaseAdmin
      .from("login_rate_limit")
      .select("failed_count, last_attempt_at, locked_until")
      .eq("email", email)
      .maybeSingle();

    if (tracker?.locked_until && new Date(tracker.locked_until) > now) {
      const minutesLeft = Math.ceil(
        (new Date(tracker.locked_until).getTime() - now.getTime()) / 60000,
      );
      return jsonResponse({
        ok: false,
        error:
          `Trop de tentatives échouées. Réessayez dans ${minutesLeft} minute(s).`,
      });
    }

    // Relaie la tentative au vrai endpoint GoTrue (mot de passe) — c'est
    // Supabase Auth qui valide réellement le mot de passe, cette fonction
    // ne fait qu'ajouter une vérification AVANT et journaliser APRÈS.
    const tokenRes = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/auth/v1/token?grant_type=password`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: Deno.env.get("SUPABASE_ANON_KEY")!,
        },
        body: JSON.stringify({ email, password }),
      },
    );
    const tokenData = await tokenRes.json();

    if (tokenRes.ok && tokenData.access_token) {
      // Succès : on remet le compteur à zéro et on journalise.
      await supabaseAdmin.from("login_rate_limit").delete().eq("email", email);
      await supabaseAdmin.from("security_audit_log").insert({
        event_type: "login_success",
        user_id: tokenData.user?.id ?? null,
        metadata: { via: "secure_login_proxy" },
      });
      return jsonResponse({
        ok: true,
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
      });
    }

    // Échec : incrémente le compteur (repart de zéro si la fenêtre de 15
    // minutes précédente est dépassée), verrouille au 5e échec.
    const lastAttempt = tracker?.last_attempt_at
      ? new Date(tracker.last_attempt_at)
      : null;
    const windowExpired = !lastAttempt ||
      now.getTime() - lastAttempt.getTime() > WINDOW_MS;
    const failedCount = (windowExpired ? 0 : (tracker?.failed_count ?? 0)) + 1;
    const lockedUntil = failedCount >= MAX_FAILED_ATTEMPTS
      ? new Date(now.getTime() + WINDOW_MS).toISOString()
      : null;

    await supabaseAdmin.from("login_rate_limit").upsert({
      email,
      failed_count: failedCount,
      last_attempt_at: now.toISOString(),
      locked_until: lockedUntil,
    });
    await supabaseAdmin.from("security_audit_log").insert({
      event_type: "login_failed",
      user_id: null,
      metadata: { via: "secure_login_proxy", email },
    });

    return jsonResponse({
      ok: false,
      error: tokenData.error_description ?? tokenData.msg ??
        "Email ou mot de passe incorrect",
    });
  } catch (e) {
    console.error(e);
    return jsonResponse(
      { ok: false, error: "Une erreur est survenue. Réessayez." },
      500,
    );
  }
});
