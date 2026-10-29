-- ============================================================
-- AkoraHub - Patch Phase 286 : fusion des formations "Liquide
-- vaisselle" FR + MG en un seul emplacement bilingue
--
-- Demande explicite (29/10) : un seul emplacement dans le catalogue
-- (pas deux formations séparées) — le client choisit la langue avec
-- un bouton FR/MG à l'intérieur de la formation. Ce patch :
-- 1) ajoute des colonnes malgaches (title_mg/content_text_mg) sur
--    formation_course_modules
-- 2) copie le texte malgache (déjà saisi en phase283/284/285) dans
--    ces colonnes, sur l'emplacement catalogue officiel français
--    ("Liquide Vaisselle", catégorie "Entretien & Hygiène")
-- 3) ajoute en français les 2 modules qui n'existaient qu'en malgache
--    (où acheter les matières premières, conseils de prix de vente)
-- 4) supprime la formation malgache séparée ("Ranon-tsavony fanasana
--    vilia") — son contenu est maintenant fusionné dans la formation
--    française, affiché via le bouton FR/MG côté client.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_course_modules
  add column if not exists title_mg text,
  add column if not exists content_text_mg text;

-- 1) Copier le texte malgache sur les 6 modules déjà communs (0 à 5),
--    en les faisant correspondre par sort_order.
update public.formation_course_modules fr
set title_mg = mg.title,
    content_text_mg = mg.content_text
from public.formation_course_modules mg
join public.formation_courses mgc on mgc.id = mg.course_id
where mgc.title = 'Ranon-tsavony fanasana vilia'
  and fr.course_id = (
    select id from public.formation_courses
    where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
  )
  and fr.sort_order = mg.sort_order
  and mg.sort_order between 0 and 5;

-- 2) Ajouter en français les 2 modules qui n'existaient qu'en malgache
insert into public.formation_course_modules
  (course_id, title, content_text, title_mg, content_text_mg, sort_order)
select
  (select id from public.formation_courses
   where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'),
  title, content_text, title_mg, content_text_mg, sort_order
from (values
  (6,
   'Où acheter les matières premières',
   $$Toutes les matières premières utilisées dans cette formation (SLES, CAPB, Comperlan, sel, acide citrique, colorant, parfum, conservateur) sont disponibles dans le catalogue Akora Fanadiovana — consultez l'onglet « Matières premières » dans l'application pour voir les prix et la disponibilité actuels.$$,
   'Aiza no hividianana ireo akora',
   $$Ny akora rehetra ampiasaina amin'ity fiofanana ity (SLES, CAPB, Comperlan, sira, acide citrique, loko, manitra, fitahirizana) dia hita ao amin'ny tahirin-java-mividy an'i Akora Fanadiovana — jereo ny tabilao "Matières premières" ao amin'ny application mba hahitana ny vidiny sy ny fahazoana azy ankehitriny.$$),
  (7,
   'Conseils pour le prix de vente',
   $$Calculez d'abord le coût de fabrication (matières premières + emballage + énergie) par litre, puis ajoutez une marge raisonnable (par exemple 30 % à 50 % selon votre lieu de vente). Comparez aussi avec les prix des produits similaires sur votre marché pour fixer un prix attractif pour vos clients, tout en restant rentable.$$,
   'Torohevitra momba ny vidin''ny varotra',
   $$Kajio aloha ny vidin'ny fanamboarana (akora + fonosana + angovo) isaky ny litatra, dia ampio tombom-barotra mety (ohatra 30% ka hatramin'ny 50% arakaraka ny toerana ivarotana). Jereo koa ny vidin'ny vokatra mitovy amin'ny tsena akaiky anao mba hamaritana vidiny mifanaraka amin'ny mpividy, nefa mbola mitondra tombony ho anao.$$)
) as new_modules(sort_order, title, content_text, title_mg, content_text_mg);

-- 3) Nombre de modules à jour (8 au lieu de 6)
update public.formation_courses
set module_count = 8
where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle';

-- 4) Supprimer la formation malgache séparée (modules puis cours)
delete from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where title = 'Ranon-tsavony fanasana vilia'
);

delete from public.formation_courses
where title = 'Ranon-tsavony fanasana vilia';
