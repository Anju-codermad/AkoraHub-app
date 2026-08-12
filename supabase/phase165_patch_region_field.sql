-- ============================================================
-- AkoraHub - Patch Phase 165 : région de Madagascar sur le profil client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, demande explicite) : "j'ai reçu beaucoup de clients
-- viennent dans le région" — distinct de `location` (texte libre issu du
-- GPS, imprécis) et de `country` (Phase 164) : un choix fermé parmi les
-- 24 régions officielles de Madagascar (confirmées par l'Admin), pour
-- localiser fiablement les clients lors des livraisons.
-- ============================================================

alter table public.profiles
  add column if not exists region text
    check (region is null or region in (
      'Analamanga', 'Bongolava', 'Itasy', 'Vakinankaratra',
      'Amoron''i Mania', 'Atsimo-Atsinanana', 'Haute Matsiatra', 'Ihorombe',
      'Vatovavy', 'Fitovinany',
      'Alaotra-Mangoro', 'Analanjirofo', 'Ambatosoa', 'Atsinanana',
      'Betsiboka', 'Boeny', 'Melaky', 'Sofia',
      'Androy', 'Anosy', 'Atsimo-Andrefana', 'Menabe',
      'Diana', 'Sava'
    ));
