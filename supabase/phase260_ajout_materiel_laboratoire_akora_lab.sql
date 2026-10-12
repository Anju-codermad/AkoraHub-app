-- ============================================================
-- AkoraHub - Patch Phase 260 : remplacement/complément du matériel
-- générique du pilier "Akora Lab" (phase254) par du matériel réel,
-- issu de 2 catalogues fournisseur fournis par la propriétaire (12/10) :
--   - un catalogue "FOURNITURES - VERRERIES" (84 réf. FV001 à FV084,
--     avec caractéristiques techniques)
--   - un catalogue "TESTEURS" (réf. TS001+, noms de produit
--     uniquement, pas de caractéristiques techniques dans le document
--     source)
-- Le nom du fournisseur n'apparaît nulle part dans ce script : ces
-- produits sont revendus sous la marque Akora Lab, pas sous celle du
-- fournisseur d'origine.
--
-- Contenu non inventé : les descriptions reprennent uniquement les
-- caractéristiques réellement indiquées dans le catalogue FOURNITURES
-- (matière, dimensions, capacités). Pour le catalogue TESTEURS, le
-- document source ne donne que le nom du produit : la description
-- reste donc volontairement courte et ne fait que reformuler la
-- fonction déjà indiquée par ce nom, sans ajouter de précision/plage
-- de mesure non fournie (règle "ne pas inventer" déjà appliquée aux
-- phases précédentes).
--
-- Pour les ~9 derniers appareils du catalogue TESTEURS (pages 10-12,
-- extraites sous forme d'images), la référence fournisseur n'a pas pu
-- être lue de façon certaine : ces produits sont ajoutés sans réf.,
-- avec une mention explicite "référence non confirmée" dans la
-- description, à vérifier/compléter depuis l'Admin.
--
-- Ce script est un COMPLÉMENT à phase254 (pas un remplacement) : les
-- ~35 produits génériques de phase254 restent en place (modifiables/
-- supprimables depuis l'Admin si redondants). Deux noms de phase254
-- entraient en collision exacte avec des produits réels de ce
-- catalogue ("Bec Bunsen", "Entonnoir en verre") : les nouveaux
-- produits ci-dessous utilisent un nom légèrement différent pour ne
-- pas être ignorés par la garde `where not exists`.
--
-- Créés en BROUILLON (visibility = false) : ni prix, ni photo, ni
-- stock réels fournis — à compléter depuis l'Admin avant publication.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (where not exists sur business_unit + nom).
-- ============================================================

insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, v.category, v.name, v.description, false
from public.business_units bu
cross join (
  values

    -- ------------------------------------------------------------
    -- Verrerie de laboratoire (catalogue FOURNITURES)
    -- ------------------------------------------------------------
    ('Verrerie de laboratoire', 'Pipette Pasteur en verre',
     'Pipette Pasteur en verre sodocalcique, longueur 230 mm, diamètre extérieur 1,4 mm, diamètre intérieur 1 mm, pointe fine. Référence fournisseur : FV001.'),
    ('Verrerie de laboratoire', 'Pipette graduée en verre',
     'Pipette graduée en verre de classe A, graduation 0,1 ml, capacités disponibles : 2, 5, 10 et 20 ml. Référence fournisseur : FV003.'),
    ('Verrerie de laboratoire', 'Pipette jaugée',
     'Pipette jaugée en verre de classe A, double trait, capacités disponibles : 2, 5 et 10 ml. Référence fournisseur : FV004.'),
    ('Verrerie de laboratoire', 'Burette graduée',
     'Burette graduée en verre de classe A, standard acide/base, graduation 0,1 ml, capacités disponibles : 25 et 50 ml. Référence fournisseur : FV007.'),
    ('Verrerie de laboratoire', 'Éprouvette graduée en verre',
     'Éprouvette graduée en verre borosilicate 3,3, graduation bleue classe A, pied hexagonal, capacités disponibles : 25, 100, 250, 500 et 1000 ml. Référence fournisseur : FV008.'),
    ('Verrerie de laboratoire', 'Bécher en verre',
     'Bécher en verre borosilicate 3,3, forme basse, bec verseur, capacités disponibles : 10, 25, 50, 100, 250 et 1000 ml. Référence fournisseur : FV009.'),
    ('Verrerie de laboratoire', 'Erlenmeyer en verre',
     'Erlenmeyer en verre borosilicate 3,3, col large, avec ou sans bouchon, capacités disponibles : 100, 250, 500 et 1000 ml. Référence fournisseur : FV010.'),
    ('Verrerie de laboratoire', 'Cristallisoir',
     'Cristallisoir en verre borosilicate, bec verseur, capacité 60 ml. Référence fournisseur : FV011.'),
    ('Verrerie de laboratoire', 'Verre de montre',
     'Verre de montre en verre borosilicate, diamètre 90 mm. Référence fournisseur : FV012.'),
    ('Verrerie de laboratoire', 'Baguette en verre',
     'Baguette en verre borosilicate, longueur 200 mm, diamètre 8 mm. Référence fournisseur : FV013.'),
    ('Verrerie de laboratoire', 'Tube à essai en verre',
     'Tube à essai en verre sodocalcique, bout rond. Référence fournisseur : FV014.'),
    ('Verrerie de laboratoire', 'Tube capillaire',
     'Tube capillaire en verre sodocalcique, diamètre intérieur 0,1 à 0,5 mm, longueurs disponibles : 100, 120, 150 et 180 mm. Référence fournisseur : FV015.'),
    ('Verrerie de laboratoire', 'Adaptateur de raccord en verre',
     'Adaptateur de raccord en verre borosilicate. Référence fournisseur : FV018.'),
    ('Verrerie de laboratoire', 'Adaptateur à queue en verre',
     'Adaptateur à queue en verre borosilicate. Référence fournisseur : FV019.'),
    ('Verrerie de laboratoire', 'Pycnomètre',
     'Pycnomètre en verre, volume 10 ou 25 ml. Référence fournisseur : FV023.'),
    ('Verrerie de laboratoire', 'Flacon GL45',
     'Flacon GL45 en verre borosilicate, diamètre de col 30 mm, capacités disponibles : 100, 250, 500 et 1000 ml. Référence fournisseur : FV027.'),
    ('Verrerie de laboratoire', 'Ampoule à décanter',
     'Ampoule à décanter en verre borosilicate, robinet PTFE, forme piriforme, capacités disponibles : 250 et 500 ml. Référence fournisseur : FV029.'),
    ('Verrerie de laboratoire', 'Entonnoir en verre, tige courte',
     'Entonnoir en verre borosilicate, tige courte, diamètres disponibles : 60, 120 et 150 mm. Référence fournisseur : FV032.'),
    ('Verrerie de laboratoire', 'Fiole jaugée',
     'Fiole jaugée en verre, bouchon PTFE, capacité 250 ml. Référence fournisseur : FV033.'),
    ('Verrerie de laboratoire', 'Ballon en verre',
     'Ballon en verre borosilicate, avec ou sans rodage, fond rond ou plat. Référence fournisseur : FV034.'),
    ('Verrerie de laboratoire', 'Boîte de Petri en verre',
     'Boîte de Petri en verre borosilicate, autoclavable. Référence fournisseur : FV037.'),
    ('Verrerie de laboratoire', 'Tube à essai à vis',
     'Tube à essai à vis en verre, dimension 90x18 mm, capacité 15 ml. Référence fournisseur : FV038.'),
    ('Verrerie de laboratoire', 'Dessiccateur',
     'Dessiccateur en verre borosilicate, plaque céramique, diamètre intérieur 120 mm. Référence fournisseur : FV042.'),
    ('Verrerie de laboratoire', 'Essencier Clevenger',
     'Essencier type Clevenger en verre borosilicate, pour huiles essentielles lourdes et légères. Référence fournisseur : FV044.'),
    ('Verrerie de laboratoire', 'Colonne chromatographique',
     'Colonne chromatographique en verre borosilicate, filtre fritté, robinet PTFE, dimension 40x400 mm. Référence fournisseur : FV045.'),
    ('Verrerie de laboratoire', 'Colonne Vigreux avec tête de distillation',
     'Colonne Vigreux avec tête de distillation, verre borosilicate, rodage 29/32, longueur 400 mm. Référence fournisseur : FV046.'),
    ('Verrerie de laboratoire', 'Kit Soxhlet',
     'Kit Soxhlet en verre borosilicate, capacités 250 ou 500 ml. Référence fournisseur : FV048.'),
    ('Verrerie de laboratoire', 'Kit de filtration',
     'Kit de filtration en verre borosilicate, capacités 250, 500, 1000 et 2000 ml. Référence fournisseur : FV050.'),
    ('Verrerie de laboratoire', 'Adaptateur thermomètre pour distillation',
     'Adaptateur pour thermomètre de distillation, verre borosilicate, rodage 29/32. Référence fournisseur : FV051.'),
    ('Verrerie de laboratoire', 'Condenseur',
     'Condenseur en verre, rodage 29/32, longueur 400 mm. Référence fournisseur : FV059.'),
    ('Verrerie de laboratoire', 'Allonge coudée avec filtre',
     'Allonge coudée avec filtre, verre borosilicate, rodage 29/32. Référence fournisseur : FV060.'),
    ('Verrerie de laboratoire', 'Vase florentin',
     'Vase florentin en verre borosilicate, capacité 250 ml. Référence fournisseur : FV065.'),
    ('Verrerie de laboratoire', 'Tube graduée avec bouchon en verre',
     'Tube graduée en verre avec bouchon en verre. Référence fournisseur : FV067.'),
    ('Verrerie de laboratoire', 'Cuve chromatographique',
     'Cuve chromatographique en verre borosilicate, simple ou double creux, forme rectangulaire, dimensions 100x100 ou 200x200 mm. Référence fournisseur : FV084.'),

    -- ------------------------------------------------------------
    -- Instruments de mesure (1 réf. FOURNITURES + catalogue TESTEURS)
    -- ------------------------------------------------------------
    ('Instruments de mesure', 'Micropipette',
     'Micropipette monocanal ou multicanaux, volume variable dès 0,1 µl. Référence fournisseur : FV006.'),
    ('Instruments de mesure', 'Alcoomètre 0-100',
     'Alcoomètre pour la mesure du titre alcoométrique, plage 0 à 100. Référence fournisseur : TS001.'),
    ('Instruments de mesure', 'Alcoomètre 3 série, 5 en 1',
     'Alcoomètre multi-fonctions, série de 3 appareils, 5 fonctions en 1. Référence fournisseur : TS002.'),
    ('Instruments de mesure', 'Bandelette test eau 16 en 1',
     'Bandelette de test pour l''eau, 16 paramètres en 1. Référence fournisseur : TS003.'),
    ('Instruments de mesure', 'Bandelette test eau 6 en 1',
     'Bandelette de test pour l''eau, 6 paramètres en 1. Référence fournisseur : TS004.'),
    ('Instruments de mesure', 'Testeur conductivité/TDS/température',
     'Appareil de mesure combiné conductivité / TDS / température. Référence fournisseur : TS005.'),
    ('Instruments de mesure', 'Dynamomètre',
     'Dynamomètre pour la mesure de force. Référence fournisseur : TS006.'),
    ('Instruments de mesure', 'Humidimètre à foin',
     'Humidimètre pour la mesure du taux d''humidité du foin. Référence fournisseur : TS007.'),
    ('Instruments de mesure', 'Humidimètre à grain',
     'Humidimètre pour la mesure du taux d''humidité des grains. Référence fournisseur : TS008.'),
    ('Instruments de mesure', 'Humidimètre sol',
     'Humidimètre pour la mesure du taux d''humidité du sol. Référence fournisseur : TS009.'),
    ('Instruments de mesure', 'Hydrodensimètre',
     'Hydrodensimètre pour la mesure de la densité des liquides. Référence fournisseur : TS010.'),
    ('Instruments de mesure', 'Lactodensimètre',
     'Lactodensimètre pour la mesure de la densité du lait. Référence fournisseur : TS011.'),
    ('Instruments de mesure', 'Mustimètre',
     'Mustimètre pour la mesure de la teneur en sucre du moût (jus de raisin). Référence fournisseur : TS012.'),
    ('Instruments de mesure', 'Papier pH en bandelette',
     'Papier pH en bandelettes, pour la mesure du pH. Référence fournisseur : TS013.'),
    ('Instruments de mesure', 'Papier pH en rouleau',
     'Papier pH en rouleau, pour la mesure du pH. Référence fournisseur : TS014.'),
    ('Instruments de mesure', 'pH-mètre 2 en 1',
     'pH-mètre portable, 2 fonctions en 1. Référence fournisseur : TS015.'),
    ('Instruments de mesure', 'pH-mètre 5 en 1',
     'pH-mètre portable, 5 fonctions en 1. Référence fournisseur : TS016.'),
    ('Instruments de mesure', 'pH-mètre portable',
     'pH-mètre portable pour la mesure du pH. Référence fournisseur : TS017.'),
    ('Instruments de mesure', 'pH-mètre sol 4 en 1',
     'pH-mètre pour sol, 4 fonctions en 1. Référence fournisseur : TS018.'),
    ('Instruments de mesure', 'Plaque CCM',
     'Plaque pour chromatographie sur couche mince (CCM). Référence fournisseur : TS019.'),
    ('Instruments de mesure', 'Réfractomètre lait',
     'Réfractomètre pour la mesure de la concentration du lait. Référence fournisseur : TS020.'),
    ('Instruments de mesure', 'Réfractomètre miel',
     'Réfractomètre pour la mesure de la teneur en eau/concentration du miel. Référence fournisseur : TS021.'),
    ('Instruments de mesure', 'Réfractomètre sucre',
     'Réfractomètre pour la mesure de la teneur en sucre (Brix). Référence fournisseur : TS022.'),
    ('Instruments de mesure', 'Réfractomètre sel',
     'Réfractomètre pour la mesure de la teneur en sel. Référence fournisseur : TS023.'),
    ('Instruments de mesure', 'Testeur TDS',
     'Testeur de TDS (solides dissous totaux). Référence fournisseur : TS024.'),
    ('Instruments de mesure', 'Thermohygromètre à sonde',
     'Thermohygromètre avec sonde, pour la mesure de la température et de l''humidité. Référence fournisseur : TS025.'),
    ('Instruments de mesure', 'Thermohygromètre',
     'Thermohygromètre pour la mesure de la température et de l''humidité. Référence fournisseur : TS026.'),
    ('Instruments de mesure', 'Thermohygromètre mural',
     'Thermohygromètre mural pour la mesure de la température et de l''humidité ambiantes. Référence fournisseur : TS027.'),
    ('Instruments de mesure', 'Thermomètre à sonde',
     'Thermomètre à sonde pour la mesure de température. Référence fournisseur : TS028.'),
    ('Instruments de mesure', 'Thermomètre aquarium',
     'Thermomètre pour aquarium. Référence fournisseur : TS029.'),
    ('Instruments de mesure', 'Thermomètre à cadran',
     'Thermomètre à cadran pour la mesure de température. Référence fournisseur : TS030.'),
    ('Instruments de mesure', 'Thermomètre en verre au mercure',
     'Thermomètre en verre au mercure pour la mesure de température. Référence fournisseur : TS031.'),
    ('Instruments de mesure', 'Thermomètre industriel infrarouge',
     'Thermomètre infrarouge à usage industriel, mesure sans contact. Référence fournisseur : TS032.'),
    ('Instruments de mesure', 'Vinomètre',
     'Vinomètre pour la mesure du titre alcoométrique du vin. Référence fournisseur : TS033.'),
    ('Instruments de mesure', 'Viscosimètre capillaire',
     'Viscosimètre capillaire pour la mesure de la viscosité des liquides. Référence fournisseur : TS034.'),
    ('Instruments de mesure', 'Viscosimètre rotatif',
     'Viscosimètre rotatif pour la mesure de la viscosité des liquides. Référence fournisseur : TS035.'),
    ('Instruments de mesure', 'Pâte à eau (jauge de réservoir)',
     'Pâte réactive pour la détection d''eau, utilisée comme jauge de réservoir. Référence fournisseur : TS036.'),
    ('Instruments de mesure', 'Pâte à produit (jauge de réservoir)',
     'Pâte réactive pour la détection de produit, utilisée comme jauge de réservoir. Référence fournisseur : TS037.'),
    ('Instruments de mesure', 'Viscosimètre à coupe pour peinture',
     'Viscosimètre à coupe pour peinture. Référence fournisseur : TS038.'),
    ('Instruments de mesure', 'Viscosimètre rotatif portable',
     'Viscosimètre rotatif portable pour la mesure de la viscosité des liquides. Référence fournisseur : TS039.'),
    ('Instruments de mesure', 'Station météorologique 3 en 1',
     'Station météorologique, 3 fonctions en 1. Référence fournisseur : TS040.'),
    ('Instruments de mesure', 'Station de mesure analogique',
     'Station de mesure analogique. Référence fournisseur : TS041.'),
    ('Instruments de mesure', 'Alcotest CTAT06',
     'Alcotest modèle CTAT06 pour la mesure du taux d''alcool. Référence fournisseur : TS042.'),
    ('Instruments de mesure', 'Alcotest ATC500',
     'Alcotest modèle ATC500 pour la mesure du taux d''alcool. Référence fournisseur : TS043.'),
    ('Instruments de mesure', 'Humidimètre grain 2SPRO',
     'Humidimètre pour grains, modèle 2SPRO. Référence fournisseur : TS044.'),
    ('Instruments de mesure', 'Testeur NPK',
     'Testeur NPK pour la mesure des teneurs en azote, phosphore et potassium du sol. Référence fournisseur : TS045.'),
    ('Instruments de mesure', 'Thermomètre infrarouge TP30',
     'Thermomètre infrarouge, modèle TP30, mesure sans contact. Référence fournisseur : TS046.'),
    ('Instruments de mesure', 'Thermomètre à sonde TP02S',
     'Thermomètre à sonde, modèle TP02S. Référence fournisseur : TS047.'),
    ('Instruments de mesure', 'Oxymètre',
     'Oxymètre pour la mesure du taux d''oxygène dissous. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Bandelette testeur eau 17 en 1',
     'Bandelette de test pour l''eau, 17 paramètres en 1. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Thermomètre mural en bois',
     'Thermomètre mural sur support en bois. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Écouvillon test bactérie',
     'Écouvillon pour test de dépistage bactériologique. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Bandelette testeur chlore',
     'Bandelette de test pour la mesure du taux de chlore. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'pH-mètre pour aliment/semi-solide',
     'pH-mètre pour aliments et produits semi-solides. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'GPS terrain',
     'GPS pour relevés de terrain. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Conductimètre sol',
     'Conductimètre pour la mesure de la conductivité du sol. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),
    ('Instruments de mesure', 'Enregistreur de température USB',
     'Enregistreur de température autonome à port USB. Référence fournisseur non confirmée (fin de catalogue, référence illisible).'),

    -- ------------------------------------------------------------
    -- Consommables de laboratoire (catalogue FOURNITURES)
    -- ------------------------------------------------------------
    ('Consommables de laboratoire', 'Pipette Pasteur en plastique',
     'Pipette Pasteur en polypropylène souple, graduation moulée, capacité 3 ml, poire intégrée. Référence fournisseur : FV002.'),
    ('Consommables de laboratoire', 'Pipette graduée en plastique',
     'Pipette graduée en polypropylène, poire de couleur fournie, capacité 5 ml, graduation 1 ml. Référence fournisseur : FV005.'),
    ('Consommables de laboratoire', 'Papier filtre',
     'Papier filtre en cellulose, vitesse moyenne, prêt à découper, diamètres disponibles : 70, 90 et 120 mm. Référence fournisseur : FV028.'),
    ('Consommables de laboratoire', 'Parafilm M',
     'Film thermoplastique translucide extensible Parafilm M, dimensions disponibles : 10x200 cm et 10x500 cm. Référence fournisseur : FV043.'),
    ('Consommables de laboratoire', 'Lamelle et lame couvre-objet',
     'Lamelle couvre-objet pour microscope (22x32 mm) et lame de verre (75x26 mm), avec ou sans dépoli, boîte de 50 ou 100 pièces. Référence fournisseur : FV053.'),
    ('Consommables de laboratoire', 'Boîte de Petri en plastique',
     'Boîte de Petri en polypropylène, dimension 90x15 mm. Référence fournisseur : FV055.'),
    ('Consommables de laboratoire', 'Microtube',
     'Microtube en polypropylène, volume 1,5 ml, bouchon plat. Référence fournisseur : FV056.'),
    ('Consommables de laboratoire', 'Tube à centrifuger',
     'Tube à centrifuger en polypropylène. Référence fournisseur : FV057.'),
    ('Consommables de laboratoire', 'Bouchon en silicone',
     'Bouchon en silicone de grade alimentaire, diamètre de trou 8 mm, différentes dimensions disponibles. Référence fournisseur : FV073.'),
    ('Consommables de laboratoire', 'Papier filtre grand format',
     'Papier filtre grand format, pour prétraitement et analyse qualitative, précipitation/séparation phase solide-liquide, purification et analyse chimique. Référence fournisseur : FV076.'),
    ('Consommables de laboratoire', 'Flacon échantillon col large',
     'Flacon échantillon col large en polypropylène, graduée, grade médicinale, capacités disponibles : 100, 250, 500, 1000 et 2000 ml. Référence fournisseur : FV077.'),
    ('Consommables de laboratoire', 'Flacon échantillon col étroit',
     'Flacon échantillon col étroit en polypropylène, graduée, grade médicinale, capacités disponibles : 100, 250, 500, 1000 et 2000 ml. Référence fournisseur : FV082.'),
    ('Consommables de laboratoire', 'Pointes de micropipette (tips)',
     'Pointes de micropipette (tips) en polypropylène, différents volumes disponibles. Référence fournisseur : FV083.'),

    -- ------------------------------------------------------------
    -- Petit matériel & outillage (catalogue FOURNITURES)
    -- ------------------------------------------------------------
    ('Petit matériel & outillage', 'Mortier en porcelaine',
     'Mortier en porcelaine avec bec verseur, diamètres disponibles : 80, 100, 130 et 160 mm. Référence fournisseur : FV016.'),
    ('Petit matériel & outillage', 'Plaque de coloration',
     'Plaque de coloration en porcelaine, 12 trous. Référence fournisseur : FV017.'),
    ('Petit matériel & outillage', 'Pissette',
     'Pissette en polypropylène, capacités disponibles : 250 et 500 ml. Référence fournisseur : FV020.'),
    ('Petit matériel & outillage', 'Tuyaux en caoutchouc',
     'Tuyaux en caoutchouc naturel, diamètre 8 mm. Référence fournisseur : FV021.'),
    ('Petit matériel & outillage', 'Bec Bunsen pour chauffe au gaz',
     'Bec Bunsen pour chauffe au gaz en laboratoire. Référence fournisseur : FV022.'),
    ('Petit matériel & outillage', 'Poire à pipetter',
     'Poire à pipetter en caoutchouc, trois valves. Référence fournisseur : FV025.'),
    ('Petit matériel & outillage', 'Pipetteur',
     'Pipetteur en polypropylène : rouge 25 ml, vert 10 ml, bleu 2 ml. Référence fournisseur : FV026.'),
    ('Petit matériel & outillage', 'Modèle moléculaire',
     'Modèle moléculaire 155 pièces, diamètre 23 mm pour C/O/N/S/Cl/P, diamètre 17 mm pour H. Référence fournisseur : FV030.'),
    ('Petit matériel & outillage', 'Spatule en inox 20-22 cm',
     'Spatule en acier inoxydable, longueur 20 à 22 cm. Référence fournisseur : FV031.'),
    ('Petit matériel & outillage', 'Statif',
     'Statif en métal, longueur de tige 600 ou 1000 mm, base 210x150 mm, diamètre de tige 10 mm. Référence fournisseur : FV035.'),
    ('Petit matériel & outillage', 'Élévateur de laboratoire',
     'Élévateur de laboratoire, plateau aluminium 10x10, 15x15 ou 20x20 cm, élévation 16 cm. Référence fournisseur : FV036.'),
    ('Petit matériel & outillage', 'Bécher en polypropylène',
     'Bécher en polypropylène, graduation moulée, bec verseur, forme basse. Référence fournisseur : FV039.'),
    ('Petit matériel & outillage', 'Éprouvette graduée en polypropylène',
     'Éprouvette graduée en polypropylène, graduation bleue classe A, pied hexagonal, capacités disponibles : 25, 100, 250, 500 et 1000 ml. Référence fournisseur : FV040.'),
    ('Petit matériel & outillage', 'Tamis',
     'Tamis en acier inoxydable SS304, différentes porosités, diamètre 200 mm. Référence fournisseur : FV041.'),
    ('Petit matériel & outillage', 'Barreau magnétique',
     'Barreau magnétique avec anneau, dimensions disponibles : 4x8, 6x15, 6x20, 8x30 et 8x40 mm. Référence fournisseur : FV047.'),
    ('Petit matériel & outillage', 'Pince de fixation',
     'Pince de fixation en acier inoxydable SS304, trois doigts. Référence fournisseur : FV049.'),
    ('Petit matériel & outillage', 'Pince de rodage clip',
     'Pince de rodage clip en plastique, couleur rouge, raccord 29/32. Référence fournisseur : FV052.'),
    ('Petit matériel & outillage', 'Barboteur',
     'Barboteur pour fermentation (alcool, bière, vin), en polypropylène, capuchon rouge, fixation par vis en caoutchouc noir. Référence fournisseur : FV054.'),
    ('Petit matériel & outillage', 'Pulvérisateur sur erlenmeyer',
     'Pulvérisateur sur erlenmeyer 50 ml. Référence fournisseur : FV058.'),
    ('Petit matériel & outillage', 'Support de fixation pour colonne',
     'Support de fixation pour colonne, statif de 600 mm de hauteur, pince trois doigts universelle, pied en acier. Référence fournisseur : FV061.'),
    ('Petit matériel & outillage', 'Poire à pipette Pasteur',
     'Poire à pipette Pasteur en caoutchouc, capacité maximale 3 ml. Référence fournisseur : FV062.'),
    ('Petit matériel & outillage', 'Fixation pour ampoule à décanter',
     'Fixation pour ampoule à décanter, statif de 600 mm de hauteur, anneaux avec pince intégrée, pied en acier. Référence fournisseur : FV063.'),
    ('Petit matériel & outillage', 'Fixation pour burette',
     'Fixation pour burette, statif de 600 mm de hauteur, pince trois doigts, pied en acier. Référence fournisseur : FV064.'),
    ('Petit matériel & outillage', 'Verre à pied en polypropylène',
     'Verre à pied en polypropylène, capacité 100 ml. Référence fournisseur : FV066.'),
    ('Petit matériel & outillage', 'Bécher en polypropylène avec poignée',
     'Bécher en polypropylène avec poignée et bec verseur, graduation bleue. Référence fournisseur : FV069.'),
    ('Petit matériel & outillage', 'Valet (pose-ballon)',
     'Valet (pose-ballon) en polypropylène. Référence fournisseur : FV070.'),
    ('Petit matériel & outillage', 'Spatule en inox, différentes tailles',
     'Spatule en acier inoxydable, différentes tailles disponibles. Référence fournisseur : FV071.'),
    ('Petit matériel & outillage', 'Pince à creuset avec tube en caoutchouc',
     'Pince à creuset avec tube en caoutchouc, pour tenir le creuset chauffant ou retirer le creuset et son couvercle de la source de chaleur, dimension 250 mm. Référence fournisseur : FV074.'),
    ('Petit matériel & outillage', 'Creuset en porcelaine',
     'Creuset en porcelaine, différentes dimensions disponibles, avec couvercle. Référence fournisseur : FV075.'),
    ('Petit matériel & outillage', 'Fiole jaugée en polypropylène',
     'Fiole jaugée en polypropylène, bouchon à vis ou à pression, autoclavable, température maximale 180°C. Référence fournisseur : FV078.'),
    ('Petit matériel & outillage', 'Entonnoir en PTFE',
     'Entonnoir en polypropylène avec bouchon à pression, revêtement téflon, résistant aux produits chimiques. Référence fournisseur : FV079.'),

    -- ------------------------------------------------------------
    -- Mobilier & rangement de laboratoire (catalogue FOURNITURES)
    -- ------------------------------------------------------------
    ('Mobilier & rangement de laboratoire', 'Portoir en bois',
     'Portoir en bois, longueur 220 mm, largeur 62 mm, hauteur 130 mm, diamètre des trous 22 mm. Référence fournisseur : FV024.'),
    ('Mobilier & rangement de laboratoire', 'Portoir en plastique',
     'Portoir en plastique pour tubes et petit matériel de laboratoire. Référence fournisseur : FV068.'),
    ('Mobilier & rangement de laboratoire', 'Rack à pipettes',
     'Rack à pipettes en polypropylène, forme trapèze, support pour 12 pipettes. Référence fournisseur : FV080.'),

    -- ------------------------------------------------------------
    -- Stérilisation & nettoyage (catalogue FOURNITURES)
    -- ------------------------------------------------------------
    ('Stérilisation & nettoyage', 'Goupillon',
     'Goupillon avec soies naturelles et fil de fer galvanisé torsadé, pour le nettoyage de la verrerie. Référence fournisseur : FV072.'),
    ('Stérilisation & nettoyage', 'Égouttoir',
     'Égouttoir en acier avec peinture, pointes recouvertes de PVC, pour le séchage de la verrerie. Référence fournisseur : FV081.')

) as v(category, name, description)
where bu.slug = 'akora-lab'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- Garde-fou : prévenir si le pilier Akora Lab n'a pas été trouvé
-- (ne devrait jamais arriver, créé par phase254).
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-lab'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-lab'' trouvé — rien inséré.';
  end if;
end $$;

-- Vérification :
-- select p.category, p.name, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'akora-lab'
-- order by p.category, p.name;
