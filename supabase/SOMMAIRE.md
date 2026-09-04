# Sommaire des scripts SQL (supabase/)

Index de tous les scripts SQL du projet, dans l'ordre chronologique réel
(vérifié via l'historique git), pour naviguer facilement sans avoir à
deviner. **Aucun fichier n'a été renommé** — les noms restent identiques
à ceux déjà exécutés sur la base de données.

## ⚠️ Règle depuis le 03/09/2026 : un seul endroit pour le SQL

Le site web vit maintenant dans un dépôt séparé
(`Anju-codermad/groupe-akora-site`), mais **partage la même base
Supabase** que cette application. Pour éviter que deux migrations
écrites séparément (une par dépôt) n'entrent en conflit sur la même
base :

- **Toute nouvelle migration SQL, y compris celles proposées depuis la
  conversation/le dépôt du site, doit être ajoutée ICI**
  (`AkoraHub-app/supabase/`), avec le prochain numéro de phase
  disponible, avant d'être exécutée dans Supabase.
- Le dépôt `groupe-akora-site` ne doit **pas** avoir son propre dossier
  `supabase/` avec des migrations concurrentes — si une session Claude
  y en crée un par erreur, le fichier doit être déplacé ici (avec un
  numéro de phase) avant exécution, puis supprimé de l'autre dépôt.
- Concrètement pour la propriétaire : avant d'exécuter un script SQL
  proposé par la conversation du site dans l'éditeur Supabase, faites-le
  d'abord relire par la conversation de l'app (celle-ci) pour
  attribution du numéro de phase et vérification de conflit.

⚠️ Quelques numéros sont utilisés par plusieurs fichiers (4, 5, 6, 8, 9) —
c'est un doublon historique, pas une erreur : dans ce sommaire ils sont
listés l'un après l'autre, dans l'ordre où ils ont réellement été créés.
`phase13` et `phase61` ont des suffixes `_a`/`_b` : ce sont volontairement
plusieurs fichiers pour une seule et même phase (pas un doublon).

| # | Fichier | Description |
|---|---------|-------------|
| 1 | `phase1_schema.sql` |  |
| 2 | `phase2_patch.sql` | permet aux clients de créer leurs propres lignes |
| 3 | `phase3_schema.sql` |  |
| 4 ⚠️ | `phase4_schema.sql` |  |
| 4 ⚠️ | `phase4_patch_avatars.sql` | bucket avatars (Profil client) |
| 5 ⚠️ | `phase5_patch_geolocation.sql` | géolocalisation précise (profils) |
| 5 ⚠️ | `phase5_patch_orders_geolocation.sql` | géolocalisation précise (commandes) |
| 6 ⚠️ | `phase6_patch_categories.sql` | sous-catégories produit (categories) |
| 6 ⚠️ | `phase6_patch_home_banners.sql` | bannière hero de l'accueil client |
| 7 | `phase7_patch_favorites.sql` | table favorites (Favoris client) |
| 8 ⚠️ | `phase8_patch_product_images.sql` | photos produit (jusqu'à 10 par produit) |
| 8 ⚠️ | `phase8_patch_messaging.sql` | messagerie privée client ↔ staff |
| 9 ⚠️ | `phase9_patch_public_profiles.sql` | profils clients publics (légers) |
| 9 ⚠️ | `phase9_patch_categories_active.sql` | activer/désactiver les catégories |
| 10 | `phase10_patch_new_business_units.sql` | 3 nouveaux piliers + catégories |
| 11 | `phase11_schema.sql` |  |
| 12 | `phase12_schema.sql` |  |
| 13 | `phase13_schema.sql` |  |
| 13 | `phase13_schema_a.sql` |  |
| 13 | `phase13_schema_b_cron_optional.sql` |  |
| 14 | `phase14_schema.sql` |  |
| 15 | `phase15_schema.sql` |  |
| 16 | `phase16_schema.sql` |  |
| 17 | `phase17_schema.sql` |  |
| 18 | `phase18_schema.sql` |  |
| 19 | `phase19_patch_birth_date.sql` |  |
| 20 | `phase20_patch_profile_bio_cover.sql` | bio + photo de couverture du profil client |
| 21 | `phase21_patch_new_business_units.sql` |  |
| 22 | `phase22_patch_cleanup_duplicate_pilier.sql` |  |
| 23 | `phase23_patch_messages_missing_columns.sql` |  |
| 24 | `phase24_patch_notification_sound_prefs.sql` | préférence de son de notification par catégorie |
| 25 | `phase25_patch_orders_driver_position.sql` | position du livreur (suivi de livraison) |
| 26 | `phase26_patch_flash_infos.sql` | Flash infos (annonces courtes) |
| 27 | `phase27_patch_orders_payment_method.sql` | Mode de paiement de la commande |
| 28 | `phase28_patch_payment_method_settings.sql` | Activation/désactivation des modes de paiement |
| 29 | `phase29_patch_payment_proof.sql` | Référence et preuve de paiement |
| 30 | `phase30_patch_message_attachments.sql` | Pièces jointes dans la messagerie |
| 31 | `phase31_patch_orders_delivery_address.sql` | adresse de livraison précisée par le client. |
| 32 | `phase32_patch_notification_sound_catalog.sql` | Catalogue de sons de notification géré par l'Admin |
| 33 | `phase33_patch_raw_material_name_suggestions.sql` | Suggestions de noms pour Matières Premières |
| 34 | `phase34_patch_security_audit_log.sql` | Journalisation sécurité + rate limiting connexion |
| 35 | `phase35_patch_login_rate_limit.sql` | Rate limiting connexion via Edge Function |
| 36 | `phase36_patch_product_category_subscriptions.sql` | Abonnement aux notifications par catégorie |
| 37 | `phase37_patch_calls.sql` | Appels audio/vidéo dans la messagerie (Agora) |
| 38 | `phase38_patch_papi_payment.sql` | Paiement en ligne automatique (Papi.mg) |
| 39 | `phase39_patch_manual_payment_staff_notification.sql` | notification push immédiate au staff |
| 40 | `phase40_schema.sql` | Matières premières (Formation) + abonnement payant |
| 41 | `phase41_patch_seed_raw_materials.sql` | Contenu technique des matières premières |
| 42 | `phase42_patch_produits_categories.sql` | alignement partiel sur le document |
| 43 | `phase43_patch_formation_courses.sql` | liste des formations/modules AkoraFormation |
| 44 | `phase44_patch_mfa_audit_log.sql` | journal de sécurité pour la double |
| 45 | `phase45_patch_formation_per_product_pricing.sql` | Formation — achat par produit (paliers dégressifs) |
| 46 | `phase46_patch_communaute_replies_reactions.sql` | réponses aux commentaires, réactions emoji |
| 47 | `phase47_patch_report_and_whatsapp_contact.sql` | signaler une publication + numéro |
| 48 | `phase48_patch_friends_and_private_chat.sql` | demandes d'ami + messagerie privée entre |
| 49 | `phase49_patch_formation_web_bucket.sql` | espace public pour la page web Formation |
| 50 | `phase50_patch_course_purchases_and_content.sql` | achat des cours AkoraFormation + |
| 51 | `phase51_patch_block_hide_save_posts.sql` | Communauté — bloquer un client, masquer |
| 52 | `phase52_patch_official_badge_pinned_posts.sql` | Communauté — badge "Officiel", publication |
| 53 | `phase53_patch_post_images_carousel.sql` | Communauté — carrousel multi-images |
| 54 | `phase54_patch_trending_posts.sql` | Communauté — fil "Tendances" (Lot 4). |
| 55 | `phase55_patch_verified_purchases_reviews.sql` | Communauté — avis vérifiés (achat réel), |
| 56 | `phase56_patch_formation_groups.sql` | Groupes communautaires AkoraFormation, par |
| 57 | `phase57_patch_delivery_addresses.sql` | Profil client — adresses de livraison |
| 58 | `phase58_patch_formation_purchases_staff_notification.sql` | notification push immédiate au staff |
| 59 | `phase59_patch_fiveonepay_payment.sql` | Intégration FiveOne Pay (Lot 1/4 — SQL) |
| 60 | `phase60_patch_customer_360.sql` | Fiche client 360° (CRM, Lot 1/5) — SQL |
| 61 | `phase61_patch_crm_lot2_a.sql` | CRM Lot 2/5 — notes, étiquettes, relances |
| 61 | `phase61_patch_crm_lot2_b_cron_optional.sql` | planifie |
| 62 | `phase62_patch_crm_lot3.sql` | CRM Lot 3/5 — statut VIP, |
| 63 | `phase63_patch_crm_lot4_segmentation.sql` | CRM Lot 4/5 — segmentation & marketing |
| 64 | `phase64_patch_client_order_cancel.sql` | Commandes client Lot 3/5 — annulation |
| 65 | `phase65_patch_service_requests.sql` | nouveau menu "Services" côté client — |
| 66 | `phase66_patch_service_catalog.sql` | catalogue de services (onglet "Services") |
| 67 | `phase67_patch_referral_program.sql` | programme de parrainage |
| 68 | `phase68_patch_chat_bubble_toggle.sql` | activer/désactiver la bulle de chat |
| 69 | `phase69_patch_order_archiving.sql` | archivage des commandes côté client |
| 70 | `phase70_patch_app_latest_version.sql` | vérification de mise à jour in-app |
| 71 | `phase71_patch_profile_first_last_name.sql` | séparer nom et prénom (profil client) |
| 72 | `phase72_patch_app_releases_bucket.sql` | bucket public pour l'APK (lien stable) |
| 73 | `phase73_patch_product_use_cases.sql` | usages produit (Savonnerie, Industriel...) |
| 74 | `phase74_patch_profile_cover_photos.sql` | plusieurs photos de couverture (profil client) |
| 75 | `phase75_patch_personalization_algorithms.sql` | algorithmes de personnalisation |
| 76 | `phase76_patch_profile_lock.sql` | profil verrouillé (privé) |
| 77 | `phase77_patch_product_stock_alerts.sql` | "M'alerter quand disponible" (rupture de stock) |
| 78 | `phase78_patch_rotate_webhook_secret.sql` | rotation du WEBHOOK_SECRET |
| 79 | `phase79_patch_public_profile_card_style.sql` | carte de profil + amis en commun (profil public) |
| 80 | `phase80_patch_usual_cart.sql` | "Mon panier habituel" |
| 81 | `phase81_patch_academie_matieres_premieres.sql` | Académie Matières Premières (fiche technique) |
| 82 | `phase82_patch_academie_champs_obligatoires.sql` | Académie — champs obligatoires |
| 83 | `phase83_patch_fusion_academie_matieres.sql` | fusion de l'achat Académie avec l'achat |
| 84 | `phase84_patch_suppression_academie_purchases.sql` | suppression définitive de l'ancien achat |
| 85 | `phase85_patch_academie_pictogrammes_dosages.sql` | pictogrammes de danger (SGH/CLP), phrases |
| 86 | `phase86_seed_pictogrammes_phrases.sql` | seed des pictogrammes SGH/CLP et des |
| 87 | `phase87_data_soude_caustique.sql` | remplissage fiche Académie "Soude |
| 88 | `phase88_cleanup_doublons_acides_bases.sql` | nettoyage doublons "Acides & Bases" |
| 89 | `phase89_data_acide_sulfurique.sql` | fiche Académie complète "Acide |
| 90 | `phase90_data_acide_chlorhydrique.sql` | fiche Académie complète "Acide |
| 91 | `phase91_data_carbonate_bicarbonate_ammoniaque.sql` | fiches Académie "Carbonate de sodium", |
| 92 | `phase92_data_citrique_phosphorique_acetique.sql` | fiches Académie "Acide citrique", |
| 93 | `phase93_data_nitrique_oxalique_lactique_chaux_silicate.sql` | fiches Académie "Acide nitrique", |
| 94 | `phase94_data_variantes_alimentaires_soude_bicarbonate.sql` | duplique le contenu Académie déjà |
| 95 | `phase95_data_benzoique_borique_fumarique_gluconique_malique_sulfamique_tartrique_carbonate_chlorure_citrate_potasse_glauber_alun.sql` | fiches Académie pour les 13 dernières |
| 96 | `phase96_ajout_catalogue_chelatants.sql` | ajout de 10 nouveaux chélatants au |
| 97 | `phase97_data_chelatants_edta_glda_mgda_hedp_atmp_dtpa_polyaspartate_phytique.sql` | fiches Académie pour 9 des 12 |
| 98 | `phase98_data_gluconate_sodium_dtpmpa.sql` | fiches Académie "Gluconate de sodium |
| 99 | `phase99_ajout_catalogue_desinfectants.sql` | ajout de 11 nouveaux désinfectants au |
| 100 | `phase100_data_desinfectants_bac_ddac_phmb_ethanol_ipa_bcdmh_dioxyde_glutaraldehyde_chloraminet_argent_iode.sql` | fiches Académie pour les 11 nouveaux |
| 101 | `phase101_data_paa_hypochlorite_calcium_sodium_peroxyde_tcca.sql` | fiches Académie pour les 5 derniers |
| 102 | `phase102_ajout_catalogue_epaississants.sql` | ajout de 10 nouveaux épaississants au |
| 103 | `phase103_data_epaississants_caroube_tara_gellane_konjac_alginate_karaya_adragante_hpmc_methylcellulose.sql` | fiches Académie pour 9 des 10 nouveaux |
| 104 | `phase104_ajout_et_fiche_pga.sql` | ajout au catalogue + fiche Académie |
| 105 | `phase105_data_ethylcellulose.sql` | fiche Académie "Éthylcellulose (E462)" |
| 106 | `phase106_data_agar_amidons_carraghenanes_cmc_gelatine_glycerine_arabique_guar.sql` | fiches Académie pour 9 des 22 produits |
| 107 | `phase107_data_xanthane_lecithine_monodiglycerides_pectines_plasmal_polysorbate_stpp.sql` | fiches Académie pour 9 des 13 derniers |
| 108 | `phase108_ajout_catalogue_solvants.sql` | ajout au catalogue de 16 nouveaux |
| 109 | `phase109_data_solvants_16_nouveaux.sql` | fiches Académie pour les 16 nouveaux |
| 110 | `phase110_data_solvants_7_existants.sql` | fiches Académie pour les 7 solvants |
| 111 | `phase111_ajout_catalogue_charges_minerales.sql` | ajout au catalogue de 16 nouvelles |
| 112 | `phase112_data_charges_minerales_16.sql` | fiches Académie pour les 16 nouvelles |
| 113 | `phase113_data_charges_minerales_9_existants.sql` | fiches Académie pour les 9 charges |
| 114 | `phase114_ajout_catalogue_colorants.sql` | ajout au catalogue de 23 nouveaux |
| 115 | `phase115_data_colorants_26.sql` | fiches Académie pour les 26 nouveaux |
| 116 | `phase116_data_colorants_13_existants.sql` | fiches Académie pour les 13 colorants |
| 117 | `phase117_ajout_catalogue_huiles_beurres.sql` | ajout au catalogue de 37 nouvelles |
| 118 | `phase118_data_huiles_beurres_lot1.sql` | fiches Académie pour le lot 1 (8 |
| 119 | `phase119_data_huiles_beurres_lot2.sql` | fiches Académie pour le lot 2 (8 |
| 120 | `phase120_data_huiles_beurres_lot3.sql` | fiches Académie pour le lot 3 (9 |
| 121 | `phase121_data_huiles_beurres_lot4.sql` | fiches Académie pour le lot 4 (7 |
| 122 | `phase122_data_huiles_beurres_lot5.sql` | fiches Académie pour le lot 5 (5 |
| 123 | `phase123_data_huiles_beurres_9_existants.sql` | fiches Académie pour les 9 produits |
| 124 | `phase124_ajout_catalogue_conservateurs_antioxydants.sql` | ajout au catalogue de 30 nouveaux |
| 125 | `phase125_data_conservateurs_lot1.sql` | fiches Académie pour le lot 1 (8 |
| 126 | `phase126_data_conservateurs_lot2.sql` | fiches Académie pour le lot 2 (8 |
| 127 | `phase127_data_conservateurs_lot3.sql` | fiches Académie pour le lot 3 (8 |
| 128 | `phase128_data_conservateurs_lot4.sql` | fiches Académie pour le lot 4 (dernier |
| 129 | `phase129_data_conservateurs_15_existants.sql` | fiches Académie pour les 15 produits |
| 130 | `phase130_ajout_catalogue_polymeres_resines.sql` | ajout au catalogue de 20 nouveaux |
| 131 | `phase131_data_polymeres_lot1.sql` | fiches Académie pour le lot 1 (7 |
| 132 | `phase132_data_polymeres_lot2.sql` | fiches Académie pour le lot 2 (7 |
| 133 | `phase133_data_polymeres_lot3.sql` | fiches Académie pour le lot 3 (dernier |
| 134 | `phase134_data_polymeres_floculants_existant.sql` | fiche Académie pour le produit déjà |
| 135 | `phase135_ajout_catalogue_parfums_additifs.sql` | ajout de nouveaux produits au |
| 136 | `phase136_data_parfums_lot1.sql` | fiches Académie pour le lot 1 (8 |
| 137 | `phase137_data_parfums_lot2.sql` | fiches Académie pour le lot 2 (8 |
| 138 | `phase138_data_parfums_lot3.sql` | fiches Académie pour le lot 3 (8 |
| 139 | `phase139_data_parfums_lot4.sql` | fiches Académie pour le lot 4 (8 |
| 140 | `phase140_data_parfums_lot5.sql` | fiches Académie pour le lot 5 (8 |
| 141 | `phase141_data_parfums_lot6.sql` | fiches Académie pour le lot 6 (7 |
| 142 | `phase142_data_parfums_existants.sql` | fiches Académie pour les 35 produits |
| 143 | `phase143_ajout_catalogue_tensioactifs.sql` | ajout de nouveaux produits au |
| 144 | `phase144_data_tensioactifs_nouveaux.sql` | fiches Académie pour les 37 nouveaux |
| 145 | `phase145_data_tensioactifs_existants.sql` | fiches Académie pour les 14 produits |
| 146 | `phase146_patch_public_profiles_loyalty.sql` | palier de fidélité dans public_profiles |
| 147 | `phase147_patch_products_academie_link.sql` | lien produit -> fiche Académie + |
| 148 | `phase148_patch_complete_products_from_academie.sql` | compléter automatiquement le catalogue |
| 149 | `phase149_categorie_oxydants_agents_blanchiment.sql` | nouvelle catégorie Académie |
| 150 | `phase150_patch_pictogrammes_oxydants.sql` | pictogrammes SGH/CLP pour les 5 |
| 151 | `phase151_patch_pictogrammes_auto_toutes_categories.sql` | pictogrammes SGH/CLP automatiques |
| 152 | `phase152_patch_security_audit_log_new_events.sql` | autoriser mfa_enabled/mfa_disabled/ |
| 153 | `phase153_patch_fix_role_escalation.sql` | CORRECTIF CRITIQUE — élévation de |
| 154 | `phase154_patch_fix_order_price_tampering.sql` | CORRECTIF CRITIQUE — falsification du |
| 155 | `phase155_patch_protect_message_content.sql` | protéger le contenu des messages |
| 156 | `phase156_data_produits_softberry.sql` | gamme "Softberry" (5 cosmétiques, |
| 157 | `phase157_patch_fix_download_url_github_release.sql` | réparer le lien de mise à jour in-app |
| 158 | `phase158_patch_completer_catalogue_produits_v2.sql` | rattraper les matières premières |
| 159 | `phase159_patch_auto_creation_produit_academie.sql` | création automatique du produit |
| 160 | `phase160_patch_expiration_flash_infos.sql` | expiration automatique des flash infos |
| 161 | `phase161_patch_notif_nouveau_client.sql` | notifier le staff dès qu'un nouveau |
| 162 | `phase162_patch_fix_call_no_staff_found.sql` | corrige "Aucun membre de l'équipe |
| 163 | `phase163_patch_gender_field.sql` | champ sexe (Homme/Femme) sur le profil |
| 164 | `phase164_patch_country_field.sql` | pays du client (géolocalisation) |
| 165 | `phase165_patch_region_field.sql` | région de Madagascar sur le profil client |
| 166 | `phase166_patch_add_roles_services_livraison.sql` | nouveaux rôles Services et Livraison |
| 167 | `phase167_patch_roles_services_livraison_access.sql` | accès restreint pour les rôles |
| 168 | `phase168_patch_client_type_secteurs.sql` | élargir les secteurs d'activité client |
| 169 | `phase169_patch_notify_all_clients_new_product.sql` | notifier tous les clients à la |
| 170 | `phase170_patch_random_products_home.sql` | sélection aléatoire de produits pour |
| 171 | `phase171_patch_random_products_sector_weighting.sql` | pondération par secteur pour "Découvrez |
| 172 | `phase172_patch_conditionnements_industriels.sql` | conditionnements industriels (poids) + |
| 173 | `phase173_patch_format_fut_45kg.sql` | conditionnement manquant (Fût 45 kg) |
| 174 | `phase174_patch_random_products_exclude_recent.sql` | éviter les doublons entre "Pour vous" |
| 175 | `phase175_patch_variant_stock_alerts.sql` | alertes de stock étendues aux variantes |
| 176 | `phase176_patch_rotate_webhook_secret_v2.sql` | rotation du WEBHOOK_SECRET (2e fois) |
| 187 | `phase187_patch_fix_formation_price_tampering.sql` | CORRECTIF CRITIQUE — falsification du prix des achats Formation (matières premières et cours) |
| 188 | `phase188_patch_categorie_akoreau.sql` | nouvelle catégorie "Akor'Eau" (traitement de l'eau) |
| 189 | `phase189_patch_move_produits_eau_vers_akoreau.sql` | déplace 3 produits 100% eau (Alun, Polymères floculants, TCCA) vers "Akor'Eau" |
| 190 | `phase190_ajout_produits_traitement_eau.sql` | 6 nouveaux produits "Akor'Eau" (chlorure/sulfate ferrique, PAC, SHMP, bisulfate de sodium, résine échangeuse de cations) |

⚠️ Sommaire incomplet : les fichiers `phase177` à `phase186` existent déjà dans
le dossier mais n'étaient pas encore listés ici avant l'ajout de la ligne
187 ci-dessus (constaté le 03/09/2026 depuis la conversation du site web,
hors scope de cette conversation pour les documenter rétroactivement).
