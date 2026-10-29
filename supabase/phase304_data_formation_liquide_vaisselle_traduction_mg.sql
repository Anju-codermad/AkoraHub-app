-- ============================================================
-- AkoraHub - Phase 304 : traduction malgache des 9 modules de la
-- formation "Liquide Vaisselle" (version professionnelle)
--
-- Demande explicite (29/10) : traduction manuelle (gratuite) plutôt
-- qu'une intégration d'API de traduction payante. IMPORTANT : comme
-- pour la première formation malgache, cette traduction a été
-- rédigée du mieux possible mais n'a pas été relue par une personne
-- malgache native — à vérifier/corriger par la propriétaire dans
-- l'app (barre d'outils de texte enrichi) avant de considérer le
-- contenu malgache comme définitif. Les mentions légales déjà en
-- malgache dans le document BNM (Module 6) ont été reprises telles
-- quelles, sans retraduction.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set title_mg = 'Ce que vous allez apprendre' -- titre déjà clair, inchangé
where title = 'Ce que vous allez apprendre'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$Ity fiofanana ity dia manoro dingana anao hanamboatra ranon-tsavony fanasana vilia amin'ny fomba matihanina, manomboka amin'ny simia fototra ka hatramin'ny varotra :

1. Simian'ny tensioactif — hahatakatra ny akora miasa (SLES, LABSA, CAPB) sy hikajy ny fatrany ampiasaina
2. Akora fototra & Fividianana — hifantina sy hividy ny akora amin'ny vidiny tsara indrindra
3. Fitambarana arakaraka ny sokajy — hamokatra vokatra amin'ny kalitao maro (mora, antonony, ambony)
4. Fomba fanaovana — hikarakara ny toeram-piasana ary hamokatra tsy tapaka, isaky ny lot
5. Fanaraha-maso ny kalitao ISO — hijery raha mifanaraka amin'ny fitsipika ny lot tsirairay
6. Fitsipika Malagasy & BNM — hanaja ny lalàna ofisialy eto Madagasikara
7. Fiarovana, FDS & Lalàna — hikarakara ny akora amim-piarovana tsara
8. Varotra & Ara-bola — hikajy ny vidiny sy hivarotra amim-tombony marina

Rehefa vita ity fiofanana ity, dia ho fantatrao ny famokarana, fanaraha-maso ary fivarotana ny ranon-tsavony fanasana vilia nataonao manokana, hatrany am-piandohana ka hatramin'ny farany.$$
where title = 'Ce que vous allez apprendre'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Inona ny tensioactif ?

Ny tensioactif (na akora mikasika ny velaran-javatra) dia molekiola misy roa sombiny :
- loha tia rano (voasarika amin'ny rano)
- rambony tia menaka (voasarika amin'ny menaka)

Io toetra roa sosona io no mahatonga ny tensioactif afaka "manala" ny loto misy menaka amin'ny velaran-javatra iray sy hampiely azy amin'ny ranon'ny fanasana — izany no fototry ny vokatra rehetra mahatonga vovoka (ranon-tsavony fanasana vilia, shampôgaina, savony lamba).

2. Ireo sokajy lehibe amin'ny tensioactif

- Anionika (herinaratra negatifa) : izy ireo no mahatonga vovoka sy manadio indrindra — anisan'izany ny SLES sy ny LABSA. Izy ireo no fototry ny ankamaroan'ny fitambarana.
- Amfoterika (herinaratra miova) : anisan'izany ny CAPB — malefaka kokoa, ampiasaina ho fanampiny mba hampitoetra sy hampalefaka ny vovoka.
- Tsy ionika sy kationika : tsy dia ampiasaina firy amin'ireo fitambarana ankehitriny (kationika indrindra ho an'ny fampalefahana lamba).

3. SLES (Sodium Laureth Sulfate)

Tensioactif anionika, fototry ny vovoka indrindra amin'ny ranon-tsavony fanasana vilia sy ny shampôgaina. Vovoka be sady malefaka, saingy mety mahatonga fanairana raha irery amin'ny fatra ambony — izany no antony tokony hampiarahana azy amin'ny tensioactif fanampiny malefaka kokoa (CAPB).

4. LABSA (Acide Dodécylbenzène Sulfonique Linéaire)

Tensioactif anionika hafa, matanjaka sy mora vidy — fototry ny detergent vovoka sy savony lamba ranoka maro. Zava-dehibe ny "L" (Linéaire/Mitsivalana) : ny LABSA misy rojo mitsivalana dia azo simban'ny biolojika, fa tsy toy ny karazana taloha sampana, izay raràna amin'ny ankamaroan'ny fitsipika momba ny tontolo iainana ankehitriny. Jereo foana raha tena mitsivalana (LAS) ny LABSA vidinao.

5. CAPB (Cocamidopropyl Bétaïne)

Tensioactif amfoterika malefaka, ampiasaina ho fanampin'ny SLES na ny LABSA. Mampitoetra sy mampitevina ny vovoka, ary mampihena ny fanairana ateraky ny tensioactif fototra eo amin'ny hoditra — izany no mahatonga azy ampiana na dia amin'ny fatra kely aza (matetika 2 ka hatramin'ny 5%) ao amin'ny fitambarana.

6. Fikajiana ny akora miasa (MA%)

Ny tensioactif vidina dia tsy madio 100% mihitsy — amidy amin'ny fatra fahavoazana voafaritra izy ireo (oh. "SLES 70%" midika hoe 70% akora miasa, 30% rano/solvant). Mba hahafantarana ny habetsaky ny vokatra tsy voakitika ampiasaina mba hahatratrarana ny isan-jaton'ny akora miasa tadiavina ao amin'ny fitambarana farany :

Habetsaky ny vokatra tsy voakitika = (% MA tadiavina × lanjan'ny fitambarana manontolo) / % ny fahavoazan'ny vokatra tsy voakitika

Ohatra : mitady 8% MA amin'ny SLES ao amin'ny fitambarana 5 litatra (5000 g), miaraka amin'ny SLES 70% :
Habetsaky ny SLES 70% = (8% × 5000 g) / 70% = 400 / 0,70 = 571 g

(Raha SLES madio 100% no ampiasaina, dia 400 g ihany no ilaina — izany no mahazava-dehibe ny fanamarinana foana ny fahavoazana voasoratra amin'ny etiketan'ny mpamatsy alohan'ny hikajiana fitambarana.)

7. Ny lazain'ny fitsipika Malagasy (BNM, NMG 401-1/2004)

Ny ranon-tsavony fanasana vilia dia tafiditra ao amin'ny sokajy "Vokatra fanadiovana amin'ny fampiasana maro" amin'ity fitsipika ity (jereo ny Module 6). Ho an'ity sokajy ity, ny tahan'ny tensioactif takina dia 10% farafahakeliny ka hatramin'ny 20% farafahabetsany.

Ny fijanonana ao anatin'ity elanelana ity dia tsy resaka fanarahan-dalàna fotsiny — ny vokatra latsaky ny faran'ambany dia manadio tsy tsara, ary ny vokatra mihoatra ny faran'ambony dia mandany akora foana tsy misy tombony marina amin'ny fahombiazana. (Ny antsipirian'ny fitsipika manontolo — azo simban'ny biolojika, pH, marika takiana — dia resahina amin'ny Module 6.)$$
where title = 'Chimie des tensioactifs'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Antontan-taratasy telo tokony hangatahina amin'ny mpamatsy foana

- TDS (Technical Data Sheet / Taratasy ara-teknika) : mamaritra ny vokatra araka ny amidy azy — fahavoazana, endrika, pH, hakitroky, fepetra fitehirizana. Izy no fototra ampiasaina hikajiana ny fitambaranao (jereo Module 1, fikajiana ny akora miasa).
- FDS (Fiche de Données de Sécurité) : taratasy takiana ho an'ny vokatra simika rehetra — loza mety hitranga, fitandremana amin'ny fikarakarana, fitehirizana, fanampiana voalohany raha misy loza. Tehirizo ary aseho raha misy fanamarinana (jereo koa Module 7 — Fiarovana, FDS & Lalàna).
- CoA (Certificate of Analysis / Taratasy fanamarinana) : manokana ho an'ny LOT tsirairay tonga — manamarina fa io lot manokana io dia mifanaraka tokoa amin'ny sanda voalaza ao amin'ny TDS (oh. "SLES 70%" nojerena tokoa ho 69,8% amin'io lot io). Ny mpamatsy azo itokisana dia manome CoA isaky ny lot, tsy TDS ankapobe fotsiny.

Ny mpamatsy izay tsy afaka manome na iray amin'ireto antontan-taratasy telo ireto dia famantarana fa tsy azo itokisana loatra ny vokany.

2. Akora eto an-toerana sa avy any ivelany ?

- Eto an-toerana : fotoam-pandefasana fohy kokoa, tsy misy sara fadin-tseranana, tsy misy risika hisakanana amin'ny fanafarana, saingy voafetra kokoa ny safidy (tsy ny tensioactif rehetra no vokarina eto an-toerana) ary mety hiovaova kokoa ny vidiny arakaraka ny tahiry misy.
- Avy any ivelany : safidy midadasika kokoa ary matetika mifanaraka tsara kokoa amin'ny vidiny raha vidiana be, saingy fotoam-pandefasana lavalava kokoa, sara fadin-tseranana sy fitaterana tokony hampidirina ao anatin'ny vidiny tena izy, ary risika hisian'ny fahatapahana raha misy fandefasana tara.

Amin'ny fampiharana : aleo omena lanja ny eto an-toerana ho an'ny akora fototra ampiasaina tsy tapaka (hisorohana ny fahatapahan-tahiry), ary ny fanafarana kosa atokana ho an'ny fividianana an-tsokajy/voakasa mialoha ho an'ny habetsaka lehibe kokoa.

3. Mampitaha ny vidiny tena izy eo amin'ny mpamatsy roa — fandrika tokony halavirina

Aza mampitaha vokatra roa araka ny vidiny isaky ny kg fotsiny : ilaina ny mampitaha ny vidiny isaky ny ampahany akora miasa, raha tsy izany ny vokatra "mora kokoa" isaky ny kg dia mety lafo kokoa raha diravina hatramin'ny fahavoazana mahasoa mitovy.

Fomba :
Vidiny tena izy isaky ny kg akora miasa = Vidim-pividianana isaky ny kg ÷ % ny fahavoazan'ny vokatra

Ohatra :
- Mpamatsy A : SLES 70% amin'ny 8 000 Ar/kg → vidiny tena izy = 8 000 / 0,70 = 11 430 Ar isaky ny kg akora miasa
- Mpamatsy B : SLES 60% amin'ny 7 200 Ar/kg → vidiny tena izy = 7 200 / 0,60 = 12 000 Ar isaky ny kg akora miasa

Ny Mpamatsy A no mora kokoa raha ny marina, na dia ambony kokoa aza ny vidiny aseho isaky ny kg. Ataovy foana io fikajiana io alohan'ny hisafidianana mpamatsy araka ny vidiny aseho fotsiny.$$
where title = 'Matières premières & Sourcing'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Nahoana no manao sokajy maro ?

Ny antontan-taratasin'ny BNM (NMG 401-1/2004) dia efa manavaka ara-panjakana sokajy maromaro ho an'ny savony fikarakarana trano, arakaraka ny tahan'ny menaka ao aminy. Ampiharina amin'ny ranon-tsavony fanasana vilia ny foto-kevitra mitovy : ny fanolorana haavo maro amin'ny kalitao/vidiny dia ahafahana mahazo mpanjifa samihafa (vidiny mora vs kalitao ambony) miaraka amin'ny fitambarana fototra mitovy, fotsiny amin'ny fanovana ny % akora miasa (MA, jereo Module 1).

- Sokajy Mora (MA ~6-8%) : vovoka ampy, fanalam-menaka antonony, vidim-pamokarana ambany indrindra — ho an'ny varotra be dia be na fonosana lehibe.
- Sokajy Antonony (MA ~10-12%) : ny fifandanjana tsara amin'ny vovoka/fanalam-menaka/vidiny — izy no fitambarana "ho an'ny rehetra" (akaikin'ny fitambarana fototra efa ampiasaina).
- Sokajy Ambony/Mifantoka (MA ~14-16%) : mifantoka be, manala menaka haingana kokoa, tavoahangy kely kokoa ho an'ny isan'ny fampiasana mitovy — laharana ambony.

Fahatsiarovana : mijanòna foana ao anatin'ny elanelana BNM ho an'ny vokatra fanadiovana (10% ka hatramin'ny 20% tensioactif, jereo Module 1 §7).

2. Dimy fitambarana vonona ampiasaina (ho an'ny 5 litatra)

Fitambarana 1 — Mora (MA ~6%) :
SLES 70% : 430 g · CAPB 45% : 100 g · Comperlan 85% : 30 g · Sira : 50-80 g · Acide citrique : araka ny ilaina pH 6-7 · Loko + Manitra : araka ny ilaina · Fitahirizana : araka ny dose omen'ny mpamatsy

Fitambarana 2 — Antonony (MA ~8%, ny fitambarana fototra efa ampiasaina) :
SLES 70% : 400 g · CAPB 45% : 150 g · Comperlan 85% : 50 g · Sira : 50-100 g · Acide citrique : araka ny ilaina pH 6-7 · Loko + Manitra : araka ny ilaina · Fitahirizana : araka ny dose omen'ny mpamatsy

Fitambarana 3 — Antonony manala menaka mafy kokoa (MA ~10%) :
SLES 70% : 550 g · CAPB 45% : 180 g · Comperlan 85% : 60 g · Sira : 60-100 g · Acide citrique : araka ny ilaina pH 6-7 · Loko + Manitra : araka ny ilaina · Fitahirizana : araka ny dose omen'ny mpamatsy

Fitambarana 4 — Ambony mifantoka (MA ~14%) :
SLES 70% : 750 g · CAPB 45% : 250 g · Comperlan 85% : 80 g · Sira : 80-120 g (matetika tsy dia ilaina firy, efa matevina kokoa ny vokatra) · Acide citrique : araka ny ilaina pH 6-7 · Loko + Manitra : araka ny ilaina (ampitomboina kely) · Fitahirizana : araka ny dose omen'ny mpamatsy

Fitambarana 5 — Tsy misy manitra / hoditra marefo (MA ~8%, miorina amin'ny Fitambarana 2 tsy misy manitra) :
Mitovy amin'ny Fitambarana 2, tsy misy loko na manitra — CAPB ampitomboina kely (180 g) hanonitra ny halefahana mahazatra avy amin'ny manitra.

(araka ny ilaina = habetsaka ampy, ajanony/refeso araka ny efa hita tao amin'ny fitambarana fototra voalohany.)

3. Mamboatra ny hakitroky sy ny pH

- Hakitroky : ajanona amin'ny sira (NaCl), toy ny hita tao amin'ny fitambarana fototra — ampio tsikelikely raha mitsapa isaky izay (ny sotro iray alatsaka dia tokony hikoriana amin'ny fomba tsy tapaka, tsy rano loatra na mafy loatra). Ny fitambarana mifantoka kokoa (Ambony) dia mila sira kely kokoa.
- pH : tanjona 6 ka hatramin'ny 7 (refesina amin'ny taratasy pH na mpamantatra pH). Ambanin'ny 6, mafaitra loatra ny vokatra (mety mahatonga fanairana) ; ambonin'ny 7, mihena ny herin'ny vovoka/fanalam-menaka. Ajanony amin'ny acide citrique aroboka, dropa isan-dropa, mamerina mandrefy isaky ny fanampiana.

4. Mpikajy — manova habetsaky ny fitambarana

Ireo fitambarana rehetra ireo dia nomena ho an'ny 5 litatra. Mba hamokarana habetsaka hafa, hombin'ny isa mitovy ny akora TSIRAIRAY :

Isa fampitomboana = Habetsaka tadiavina (L) / 5

Ohatra : mamokatra 20 litatra amin'ny Fitambarana 2 (Antonony) → Isa fampitomboana = 20 / 5 = 4
- SLES 70% : 400 g × 4 = 1 600 g
- CAPB 45% : 150 g × 4 = 600 g
- Comperlan 85% : 50 g × 4 = 200 g
- Sira : 50-100 g × 4 = 200-400 g (ajanony tsikelikely foana, na dia amin'ny habetsaka lehibe aza)

Ny sira, ny loko, ny manitra ary ny acide citrique dia mijanona foana "ajanona raha mitsapa" na dia amin'ny habetsaka lehibe aza — ny tensioactif ihany (SLES/CAPB/Comperlan) no azo kajiana mialoha amim-pahatokiana.$$
where title = 'Formulation par gamme'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Mikarakara ny toeram-piasana ho faritra 5

Na dia amin'ny toerana kely aza, ny fanasarahana ara-batana (na farafahakeliny ara-potoana) ireto dingana 5 ireto dia misoroka ny fahadisoana ary manamaivana ny famokarana :

1. Fandraisana & fitehirizana ny akora fototra — bidao mihidy, misy marika, voaaro amin'ny hafanana/ny masoandro (jereo Module 1 §7 sy ny fitambarana fototra).
2. Fandanjana & fandrefesana — toerana iray ihany misy ny mizana, izay andanjana ny akora tsirairay alohan'ny hampidirana azy. Tsy misy "amin'ny maso" mihitsy.
3. Fangarahana & famokarana — ny toerana misy ny sini-pangaro, izay anaovana ny filaharan'ny fanampiana (jereo §2 ambany).
4. Fanaraha-maso ny kalitao — toerana mitokana misy ny taratasy pH sy ny fitaovana hamantarana ny hakitroky, lavitry ny fangarahana mandeha mba hisorohana ny fandotoana.
5. Fonosana & fitehirizana ny vokatra vita — famenoana tavoahangy, fametahana marika, fitehirizana ny vokatra vita mitokana amin'ny akora fototra tsy voakitika (mba tsy hifangaroana ny bidao akora sy ny bidao vokatra vita).

2. Ny filaharan'ny fanampiana ny akora — ary ny antony mahazava-dehibe izany

Ny filaharana omena ao amin'ny fitambarana fototra dia tsy kisendrasendra :
1. Rano aloha (fototra/solvant)
2. SLES, amin'ny fangarahana malefaka — ny fangarahana mafy loatra amin'ity dingana ity dia mamorona vovoka be loatra izay manelingelina ny dingana manaraka
3. CAPB, dia Comperlan — ampiana aorian'ny SLES mba hiparitaka tsara ao amin'ny fototra efa diraina
4. Sira, tsikelikely — mampitevina ; raha ampiana haingana loatra (alohan'ny tena hahalevonan'ny tensioactif), tsy mitovy ny vokatra
5. Mpanitsy pH (acide citrique), loko, manitra, fitahirizana — farany foana, rehefa mitoetra ny votoatiny, mba tsy hanova ny fatra alohan'ny hahavitan'ny fangarahana

Ny fanajana io filaharana io dia misoroka olana telo matetika mitranga : vovoka tsy voafehy mandritra ny famokarana, vokatra maloto na misy voantsinapaka (sira tsy levona tsara), ary manitra/loko tsy mifangaro tsara ao amin'ny fitambarana.

3. Ny taratasin'ny lot — nahoana no tokony hofenoina isaky ny famokarana

Ny taratasin'ny lot dia antontan-taratasy tsotra fenoina isaky ny famokarana TSIRAIRAY, izay misoratra :
- Laharan'ny lot sy ny daty famokarana
- Ny habetsaka marina nolanjaina amin'ny akora tsirairay (tsy ny habetsaka ara-teoria ao amin'ny fitambarana — fa ny habetsaka naidina tokoa)
- Iza no namokatra ny lot
- Ny valin'ny fanaraha-maso ny kalitao : pH refesina, hakitroky noheverina ho marina na tsia
- Ora nanombohana sy nahavitan'ny famokarana

Ny ilàny azy marina :
- Fahafahana mizaha ny lalana raha misy fitarainan'ny mpanjifa (mahafantatra marina hoe lot inona no namidy, miaraka amin'ny akora inona)
- Fahafahana mamerina : mamerina manao lot tsara indrindra, na mamantatra izay niova tamin'ny lot nisy olana
- Antontan-taratasy aseho raha misy fanamarinana (jereo Module 7 — Fiarovana, FDS & Lalàna)

Na dia kahie tsotra misy ireo fampahalalana ireo, lot isaky ny lot, aza, dia ampy hanombohana.

4. Mikasa ny haben'ny lot (batch calc)

Ampiasao ny mpikajy fampitomboana ao amin'ny Module 3 mba hampifanaraka ny haben'ny lot amin'ny filàna marina :
- Lot kely loatra raha oharina amin'ny commande → fahatapahana matetika, famokarana averina matetika loatra
- Lot lehibe loatra raha oharina amin'ny filàna → tahiry tsy mihetsika, risika hahatonga ny vokatra vita ho antitra alohan'ny hivarotana azy

Fomba tsotra : ampio ny commande miandry + sombiny tahiry fiarovana (ohatra, mitovy amin'ny varotra iray herinandro mahazatra), avy eo ampiasao ny isa fampitomboana (Module 3 §4) mba hikajiana ny habetsaky ny akora amin'ny lot hovokarina.$$
where title = 'Processus de fabrication'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. ISO 9001 — fomba fiasa, tsy taratasy fotsiny

ISO 9001 dia ny fitsipika iraisam-pirenena momba ny fitantanana ny kalitao — tsy mamaritra ny fomba hamokarana vokatra manokana izy, fa ny fomba handaminana ny asa mba ho tsy miova ny kalitao : fomba fiasa voasoratra, fanamarinana tsy tapaka, fahafahana mizaha ny lalana (jereo ny taratasin'ny lot ao amin'ny Module 4), ary fanatsarana tsy an-kijanona miainga amin'ny olana sendra.

Tsy voatery ho an'ny varotra eto an-toerana izy, saingy ny fakana tahaka azy sahady (na tsy manana ny fahazoan-dalana ofisialy, izay misy vidiny) dia mamboatra ny lalana raha mikasa mpanjifa matihanina (B2B) na fanondranana any ivelany ianao indray andro any, izay matetika takiana.

2. Ny fitsipika tena izy ho an'ny fitsapana savony sy detergent

Ny antontan-taratasy ofisialin'ny BNM (NMG 401-1/2004) nomenao dia milaza mazava ny fitsipika ISO ampiasaina hanaraha-maso ny savony/detergent eto Madagasikara :

- ISO 456 : fandrefesana ny chlorure
- ISO 457 : fandrefesana ny menaka rehetra
- ISO 672 : fomba fakana santionany (ny fomba hakana santionany mendrika ny lot)
- ISO 8212 : famaritana ny alcalinité malalaka na ny acidité malalaka
- ISO 4318 : famaritana ny akora tsy mety levona amin'ny alcool

Ireo fitsipika ireo, fa tsy ireo antsipirihany tsy voamarina, no fototra ampiasaina amin'ny fanaraha-maso ofisialy — izany no antony nakana azy ireo eto, fa tsy isa hafa mivezivezy indraindray tsy misy loharano azo itokisana.

3. Manamarina ny fifanarahan'ny lot

Isaky ny famokarana, alohan'ny hametrahana lot amin'ny varotra, jereo :
- pH (tanjona 6-7, jereo Module 3 §3)
- Hakitroky (votoatiny marina, jereo Module 3 §3)
- Tahan'ny tensioactif tena ampiasaina, amin'ny fikajiana (jereo Module 1 §6) — na amin'ny fitsapana laboratoara nekena raha mikasa fahazoan-dalana ofisialy any aoriana ianao
- Fijery maso : loko tovana, tsy misy sisa na fisarahana ao anaty bidao

Ity rehetra ity dia soratana mivantana ao amin'ny taratasin'ny lot (Module 4 §3) : izy no manaporofo, lot isaky ny lot, fa manaja ny fepetra farany ambany ao amin'ny fitsipika BNM ny vokatrao (fahatsiarovana Module 1 §7 : 10% ka hatramin'ny 20% tensioactif ho an'ny vokatra fanadiovana).

4. Inona no atao raha tsy mifanaraka ny lot iray

- Aza mivarotra lot tsy araka ny fitsipika mihitsy, na dia "angamba tsy misy loza" aza — aleo very io lot io toy izay very ny fahatokisan'ny mpanjifa na mahatratra fanamarinana.
- Raha azo refesina sy azo avadika ny olana (oh. mifantoka loatra → diravina kely amin'ny rano, amin'ny fikajiana indray ny % MA vaovao), hitsio dia tsapao indray alohan'ny hanamarinana ny lot.
- Raha tsy azo avadika ny olana (pH lavitra ny tanjona, fisarahana hita maso), aza foniana io lot io — soraty ny antony azo inoana ao amin'ny taratasin'ny lot mba hisorohana ny famerenana ny fahadisoana mitovy.$$
where title = 'Contrôle qualité ISO'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$Ity module ity dia miorina mivantana amin'ny fitsipika ofisialin'ny NMG 401-1/2004 an'ny Bureau des Normes de Madagascar (BNM), "Savons et Détergents".

1. Izay rakotry ity fitsipika ity

Mametra ny fepetra ho an'ny savony fikarakarana trano, savony fidiovana, vokatra fanadiovana, detergent ary ranon-javela amidy eto Madagasikara izy. TSY mihatra amin'ny shampôgaina, savony fanafody ary fanafody izy.

Ny ranon-tsavony fanasana vilia dia tafiditra ao amin'ny sokajy "Vokatra fanadiovana amin'ny fampiasana maro" amin'ity fitsipika ity (sokajy akaiky indrindra — tokony hamarinina mivantana amin'ny BNM raha mikasa fahazoan-dalana ofisialy ianao).

2. Fepetra takiana ho an'ny vokatra fanadiovana amin'ny fampiasana maro

Araka ny tabilao ofisialin'ny fitsipika (§4) :
- Tensioactif : 10% farafahakeliny, 20% farafahabetsany
- Azo simban'ny biolojika : 80% farafahakeliny
- pH amin'ny solution 1% amin'ny 23°C : 8 farafahabetsany

Fahatsiarovana ankapobe (§4, sokajy rehetra) : ny vokatra dia tsy maintsy tsy radioaktifa, azo simban'ny biolojika 80% farafahakeliny, misy rojo mitsivalana (jereo Module 1 §4 momba ny LABSA mitsivalana), ary tsy mahatonga fanairana eo amin'ny hoditra.

3. Marika takiana amin'ny etiketa

Araka ny fitsipika (§5.3, sokajy detergent ranoka — akaiky indrindra amin'ny ranon-tsavony fanasana vilia), ny etiketanao dia tsy maintsy misy :
- Ny lanja na ny habetsaka net araka ny rafitra metrika iraisam-pirenena
- Ny mari-pamokarana
- Ny famaritana ny vokatra : "RANON-TSAVONY"
- Ny daty famokarana
- Ny firenena niandohany
- Ny votoatiny : tahan'ny phosphate, tahan'ny tensioactif, tahan'ny fahaazoana simban'ny biolojika
- Ny fomba fampiasana farafahakeliny amin'ny teny Malagasy, misy ny marik'ny fatra
- Ny kaody baridiany (atolotra)
- Ny marika takiana : « TSY AZO SOTROINA », amin'ny endri-tsoratra mazava sy hita

Ny soratra dia tsy maintsy misy koa, amin'ny teny Malagasy, amin'ny endri-tsoratra mazava sy hita, ity fehezanteny momba ny fiarovana ity :
« AMPIRIMO TSARA MBA TSY HO LALAOVIN'NY ANKIZY. RAHA SENDRA VOA NY MASO DIA SASAO AVY HATRANY AMIN'NY RANO BE. RAHA SENDRA VOATELINA DIA MANATONA HAINGANA MPITSABO »

4. Endrika fonosana ekena (amin'ny millilitatra)

Ny fitsipika dia mametra dingana mazava ho an'ny detergent ranoka — ny endrika rehetra amidy dia tsy maintsy manaraka ireto fitomboana ireto :
- 25 ka hatramin'ny 150 ml : ny fitomboana rehetra amin'ny 25
- 150 ka hatramin'ny 750 ml : ny fitomboana rehetra amin'ny 50
- 750 ka hatramin'ny 2 500 ml : ny fitomboana rehetra amin'ny 250
- 2 500 ka hatramin'ny 5 000 ml : ny fitomboana rehetra amin'ny 500
- 5 000 ka hatramin'ny 10 000 ml : ny fitomboana rehetra amin'ny 1 000

Ny bidao 5 litatra (5 000 ml) toy ny ao amin'ny fitambarana fototra dia efa manaraka ireo dingana ireo. Ho an'ny habe hafa (oh. tavoahangy kely), jereo foana raha mifanaraka amin'ny iray amin'ireo fitomboana ekena ireo ny habetsaka nosafidianina alohan'ny hanomezana ny fonosana.

5. Izay mbola tokony hamarininao manokana

Ity module ity dia maka indray ny fepetra voasoratra ao amin'ny fitsipika NMG 401-1/2004. Ho an'ny fahazoan-dalana ofisialy (raha mikasa izany ianao), antsoy mivantana ny BNM (B.P : 1316 Soarano, Antananarivo — bnm@bnm.mg) mba hahafantarana ny fomba fangatahana, ny vidiny ary ny fe-potoana ankehitriny — ireo fampahalalana azo ampiharina ireo dia tsy voarakitra ao amin'ny antontan-taratasy ara-teknika nomena ary tokony hamarinina mivantana aminy ireo.$$
where title = 'Norme Malagasy & BNM'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Ny FDS (Fiche de Données de Sécurité) — lohateny 16 mitovy anarana

Efa noresahina tao amin'ny Module 2, ny FDS dia manaraka endrika iraisam-pirenena mitovy anarana amin'ny lohateny 16 (rafitra GHS, ampiasaina eran-tany amin'ny mpamatsy vokatra simika) :

1. Famantarana ny vokatra sy ny orinasa
2. Famantarana ny loza mety hitranga
3. Votoatiny / fampahalalana momba ny singa
4. Fanampiana voalohany
5. Fepetra hiadiana amin'ny afo
6. Fepetra raisina raha misy fielezana tsy nahy
7. Fikarakarana sy fitehirizana
8. Fanaraha-maso ny fiatrehana / fiarovana manokana
9. Toetra ara-batana sy ara-simika
10. Fitoerana sy ny fihetsiky ny singa
11. Fampahalalana ara-poizina
12. Fampahalalana momba ny tontolo iainana
13. Fiheverana momba ny fanafoanana
14. Fampahalalana momba ny fitaterana
15. Fampahalalana ara-dalàna
16. Fampahalalana hafa

Ho an'ny akora fototra tsirairay vidina (SLES, CAPB, Comperlan, acide citrique...), angataho foana ny FDS amin'ny mpamatsy ary tehirizo — ilaina tsy maintsy raha misy loza (lohateny 4, fanampiana voalohany) ary mba hahafantarana ny fomba fitehirizana/fikarakarana azy amim-piarovana (lohateny 7).

2. CLP — mahatakatra ny etiketan'ny akora fototrao

CLP (Classification, Labelling and Packaging) dia ny rafitra iraisam-pirenena amin'ny sary mifamadika sy ny filazana loza hita amin'ny fonosana sy ny FDS-n'ny mpamatsinao. Ireo mahazatra indrindra ho an'ny akora fototry ny kosmetika/fanadiovana :

- Sary "marika fanontaniana" : mahatonga fanairana (matetika hita amin'ny tensioactif mifantoka toy ny SLES na LABSA tsy voakitika, alohan'ny fandiravana)
- Sary "fahasimbana" : ho an'ny vokatra mifantoka be na misy pH mihoa-pampana (oh. soude caustique, acide mifantoka)
- Filazana H (fehezanteny momba ny loza, oh. "H315 : mahatonga fanairana amin'ny hoditra") sy filazana P (torohevitra fitandremana, oh. "P280 : mitafy ganta fiarovana")

Ny fahafantarana mamaky ireo sary mifamadika ireo eo amin'ny fonosan'ny mpamatsy dia ahafahana mamantatra avy hatrany ny haavon'ny fitandremana ilaina na dia tsy mbola nosokafana aza ny FDS manontolo.

3. EPI — fitaovana fiarovana manokana farafahakeliny

Ho an'ny famokarana (jereo koa ny fitambarana fototra, §6 Fiarovana) :
- Ganta mahatohitra ny vokatra simika (tsy ganta fanasan-dovia tsotra manify fotsiny ho an'ny fikarakarana tensioactif mifantoka)
- Solomaso fiarovana, indrindra rehefa mandraraka vokatra mifantoka (risika hisian'ny fibaroaka)
- Amin'ny toerana tsy misy rivotra tsara, mety ilaina ny saron-tava mifanentana arakaraka ny vokatra ampiasaina (jereo ny FDS, lohateny 8)

4. Fomba fiasa ara-dalàna tsara ankapobeny

- Tehirizo ao amin'ny boaty antontan-taratasy azo idirana eo amin'ny toeram-piasana ny FDS rehetra avy amin'ny mpamatsinao
- Asio marika mazava ny bidao akora fototra rehetra, na dia aorian'ny famindrana azy amin'ny fonosana kely kokoa aza
- Tehirizo mitokana ny vokatra tsy mifanaraka (jereo foana ny lohateny 7 sy 10 ao amin'ny FDS raha misy fisalasalana)
- Tehirizo ny taratasin'ny lot (Module 4) ho porofo fahafahana mizaha ny lalana raha misy fanamarinana na fitarainana$$
where title = 'Sécurité, FDS & Réglementation'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

update public.formation_course_modules
set content_text_mg = $$1. Mikajy ny vidim-pamokarana tena izy

Ny vidim-pamokarana ny litatra iray ranon-tsavony fanasana vilia dia tsy ny vidin'ny tensioactif fotsiny — ilaina atambatra :
- Akora fototra : tensioactif + sira + acide citrique + loko + manitra + fitahirizana (jereo Module 1 §6 ho an'ny fikajiana ny habetsaka tsirairay, Module 3 ho an'ny fitambarana 5)
- Fonosana : bidao/tavoahangy + etiketa (jereo ny endrika ekena, Module 6 §4)
- Asa tanana : fotoam-pamokarana × ny vidiny isan'ora azonao (na dia ianao mihitsy aza no mamokatra, omeo lanja ny fotoanao — raha tsy izany dia diso ny fikajiana ny tombony)
- Sarany ankapobeny : angovo, rano, fihenan-danjan'ny fitaovana (mizana, siny...) zaraina amin'ny isan'ny litatra vokarina

Vidim-pamokarana isaky ny litatra = (Akora fototra + Fonosana + Asa tanana + Sarany ankapobeny) ÷ Isan'ny litatra amin'ny lot

2. Manamboatra tabilao vidiny

Ampifangaroy ny sokajy 3-nao (Module 3 §1 : Mora / Antonony / Ambony) amin'ny endrika ekenao (Module 6 §4) mba hanamboarana tabilao feno. Isaky ny efijery, atombohy amin'ny vidim-pamokarana isaky ny litatra dia ampiharo ny tombony mifanaraka amin'ny laharana :

- Mora : tombony kely kokoa (20-30%), habetsaky ny varotra lehibe kokoa
- Antonony : tombony antonony (30-50%)
- Ambony : tombony ambony kokoa (50% sy mihoatra), ny mpanjifa dia mandoa ho an'ny fifantohana/kalitao heverina

Fitandremana : ny vidiny isaky ny litatra dia tokony hihena kely amin'ny ankapobeny amin'ny endrika lehibe kokoa (fampirisihana hividy bebe kokoa), fa tsy tokony ho ambanin'ny vidim-pamokarana + tombony farafahakeliny ekena mihitsy.

3. Mivarotra amin'ny B2C na B2B — fomba fisaina roa samihafa

- B2C (varotra mivantana amin'ny mpanjifa farany) : endrika kely, vidiny isan'iray ambony kokoa, tombony mahafinaritra kokoa isaky ny litatra, fandoavam-bola avy hatrany — izy no varotra "an-tsingaro".
- B2B (varotra amin'ny mpivarotra indray, hotely, orinasa fanadiovana...) : endrika lehibe na commande an-tsokajy, vidiny midina arakaraka ny habetsaka (tombony kely kokoa isaky ny litatra fa habetsaka be kokoa), matetika misy fe-potoam-pandoavam-bola hifampiraharahana, ary fifandraisana ara-barotra tokony hotehirizina amin'ny lava-potoana fa tsy varotra indray mandeha.

Samy azo atao ny roa : tehirizo ny sokajy Antonony/Ambony ho an'ny B2C, dia atolory ny sokajy Mora amin'ny fonosana lehibe ho an'ny B2B.

4. Mpikajy ny tombony — ny fitambarana fototra

Alohan'ny hanombohana lot na tolotra vaovao, kajio foana ny tombony amin'ity fikajiana tsotra ity :

Tombony = (Vidin'ny varotra × Habetsaka namidy) − (Vidim-pamokarana isaky ny litatra × Habetsaka novokarina)

Ohatra : 20 litatra amin'ny Fitambarana 2 (Antonony) novokarina, vidim-pamokarana heverina ho 3 000 Ar/L, namidy 5 000 Ar/L :
Tombony = (5 000 × 20) − (3 000 × 20) = 100 000 − 60 000 = 40 000 Ar

Avero io fikajiana io isaky ny : miova ny vidin'ny mpamatsy iray (Module 2 §3), manova sokajy ianao (Module 3), na manandrana endrika/làlam-barotra vaovao ianao (B2C vs B2B) — izy no fomba tsara indrindra hahafantarana raha tena mitondra tombony tokoa ny tolotra iray alohan'ny hanaovana azy.$$
where title = 'Commercialisation & Business'
  and course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%');

-- Vérification : doit renvoyer 9 lignes avec content_text_mg rempli.
select sort_order, title, (content_text_mg is not null) as a_traduction_mg
from public.formation_course_modules
where course_id = (select id from public.formation_courses where title ilike '%liquide vaisselle%')
order by sort_order;
