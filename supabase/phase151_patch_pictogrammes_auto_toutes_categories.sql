-- ============================================================
-- AkoraHub - Patch Phase 151 : pictogrammes SGH/CLP automatiques
-- pour TOUT le catalogue Académie existant (les 13 catégories), pas
-- seulement les 5 oxydants de phase150.
--
-- Principe : chaque fiche Académie a déjà des phrases H assignées
-- (danger réel documenté au moment de sa création, catégorie par
-- catégorie). On déduit le(s) pictogramme(s) à partir de ces phrases
-- H via la correspondance standard CLP :
--   H225/H226            -> GHS02 (inflammable)
--   H272                 -> GHS03 (comburant)
--   H290/H314/H318       -> GHS05 (corrosif)
--   H311/H331            -> GHS06 (toxique, catégorie 3)
--   H302/H303/H312/H315/
--   H317/H319/H332/H335/
--   H336                 -> GHS07 (irritant/nocif)
--   H304/H351            -> GHS08 (danger santé : aspiration/cancérogène)
--   H400/H410/H411/H412  -> GHS09 (environnement aquatique)
--
-- Sécurité : ne touche QUE les fiches n'ayant encore AUCUN
-- pictogramme (`not exists academie_pictograms`) — rien n'écrase un
-- choix déjà fait à la main dans l'éditeur admin. Les 5 oxydants de
-- phase150 sont donc automatiquement ignorés (déjà pourvus).
--
-- Limite à connaître : cette correspondance est une règle générale,
-- pas garantie exacte dans 100 % des cas particuliers (certaines
-- classifications dépendent de la concentration précise du produit).
-- Statut `a_valider` déjà en place sur toutes les fiches concernées :
-- à vérifier au même titre que le reste du contenu.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_map jsonb := '{
    "H225": "GHS02", "H226": "GHS02",
    "H272": "GHS03",
    "H290": "GHS05", "H314": "GHS05", "H318": "GHS05",
    "H311": "GHS06", "H331": "GHS06",
    "H302": "GHS07", "H303": "GHS07", "H312": "GHS07",
    "H315": "GHS07", "H317": "GHS07", "H319": "GHS07",
    "H332": "GHS07", "H335": "GHS07", "H336": "GHS07",
    "H304": "GHS08", "H351": "GHS08",
    "H400": "GHS09", "H410": "GHS09", "H411": "GHS09", "H412": "GHS09"
  }'::jsonb;
  v_inserted int;
begin
  insert into public.academie_pictograms (academie_id, pictogram_id)
  select distinct ah.academie_id, dp.id
  from public.academie_phrases_h ah
  join public.phrases_h h on h.id = ah.phrase_h_id
  join public.danger_pictograms dp on dp.code = v_map ->> h.code
  where v_map ? h.code
    and not exists (
      select 1 from public.academie_pictograms existing
      where existing.academie_id = ah.academie_id
    )
  on conflict (academie_id, pictogram_id) do nothing;

  get diagnostics v_inserted = row_count;
  raise notice 'Pictogrammes ajoutés automatiquement : % lignes (academie_id x pictogramme).', v_inserted;
end $$;
