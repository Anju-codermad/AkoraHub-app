-- ============================================================
-- AkoraHub - Patch Phase 221 : compteur de visites public du site web
--
-- Contexte (08/09) : demande de rendre visible, sur le site
-- (groupe-akora.com), le nombre de visites — un badge public affiché
-- dans le pied de page ("preuve sociale"), pas un tableau de bord privé.
--
-- Une seule ligne (id = 1) porte le compteur global. Incrémenté via la
-- fonction SECURITY DEFINER ci-dessous, jamais par un UPDATE direct du
-- client — sinon n'importe qui pourrait remettre le compteur à
-- n'importe quelle valeur via l'API REST publique. La lecture reste
-- ouverte à tous (le badge doit être visible sans authentification).
--
-- Compté une fois par session de navigation côté client (sessionStorage,
-- voir site/assets/visits.js), pas à chaque page vue — mais rien
-- n'empêche un visiteur motivé de rappeler la fonction plusieurs fois
-- (pas d'authentification sur l'appel RPC). Compromis assumé pour un
-- badge de preuve sociale, pas une métrique d'audit — même limite que
-- n'importe quel compteur de visites public.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New
-- query. Idempotent (create if not exists / create or replace).
-- ============================================================

create table if not exists public.site_visit_counter (
  id smallint primary key default 1,
  count bigint not null default 0,
  constraint site_visit_counter_single_row check (id = 1)
);

insert into public.site_visit_counter (id, count) values (1, 0)
on conflict (id) do nothing;

alter table public.site_visit_counter enable row level security;

drop policy if exists "site_visit_counter_select_all" on public.site_visit_counter;
create policy "site_visit_counter_select_all" on public.site_visit_counter
  for select using (true);

-- Aucune policy INSERT/UPDATE/DELETE pour anon/authenticated : la seule
-- façon de faire progresser le compteur est cette fonction (+1 à chaque
-- appel, jamais une valeur arbitraire).
create or replace function public.increment_site_visits()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count bigint;
begin
  update public.site_visit_counter set count = count + 1 where id = 1
  returning count into v_count;
  return v_count;
end;
$$;

grant execute on function public.increment_site_visits() to anon, authenticated;
