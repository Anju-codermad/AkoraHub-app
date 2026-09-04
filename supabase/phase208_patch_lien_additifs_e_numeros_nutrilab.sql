-- ============================================================
-- AkoraHub - Patch Phase 208 : lie ~103 additifs alimentaires (numéro
-- E reconnu) à Akora NutriLab, avec leur catégorie NutriLab dédiée —
-- demande explicite de la propriétaire le 04/09/2026, suite à l'audit
-- complet du catalogue (voir phase207).
--
-- Ces produits ont un vrai numéro E (additif alimentaire reconnu au
-- niveau UE) mais n'avaient pas "alimentaire" dans leur nom, donc le
-- diagnostic initial (phases 204-206, recherche par mot-clé) ne les
-- avait pas repérés. Contrairement à la phase 205, on ne les BASCULE
-- pas vers NutriLab : ils restent sous Akora Pro comme pilier
-- principal, avec leur catégorie Akora Pro actuelle inchangée
-- (Conservateurs & Antioxydants, Colorants, Épaississants...) — déjà
-- fine et pertinente pour ce pilier généraliste.
--
-- Extension de schéma nécessaire : `product_extra_business_units`
-- (phase202) n'avait que (product_id, business_unit_id) — pas de
-- catégorie. Ajout d'une colonne `category` nullable, spécifique au
-- lien (n'affecte jamais `products.category`, qui reste le
-- classement du pilier PRINCIPAL). Permet à un produit d'avoir un
-- classement différent selon le pilier où on le regarde (ex.
-- "Conservateurs & Antioxydants" sous Akora Pro, "Additifs
-- alimentaires" sous Akora NutriLab).
--
-- Important : cette colonne stocke l'information correctement, mais
-- l'affichage groupé par catégorie sous NutriLab pour un produit LIÉ
-- (pas basculé) dépend du code Flutter du catalogue
-- (product_catalog_tab.dart), hors du périmètre de ce dépôt
-- supabase/. À vérifier/adapter côté app si le classement
-- n'apparaît pas correctement une fois ce script exécuté.
--
-- Répartition (103 produits) :
--   Colorants alimentaires (22), Édulcorants (15), Émulsifiants (3),
--   Épaississants/gélifiants/stabilisants (19), Additifs alimentaires
--   — conservateurs/acidulants/exhausteurs (44).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (add column if not exists ; upsert par nom exact).
-- ============================================================

alter table public.product_extra_business_units
  add column if not exists category text;

do $$
declare
  v_nutrilab_id uuid;
  v_linked_count int;
begin
  select id into v_nutrilab_id from public.business_units where slug = 'akora-nutrilab';
  if v_nutrilab_id is null then
    raise exception 'Pilier Akora NutriLab introuvable — exécuter d''abord la phase 203.';
  end if;

  insert into public.product_extra_business_units (product_id, business_unit_id, category)
  select p.id, v_nutrilab_id, m.nutrilab_category
  from public.products p
  join (values
    -- Colorants alimentaires
    ('Bleu brillant FCF (E133)', 'Colorants alimentaires'),
    ('Bleu patenté V (E131)', 'Colorants alimentaires'),
    ('Brun FK (E154)', 'Colorants alimentaires'),
    ('Brun HT (E155)', 'Colorants alimentaires'),
    ('Chlorophylles et chlorophyllines (E140/E141)', 'Colorants alimentaires'),
    ('Colorant caramel ammoniacal-sulfite (Classe IV — E150d)', 'Colorants alimentaires'),
    ('Colorant rouge ponceau 4R (E124)', 'Colorants alimentaires'),
    ('Colorant rouge vin / anthocyanes (E163)', 'Colorants alimentaires'),
    ('Curcumine, extrait de curcuma (E100)', 'Colorants alimentaires'),
    ('Dioxyde de titane (E171)', 'Colorants alimentaires'),
    ('Extrait de paprika / capsanthine (E160c)', 'Colorants alimentaires'),
    ('Jaune de quinoléine (E104)', 'Colorants alimentaires'),
    ('Jaune orangé S (E110)', 'Colorants alimentaires'),
    ('Lycopène, extrait de tomate (E160d)', 'Colorants alimentaires'),
    ('Noir brillant BN (E151)', 'Colorants alimentaires'),
    ('Noir végétal / charbon végétal (E153)', 'Colorants alimentaires'),
    ('Rocou / Annatto (bixine, norbixine) (E160b)', 'Colorants alimentaires'),
    ('Rouge allura AC (E129)', 'Colorants alimentaires'),
    ('Rouge carmoisine / Azorubine (E122)', 'Colorants alimentaires'),
    ('Rouge érythrosine (E127)', 'Colorants alimentaires'),
    ('Tartrazine jaune citron (E102)', 'Colorants alimentaires'),
    ('Vert S (E142)', 'Colorants alimentaires'),

    -- Édulcorants
    ('Acésulfame de potassium (Ace-K / E950)', 'Édulcorants'),
    ('Aspartame (E951)', 'Édulcorants'),
    ('Érythritol (E968)', 'Édulcorants'),
    ('Isomalt (E953)', 'Édulcorants'),
    ('Lactitol (E966)', 'Édulcorants'),
    ('Maltitol (E965) — sirop et poudre', 'Édulcorants'),
    ('Mannitol (E421)', 'Édulcorants'),
    ('Polyglycitol (E964) — poudre et sirop', 'Édulcorants'),
    ('Saccharine sodique (E954)', 'Édulcorants'),
    ('Sel d''aspartame-acésulfame (E962)', 'Édulcorants'),
    ('Sorbitol (E420)', 'Édulcorants'),
    ('Stévia (Glycosides de stéviol E960)', 'Édulcorants'),
    ('Sucralose (E955)', 'Édulcorants'),
    ('Thaumatine (E957)', 'Édulcorants'),
    ('Xylitol (E967)', 'Édulcorants'),

    -- Émulsifiants
    ('Lécithine de soja (E322)', 'Émulsifiants'),
    ('Mono- et diglycérides d''acides gras (E471)', 'Émulsifiants'),
    ('Polysorbate 80 (E433)', 'Émulsifiants'),

    -- Épaississants, gélifiants et stabilisants
    ('Agar-Agar (E406)', 'Épaississants, gélifiants et stabilisants'),
    ('Alginate de propylène glycol (PGA, E405)', 'Épaississants, gélifiants et stabilisants'),
    ('Alginate de sodium (E401)', 'Épaississants, gélifiants et stabilisants'),
    ('Amidon modifié (E1400–E1452)', 'Épaississants, gélifiants et stabilisants'),
    ('Carraghénanes (E407)', 'Épaississants, gélifiants et stabilisants'),
    ('CMC / Carboxyméthylcellulose (E466) — Tylose', 'Épaississants, gélifiants et stabilisants'),
    ('Éthylcellulose (E462)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme adragante (E413)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme arabique (E414)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme de caroube (LBG, E410)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme de konjac (E425)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme gellane (E418)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme guar (E412)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme karaya (E416)', 'Épaississants, gélifiants et stabilisants'),
    ('Gomme Tara (E417)', 'Épaississants, gélifiants et stabilisants'),
    ('HPMC (hydroxypropylméthylcellulose, E464)', 'Épaississants, gélifiants et stabilisants'),
    ('Méthylcellulose (E461)', 'Épaississants, gélifiants et stabilisants'),
    ('Pectine HM (E440i)', 'Épaississants, gélifiants et stabilisants'),
    ('Tripolyphosphate de sodium STPP (E451)', 'Épaississants, gélifiants et stabilisants'),

    -- Additifs alimentaires (conservateurs, acidulants, exhausteurs)
    ('Acide ascorbique / Ascorbate Na (E300/E301)', 'Additifs alimentaires'),
    ('Acide benzoïque (E210)', 'Additifs alimentaires'),
    ('Acide propionique (E280)', 'Additifs alimentaires'),
    ('Ascorbate de calcium (E302)', 'Additifs alimentaires'),
    ('Ascorbate de sodium (E301)', 'Additifs alimentaires'),
    ('BHA (Butylhydroxyanisole, E320)', 'Additifs alimentaires'),
    ('BHT (Butylhydroxytoluène, E321)', 'Additifs alimentaires'),
    ('Dicarbonate de diméthyle (DMDC, E242)', 'Additifs alimentaires'),
    ('Gallate d''octyle (E311)', 'Additifs alimentaires'),
    ('Gallate de dodécyle (E312)', 'Additifs alimentaires'),
    ('Gallate de propyle (E310)', 'Additifs alimentaires'),
    ('Hexaméthylènetétramine (E239)', 'Additifs alimentaires'),
    ('Lysozyme (E1105)', 'Additifs alimentaires'),
    ('Métabisulfite de potassium (E224) — ''Meta K''', 'Additifs alimentaires'),
    ('Natamycine (E235)', 'Additifs alimentaires'),
    ('Nisine (E234)', 'Additifs alimentaires'),
    ('Nitrite de sodium / Sel nitrité (E250)', 'Additifs alimentaires'),
    ('Palmitate d''ascorbyle (E304)', 'Additifs alimentaires'),
    ('Propionate de calcium (E282)', 'Additifs alimentaires'),
    ('Propionate de sodium (E281)', 'Additifs alimentaires'),
    ('Salpêtre (Nitrate de potassium KNO₃ E252)', 'Additifs alimentaires'),
    ('Salpêtre / Nitrate de potassium (E252)', 'Additifs alimentaires'),
    ('Sulfite de sodium / Métabisulfite de sodium (E221/E223)', 'Additifs alimentaires'),
    ('Acide fumarique (E297)', 'Additifs alimentaires'),
    ('Acide malique DL (E296)', 'Additifs alimentaires'),
    ('Acide phytique (E391)', 'Additifs alimentaires'),
    ('Acide tartrique L(+) (E334)', 'Additifs alimentaires'),
    ('Bicarbonate de sodium NaHCO₃ (E500ii)', 'Additifs alimentaires'),
    ('Carbonate acide d''ammonium / Bicarbonate d''ammonium (E503)', 'Additifs alimentaires'),
    ('Carbonate de calcium CaCO₃ (E170)', 'Additifs alimentaires'),
    ('Citrate de sodium (E331)', 'Additifs alimentaires'),
    ('Citrate de sodium / Citrate de potassium (E331/E332)', 'Additifs alimentaires'),
    ('Crème de tartre (Tartrate acide de potassium E336)', 'Additifs alimentaires'),
    ('Gluconate de sodium (E576)', 'Additifs alimentaires'),
    ('Tartrate de sodium (E335)', 'Additifs alimentaires'),
    ('Alun de potassium (E522)', 'Additifs alimentaires'),
    ('Chlorure de magnésium (E511)', 'Additifs alimentaires'),
    ('Chlorure de potassium (E508)', 'Additifs alimentaires'),
    ('Éthylmaltol (E637)', 'Additifs alimentaires'),
    ('Guanylate disodique / Acide guanylique (E626/E627)', 'Additifs alimentaires'),
    ('Inosinate disodique / Acide inosinique (E630/E631)', 'Additifs alimentaires'),
    ('Maltol (E636)', 'Additifs alimentaires'),
    ('Glutamate monosodique MSG (E621)', 'Additifs alimentaires'),
    ('Azodicarbonamide (E927a)', 'Additifs alimentaires')
  ) as m(product_name, nutrilab_category)
  on p.name = m.product_name
  on conflict (product_id, business_unit_id)
  do update set category = excluded.category;
  get diagnostics v_linked_count = row_count;
  raise notice '% produit(s) lié(s) à Akora NutriLab avec catégorie.', v_linked_count;
end $$;

-- Vérification : répartition par catégorie NutriLab
select category as categorie_nutrilab, count(*) as nb_produits
from public.product_extra_business_units
where business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
  and category is not null
group by category
order by category;

-- Vérification détaillée
select p.name as produit, bu.name as pilier_principal, peb.category as categorie_nutrilab
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
join public.business_units bu on bu.id = p.business_unit_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
order by peb.category, p.name;
