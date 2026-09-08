-- ============================================================
-- AkoraHub - Patch Phase 227 : rattrape les visites déjà comptées dans
-- le journal détaillé (site_visits)
--
-- Contexte (08/09) : au moment de créer site_visits (phase226), le badge
-- "X visites" existant (site_visit_counter, phase221) affichait déjà un
-- total accumulé depuis son lancement — ces visites-là n'ont jamais eu
-- leur pays/page/référent enregistrés (l'ancien compteur ne gardait
-- qu'un total global, pas de détail). Demande explicite : que ces
-- visites déjà comptées soient quand même intégrées à la nouvelle table,
-- pour que le total y soit cohérent avec le badge, plutôt que de
-- repartir de zéro.
--
-- Comble l'écart entre site_visit_counter.count et le nombre de lignes
-- déjà dans site_visits, avec des lignes "pays inconnu" (jamais capturé
-- à l'époque) — reconnaissables par leur session_id préfixé
-- "backfill-", à exclure des rapports "visites par pays" si on veut
-- uniquement le détail géographique fiable capté depuis le 08/09.
--
-- Protégé contre une double exécution : ne fait rien si des lignes
-- "backfill-" existent déjà.
--
-- À exécuter une seule fois, APRÈS la phase226 : Supabase Dashboard ->
-- SQL Editor -> New query.
-- ============================================================

do $$
declare
  v_counter bigint;
  v_current bigint;
  v_missing bigint;
begin
  select count into v_counter from public.site_visit_counter where id = 1;
  select count(*) into v_current from public.site_visits;
  v_missing := greatest(coalesce(v_counter, 0) - v_current, 0);

  if exists (select 1 from public.site_visits where session_id like 'backfill-%') then
    raise notice 'Backfill déjà effectué — aucune ligne ajoutée.';
  elsif v_missing = 0 then
    raise notice 'Rien à combler : site_visits (%) déjà >= site_visit_counter (%).', v_current, v_counter;
  else
    insert into public.site_visits (path, referrer, country, session_id, created_at)
    select null, 'backfill : visite comptée avant la mise en place du suivi détaillé (pays/page inconnus)', null,
           'backfill-' || gs, now()
    from generate_series(1, v_missing) as gs;
    raise notice '% visites historiques ajoutées (pays inconnu).', v_missing;
  end if;
end $$;

-- Vérification : total après backfill, et combien viennent du rattrapage.
select count(*) as total_site_visits,
       count(*) filter (where session_id like 'backfill-%') as dont_backfill
from public.site_visits;
