// Edge Function : génère et envoie par e-mail la facture proforma PDF
// d'une demande de diagnostic qualité de l'eau (site web), dès qu'elle
// arrive avec un e-mail et un montant réel (voir le trigger AFTER
// INSERT dans supabase/phase219_patch_proforma_invoice_email.sql, qui
// exclut déjà le forfait "ONG/Communauté" — "sur devis", pas de
// montant à facturer — et toute demande sans e-mail).
//
// Secrets nécessaires (Supabase Dashboard -> Edge Functions -> Manage
// secrets) :
// - RESEND_API_KEY : clé API Resend (resend.com -> API Keys), une fois
//   le domaine d'envoi vérifié.
// - WEBHOOK_SECRET : déjà configuré pour les autres triggers, réutilisé
//   tel quel ici (voir phase219).
// (SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis
// automatiquement par Supabase à toute Edge Function.)
//
// ⚠️ L'adresse d'expédition ci-dessous (`FROM_EMAIL`) doit utiliser un
// domaine (ou sous-domaine) réellement vérifié dans Resend — à adapter
// si vous vérifiez autre chose que groupe-akora.com directement.
//
// Les prix ne sont JAMAIS pris depuis le payload envoyé par le
// formulaire — uniquement recalculés ici depuis `water_analysis_packs`/
// `water_analysis_tests` (même source de vérité que le trigger
// anti-falsification `enforce_water_diagnostic_pricing()`, phase217),
// pour que la facture reflète toujours le vrai prix, jamais une valeur
// que le client aurait pu falsifier avant que ce trigger n'existe.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PDFDocument, rgb, StandardFonts } from "https://esm.sh/pdf-lib@1.17.1";

const FROM_EMAIL = "Akora Fanadiovana <facturation@groupe-akora.com>";
const BCC_EMAIL = "akorafanadiovana@gmail.com";
const FLACON_PRICE = 24000;

const COMPANY = {
  name: "AKORA FANADIOVANA",
  address: "67ha Nord, Ankasina, Antananarivo, Madagascar",
  phone: "Tél : 034 08 746 96",
  email: "Email : akorafanadiovana@gmail.com",
};

interface LineItem {
  description: string;
  quantity: number;
  unitPrice: number;
}

function formatAr(n: number): string {
  return `${Math.round(n).toLocaleString("fr-FR")} Ar`;
}

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
}

async function buildInvoicePdf(
  record: Record<string, unknown>,
  lineItems: LineItem[],
  total: number,
  deposit: number | null,
): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  const page = doc.addPage([595, 842]); // A4
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);

  const marginLeft = 50;
  const rightEdge = 545;
  let y = 792;

  const drawLeft = (text: string, size: number, useBold = false, x = marginLeft) => {
    page.drawText(text, { x, y, size, font: useBold ? bold : font, color: rgb(0, 0, 0) });
  };
  const drawRight = (text: string, size: number, useBold = false) => {
    const f = useBold ? bold : font;
    const width = f.widthOfTextAtSize(text, size);
    page.drawText(text, { x: rightEdge - width, y, size, font: f, color: rgb(0, 0, 0) });
  };

  // ---- En-tête société ----
  drawLeft(COMPANY.name, 13, true);
  y -= 16;
  drawLeft(COMPANY.address, 9);
  y -= 12;
  drawLeft(COMPANY.phone, 9);
  y -= 12;
  drawLeft(COMPANY.email, 9);
  y -= 30;

  // ---- Titre ----
  drawLeft(`PROFORMA N° ${record.proforma_number}`, 15, true);
  y -= 18;
  const dateStr = new Intl.DateTimeFormat("fr-FR", {
    day: "2-digit", month: "2-digit", year: "numeric",
  }).format(new Date(record.created_at as string));
  drawLeft(`Date : ${dateStr}`, 9);
  y -= 26;

  // ---- Bloc client ----
  drawLeft("Client :", 10, true);
  y -= 14;
  drawLeft(String(record.name ?? ""), 9);
  y -= 12;
  if (record.phone) { drawLeft(String(record.phone), 9); y -= 12; }
  if (record.email) { drawLeft(String(record.email), 9); y -= 12; }
  if (record.client_type === "entreprise" || record.client_type === "organisation") {
    if (record.company_name) { drawLeft(String(record.company_name), 9); y -= 12; }
    if (record.nif) { drawLeft(`NIF : ${record.nif}`, 9); y -= 12; }
    if (record.stat) { drawLeft(`STAT : ${record.stat}`, 9); y -= 12; }
    if (record.contact_person) { drawLeft(`Contact : ${record.contact_person}`, 9); y -= 12; }
  }
  y -= 20;

  // ---- Tableau des lignes ----
  const colDesc = marginLeft;
  const colQty = 340;
  const colUnit = 390;
  const colTotal = rightEdge;
  const rowHeight = 20;
  const tableTop = y;

  page.drawRectangle({
    x: marginLeft, y: y - rowHeight + 6, width: rightEdge - marginLeft, height: rowHeight,
    color: rgb(0.9, 0.9, 0.9),
  });
  drawLeft("Description", 9, true, colDesc + 4);
  drawLeft("Qté", 9, true, colQty);
  drawLeft("Prix unit.", 9, true, colUnit);
  drawRight("Total", 9, true);
  y -= rowHeight;

  for (const item of lineItems) {
    drawLeft(item.description, 8.5, false, colDesc + 4);
    drawLeft(String(item.quantity), 8.5, false, colQty);
    drawLeft(formatAr(item.unitPrice), 8.5, false, colUnit);
    drawRight(formatAr(item.quantity * item.unitPrice), 8.5);
    y -= rowHeight;
  }

  const tableBottom = y + rowHeight - 6;
  page.drawRectangle({
    x: marginLeft, y: tableBottom, width: rightEdge - marginLeft, height: tableTop - tableBottom + 6,
    borderColor: rgb(0.6, 0.6, 0.6), borderWidth: 1,
  });
  page.drawLine({
    start: { x: marginLeft, y: tableTop - rowHeight + 6 },
    end: { x: rightEdge, y: tableTop - rowHeight + 6 },
    color: rgb(0.6, 0.6, 0.6), thickness: 1,
  });

  y -= 16;
  drawRight(`TOTAL : ${formatAr(total)}`, 11, true);
  if (deposit != null) {
    y -= 16;
    drawRight(`Acompte à régler en ligne (50%) : ${formatAr(deposit)}`, 10, true);
  }

  return await doc.save();
}

Deno.serve(async (req) => {
  const secretHeader = req.headers.get("x-webhook-secret");
  if (secretHeader !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const payload = await req.json();
    const record = payload.record as Record<string, unknown>;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let lineItems: LineItem[] = [];

    if (record.selected_pack) {
      const { data: pack } = await supabase
        .from("water_analysis_packs")
        .select("label, price")
        .eq("slug", record.selected_pack)
        .maybeSingle();
      if (pack && pack.price != null) {
        lineItems = [{ description: pack.label, quantity: 1, unitPrice: pack.price }];
      }
    } else if (Array.isArray(record.requested_analyses) && record.requested_analyses.length > 0) {
      const { data: tests } = await supabase
        .from("water_analysis_tests")
        .select("slug, category, label, price")
        .in("slug", record.requested_analyses as string[]);
      for (const t of tests ?? []) {
        lineItems.push({ description: t.label, quantity: 1, unitPrice: t.price });
      }
      if ((tests ?? []).some((t) => t.category === "microbiologie")) {
        lineItems.push({
          description: "Flacon de prélèvement stérile",
          quantity: 1,
          unitPrice: FLACON_PRICE,
        });
      }
    }

    const computedTotal = lineItems.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);
    const total = (record.estimated_total as number) ?? computedTotal;
    if (lineItems.length > 0 && Math.abs(computedTotal - total) > 1) {
      console.error(
        `Écart entre le total recalculé (${computedTotal}) et estimated_total (${total}) pour la demande ${record.id}`,
      );
    }
    const deposit = (record.deposit_amount as number | null) ?? null;

    const pdfBytes = await buildInvoicePdf(record, lineItems, total, deposit);
    const pdfBase64 = toBase64(pdfBytes);

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [record.email],
        bcc: [BCC_EMAIL],
        subject: `Votre proforma N° ${record.proforma_number} — Diagnostic qualité de l'eau`,
        html:
          `<p>Bonjour ${record.name ?? ""},</p>` +
          `<p>Merci pour votre demande de diagnostic qualité de l'eau. Vous trouverez ci-joint votre facture proforma ` +
          `(N° ${record.proforma_number}).</p>` +
          (deposit != null
            ? `<p>Un acompte de <strong>${formatAr(deposit)}</strong> (50%) est à régler en ligne pour confirmer votre prélèvement.</p>`
            : "") +
          `<p>Notre équipe vous recontactera pour organiser la suite.</p>` +
          `<p>Akora Fanadiovana</p>`,
        attachments: [
          {
            filename: `proforma-${record.proforma_number}.pdf`,
            content: pdfBase64,
          },
        ],
      }),
    });

    if (!resendRes.ok) {
      console.error("Échec envoi Resend :", await resendRes.text());
      return new Response("error", { status: 500 });
    }

    return new Response("ok");
  } catch (e) {
    console.error(e);
    return new Response("error: " + (e as Error).message, { status: 500 });
  }
});
