-- ============================================================
-- AkoraHub - Phase 283 : version malgache de la formation
-- "Liquide vaisselle" + adaptation marché Madagascar
--
-- Demande explicite (28/10) : une formation séparée, entièrement en
-- malgache (pas juste une traduction du français collée à côté), avec
-- en plus des infos pratiques pour le marché local : où acheter les
-- matières premières (renvoie vers le catalogue Akora Fanadiovana) et
-- un module sur le calcul du prix de vente conseillé.
--
-- IMPORTANT : la traduction malgache ci-dessous a été rédigée du
-- mieux possible, mais n'a pas été relue par une personne malgache
-- native — à vérifier/corriger par la propriétaire avant publication
-- si besoin (champ "status" laissé à 'en_projet' volontairement, voir
-- plus bas : pas de prix ni de "deja_developpee" tant que le texte
-- n'a pas été relu).
--
-- Même catégorie que la version française ("Entretien & Hygiène")
-- pour qu'elles apparaissent côte à côte dans le menu Académie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

with new_course as (
  insert into public.formation_courses (category, title, status, module_count, price)
  values ('Entretien & Hygiène', 'Savony fanasan-dovia (Malagasy)', 'en_projet', 8, null)
  returning id
)
insert into public.formation_course_modules (course_id, title, content_text, sort_order)
select id, title, content_text, sort_order
from new_course, (values
  (0, 'Tanjon''ny fiofanana', $$Mianatra ny fomba fanamboarana savony fanasan-dovia manify vovoka, mahafoana menaka, ary matanjaka, miorina amin'ny fitambarana akora tsotra azo ovaina arakaraka ny tetibola sy ny kalitao tadiavina.$$),
  (1, 'Fitaovana ilaina', $$- Sini-pangaro na bakoly (farafahakeliny 6 litatra)
- Spatola na zavatra ahasarotiny ny fangarahana
- Mizana (mizana an-dakozia na mizana marina)
- Tavoahangy/bidao foana hamenoana ny vokatra
- Ganta fiarovana$$),
  (2, 'Akora ilaina (ho an''ny 5 litatra)', $$- Rano : Hatramin'ny 5 L — fototra/famenoana
- SLES 70% : 400 g (~8%) — akora mahatonga vovoka sy manadio voalohany indrindra
- CAPB 45% : 150 g (~3%) — manamora ny hoditra, manamafy ny vovoka
- Comperlan / Cocamide DEA 85% : 50 g (~1%) — mampitoetra sy mampitevina ny vovoka
- Sira (NaCl), aroboka amin'ny rano kely aloha : 50 hatramin'ny 100 g (azo ovaina) — mampitevina ny vokatra
- Acide citrique : vitsivitsy grama, aroboka — manamboatra ny pH (tanjona : 6 ka hatramin'ny 7)
- Loko : vitsivitsy dropa, aroboka — fandokoana
- Manitra : 15 ka hatramin'ny 20 g (~0,3%) — fofona
- Fitahirizana (conservateur) : araka ny dose omen'ny mpamatsy — misoroka ny fitomboan'ny mikraoba$$),
  (3, 'Fomba fanaovana', $$1. Araro ao anaty sini-pangaro ny 70% eo ho eo amin'ny rano rehetra.
2. Ampio ny SLES miaraka amin'ny fangarahana malefaka (raha mafy loatra ny fangarahana dia hamorona vovoka be loatra mandritra ny famokarana). Aoka hiely tsara.
3. Ampio ny CAPB, afangaro.
4. Ampio ny Comperlan/Cocamide DEA, afangaro.
5. Dingana lehibe — fampitevenana : aroboka amin'ny rano mangarahara kely ny sira, dia ampio tsikelikely amin'ny fangarahana mandra-pahazoana ny votoatiny tadiavina. Ajanony rehefa mety ilay votoatiny — ny sira be loatra dia mety hahatonga ny vokatra ho maloto na misy voantsinapaka.
6. Ampio ny loko aroboka, afangaro.
7. Ampio ny manitra, afangaro malefaka.
8. Ampio ny fitahirizana araka ny dose nomen'ny mpamatsy.
9. Jereo ny pH (taratasy pH na mpamantatra pH) ary ovay amin'ny acide citrique aroboka raha ilaina — tanjona : pH 6 ka hatramin'ny 7.
10. Ampio ny rano sisa tavela mandra-pahatongan'ny 5 litatra.
11. Avelao hitoetra 24 ora talohan'ny fameneram-potoana — ho levona ny baolina rivotra ary hitoetra ny votoatiny.$$),
  (4, 'Torohevitra sy ny tsy tokony hatao', $$- Aza ampiana ny sira raha mbola tsy levona tsara ny SLES — tsy ho mitovy ny vokatra.
- Ampio tsikelikely ny sira ary andramo isaky ny fanampiana — sarotra ny miverina raha be loatra no nampiana.
- Ny vokatra manify loatra (rano) matetika dia tsy ampy sira ; ny vokatra misy voantsinapaka/maloto kosa matetika be loatra sira.$$),
  (5, 'Fiarovana', $$- Mitafia ganta mandritra ny famokarana.
- Esory ny fifandraisana amin'ny maso.
- Asio marika mazava ny bidao misy akora voalohany.
- Tehirizo lavitra ny hafanana sy ny masoandro mivantana.$$),
  (6, 'Aiza no hividianana ireo akora', $$Ny akora rehetra ampiasaina amin'ity fiofanana ity (SLES, CAPB, Comperlan, sira, acide citrique, loko, manitra, fitahirizana) dia hita ao amin'ny tahirin-java-mividy an'i Akora Fanadiovana — jereo ny tabilao "Matières premières" ao amin'ny application mba hahitana ny vidiny sy ny fahazoana azy ankehitriny.$$),
  (7, 'Torohevitra momba ny vidin''ny varotra', $$Kajio aloha ny vidin'ny fanamboarana (akora + fonosana + angovo) isaky ny litatra, dia ampio tombom-barotra mety (ohatra 30% ka hatramin'ny 50% arakaraka ny toerana ivarotana). Jereo koa ny vidin'ny vokatra mitovy amin'ny tsena akaiky anao mba hamaritana vidiny mifanaraka amin'ny mpividy, nefa mbola mitondra tombony ho anao.$$)
) as modules(sort_order, title, content_text);
