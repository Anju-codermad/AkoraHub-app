// Edge Function : notifie par e-mail l'arrivée d'une nouvelle
// proposition producteur (site web, Espace Producteurs) — déclenchée
// par un trigger AFTER INSERT sur producer_proposals (voir
// espace_producteurs_v2.sql, section 7, dépôt groupe-akora-site).
//
// Même schéma que send-proforma-invoice : net.http_post + vérification
// x-webhook-secret, envoi via Resend.
//
// Secrets nécessaires (déjà configurés, réutilisés tels quels) :
// - RESEND_API_KEY
// - WEBHOOK_SECRET
//
// ⚠️ "Ne jamais perdre une proposition si l'envoi de l'e-mail échoue"
// (demande explicite) : cette fonction ne touche jamais la ligne
// producer_proposals autrement qu'en mettant à jour
// notification_sent/notification_error — jamais en annulant ou en
// modifiant les données de la proposition elle-même. En cas d'échec
// Resend, notification_error est renseigné et l'admin peut relancer
// manuellement (voir le bouton "Renvoyer la notification" côté
// admin-producteurs.html, qui rappelle cette même fonction avec
// resend: true).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FROM_EMAIL = "Groupe Akora <notifications@groupe-akora.com>";
const TO_EMAIL = "akorafanadiovana@gmail.com";
const ADMIN_BASE_URL = "https://groupe-akora.com/admin-producteurs.html";

const PRODUCER_TYPE_LABELS: Record<string, string> = {
  particulier: "Particulier",
  entreprise: "Entreprise",
  cooperative: "Coopérative",
  association: "Association",
};

function escapeHtml(s: unknown): string {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c] as string));
}

Deno.serve(async (req) => {
  const secretHeader = req.headers.get("x-webhook-secret");
  if (secretHeader !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("Unauthorized", { status: 401 });
  }

  let proposalId: string | undefined;
  try {
    const payload = await req.json();
    // Deux formes d'appel : trigger ({table, record}) ou relance
    // manuelle depuis l'admin ({proposalId, resend: true}).
    proposalId = payload?.record?.id ?? payload?.proposalId;
    if (!proposalId) return new Response("ignored", { status: 200 });

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: proposal, error: proposalError } = await supabase
      .from("producer_proposals")
      .select("id, full_name, company_name, producer_type, region, city, address, phone, whatsapp, email, message, created_at")
      .eq("id", proposalId)
      .maybeSingle();
    if (proposalError || !proposal) {
      return new Response("proposal not found", { status: 404 });
    }

    const { data: products } = await supabase
      .from("producer_proposal_products")
      .select("name, description, quantity_available, unit, indicative_price, producer_categories(label)")
      .eq("proposal_id", proposalId)
      .order("sort_order");

    const productRows = (products ?? []).map((p: Record<string, unknown>) => {
      const category = (p.producer_categories as { label?: string } | null)?.label;
      return `
        <tr>
          <td style="padding:6px 10px;border:1px solid #ddd;">${escapeHtml(p.name)}</td>
          <td style="padding:6px 10px;border:1px solid #ddd;">${escapeHtml(category || "—")}</td>
          <td style="padding:6px 10px;border:1px solid #ddd;">${escapeHtml(p.quantity_available || "—")}${p.unit ? " " + escapeHtml(p.unit) : ""}</td>
          <td style="padding:6px 10px;border:1px solid #ddd;">${escapeHtml(p.indicative_price || "—")}</td>
        </tr>`;
    }).join("");

    const contactLines = [
      proposal.phone ? `Téléphone : ${escapeHtml(proposal.phone)}` : null,
      proposal.whatsapp ? `WhatsApp : ${escapeHtml(proposal.whatsapp)}` : null,
      proposal.email ? `E-mail : ${escapeHtml(proposal.email)}` : null,
    ].filter(Boolean).join("<br/>");

    const locationLine = [proposal.address, proposal.city, proposal.region]
      .filter(Boolean).map(escapeHtml).join(", ");

    const adminLink = `${ADMIN_BASE_URL}?id=${encodeURIComponent(proposal.id)}`;

    const html = `
      <h2>Nouvelle proposition producteur</h2>
      <p>
        <strong>${escapeHtml(proposal.full_name)}</strong>
        ${proposal.company_name ? ` — ${escapeHtml(proposal.company_name)}` : ""}
        (${escapeHtml(PRODUCER_TYPE_LABELS[proposal.producer_type as string] || proposal.producer_type)})
      </p>
      <p>${contactLines || "Aucune coordonnée renseignée"}</p>
      ${locationLine ? `<p>Région/localisation : ${locationLine}</p>` : ""}
      ${proposal.message ? `<p>Message : ${escapeHtml(proposal.message)}</p>` : ""}
      <h3>Produits proposés (${(products ?? []).length})</h3>
      <table style="border-collapse:collapse;width:100%;">
        <thead>
          <tr style="background:#f0f0f0;">
            <th style="padding:6px 10px;border:1px solid #ddd;text-align:left;">Produit</th>
            <th style="padding:6px 10px;border:1px solid #ddd;text-align:left;">Catégorie</th>
            <th style="padding:6px 10px;border:1px solid #ddd;text-align:left;">Quantité disponible</th>
            <th style="padding:6px 10px;border:1px solid #ddd;text-align:left;">Prix indicatif</th>
          </tr>
        </thead>
        <tbody>${productRows}</tbody>
      </table>
      <p style="margin-top:20px;"><a href="${adminLink}">Voir la proposition complète dans l'administration</a></p>
    `;

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [TO_EMAIL],
        subject: `Nouvelle proposition producteur — ${proposal.full_name}`,
        html,
      }),
    });

    if (!resendRes.ok) {
      const errText = await resendRes.text();
      console.error("Échec envoi Resend (proposition producteur) :", errText);
      await supabase
        .from("producer_proposals")
        .update({ notification_sent: false, notification_error: errText.slice(0, 500) })
        .eq("id", proposalId);
      return new Response("error", { status: 500 });
    }

    await supabase
      .from("producer_proposals")
      .update({ notification_sent: true, notification_error: null })
      .eq("id", proposalId);

    return new Response("ok");
  } catch (e) {
    console.error(e);
    if (proposalId) {
      try {
        const supabase = createClient(
          Deno.env.get("SUPABASE_URL")!,
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
        );
        await supabase
          .from("producer_proposals")
          .update({ notification_sent: false, notification_error: String((e as Error).message ?? e).slice(0, 500) })
          .eq("id", proposalId);
      } catch (_) { /* on ne peut rien faire de plus ici */ }
    }
    return new Response("error: " + (e as Error).message, { status: 500 });
  }
});
