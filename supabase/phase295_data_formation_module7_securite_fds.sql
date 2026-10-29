-- ============================================================
-- AkoraHub - Phase 295 : contenu du Module 7 "Sécurité, FDS &
-- Réglementation" — formation Liquide Vaisselle
--
-- Demande explicite (29/10). Couvre : les 16 rubriques standard
-- d'une FDS (format international GHS, vérifiable), le système CLP
-- (classification/étiquetage des dangers, vérifiable), et l'EPI —
-- repris des tags de la maquette fournie. Le tag "Codex" n'a pas
-- d'équivalent clair et vérifiable dans ce contexte (savons/
-- détergents) — non utilisé, à clarifier avec la propriétaire si
-- elle avait une source précise en tête.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. La FDS (Fiche de Données de Sécurité) — 16 rubriques standardisées

Déjà évoquée au Module 2, la FDS suit un format international standardisé en 16 rubriques (système GHS, utilisé dans le monde entier par les fournisseurs de produits chimiques) :

1. Identification du produit et de la société
2. Identification des dangers
3. Composition / informations sur les composants
4. Premiers secours
5. Mesures de lutte contre l'incendie
6. Mesures à prendre en cas de dispersion accidentelle
7. Manipulation et stockage
8. Contrôles de l'exposition / protection individuelle
9. Propriétés physiques et chimiques
10. Stabilité et réactivité
11. Informations toxicologiques
12. Informations écologiques
13. Considérations relatives à l'élimination
14. Informations relatives au transport
15. Informations réglementaires
16. Autres informations

Pour chaque matière première achetée (SLES, CAPB, Comperlan, acide citrique...), demandez systématiquement la FDS au fournisseur et conservez-la — elle est indispensable en cas d'accident (rubrique 4, premiers secours) et pour savoir comment stocker/manipuler le produit en sécurité (rubrique 7).

2. CLP — comprendre les étiquettes de vos matières premières

CLP (Classification, Labelling and Packaging) est le système international de pictogrammes et de mentions de danger qu'on retrouve sur les emballages et les FDS de vos fournisseurs. Les plus courants pour les matières premières de cosmétique/détergence :
- Pictogramme "point d'exclamation" : irritant (souvent présent sur les tensioactifs concentrés comme le SLES ou le LABSA bruts, avant dilution)
- Pictogramme "corrosion" : pour les produits très concentrés ou à pH extrême (ex. soude caustique, acide concentré)
- Mentions H (phrases de danger, ex. "H315 : provoque une irritation cutanée") et mentions P (conseils de prudence, ex. "P280 : porter des gants de protection")

Savoir lire ces pictogrammes sur l'emballage d'un fournisseur permet de juger immédiatement le niveau de précaution nécessaire avant même d'ouvrir la FDS complète.

3. EPI — équipement de protection individuelle minimal

Pour la fabrication (voir aussi la formule de base, §6 Sécurité) :
- Gants résistants aux produits chimiques (pas de simples gants de vaisselle fins pour manipuler les tensioactifs concentrés)
- Lunettes de protection, surtout lors du versement de produits concentrés (risque de projection)
- Dans un espace mal ventilé, un masque adapté peut être nécessaire selon les produits utilisés (voir la FDS, rubrique 8)

4. Bonnes pratiques réglementaires générales

- Conserver toutes les FDS de vos fournisseurs dans un classeur accessible sur le lieu de fabrication
- Étiqueter clairement tous les bidons de matières premières, y compris après transvasement dans un contenant plus petit
- Stocker les produits incompatibles séparément (toujours vérifier la rubrique 7 et 10 de la FDS en cas de doute)
- Garder les fiches de lot (Module 4) comme preuve de traçabilité en cas de contrôle ou de réclamation$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 6;
