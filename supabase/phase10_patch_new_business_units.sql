-- ============================================================
-- Akora Fanadiovana - Patch Phase 10 : 3 nouveaux piliers + catégories
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : 3 nouvelles gammes discutées avec l'utilisateur, créées
-- désactivées (invisibles côté client) en attendant qu'il soit prêt à les
-- lancer — voir phase9_patch_categories_active.sql pour le mécanisme
-- actif/inactif. Un simple interrupteur dans "Piliers d'entreprise"
-- suffira à les activer le moment venu.
--   1. Matières Premières : chimie générale (hygiène, cosmétique...),
--      remplace l'ancienne idée de catégorie "Agroalimentaire" séparée
--      (Option A actée avec l'utilisateur : un ingrédient alimentaire va
--      dans sa famille chimique, ex. Acides & Bases, avec juste une note
--      "qualité alimentaire" dans sa description produit).
--   2. Anti-Nuisibles : insecticides, avec une gamme "Produits Agrivet"
--      en prévision d'un projet de revente agricole/vétérinaire.
--   3. Matières Premières Peinture : distinct du pilier ARCA PAINTS
--      existant (qui vend les peintures finies) — ici les intrants pour
--      fabriquer de la peinture. Catégories proposées par défaut, à
--      ajuster librement depuis l'écran de gestion des catégories.
-- ============================================================

insert into public.business_units (name, slug, active)
values
  ('Matières Premières', 'matieres-premieres', false),
  ('Anti-Nuisibles', 'anti-nuisibles', false),
  ('Matières Premières Peinture', 'matieres-premieres-peinture', false)
on conflict (slug) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Acides & Bases'),
  ('Chélatants'),
  ('Désinfectants'),
  ('Épaississants'),
  ('Charges Minérales'),
  ('Colorants'),
  ('Conservateurs & Antioxydants'),
  ('Huiles & Beurres Cosmétiques'),
  ('Parfums & Additifs'),
  ('Polymères & Résines'),
  ('Solvants'),
  ('Tensioactifs')
) as c(name)
where bu.slug = 'matieres-premieres'
on conflict (business_unit_id, name) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Insecticides Maison'),
  ('Insecticides Extérieur'),
  ('Anti-Fourmis & Cafards'),
  ('Anti-Moustiques & Mouches'),
  ('Raticides & Rongeurs'),
  ('Anti-Puces & Tiques'),
  ('Produits Agrivet')
) as c(name)
where bu.slug = 'anti-nuisibles'
on conflict (business_unit_id, name) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Liants & Résines'),
  ('Pigments & Colorants'),
  ('Charges & Additifs'),
  ('Solvants & Diluants'),
  ('Siccatifs & Conservateurs')
) as c(name)
where bu.slug = 'matieres-premieres-peinture'
on conflict (business_unit_id, name) do nothing;

-- Vérification : voir les 3 piliers créés et leurs catégories
select bu.name as pilier, bu.active, cat.name as categorie
from public.business_units bu
left join public.categories cat on cat.business_unit_id = bu.id
where bu.slug in ('matieres-premieres', 'anti-nuisibles', 'matieres-premieres-peinture')
order by bu.name, cat.name;
