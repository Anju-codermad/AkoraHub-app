import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/chat/unread_support_messages.dart';
import '../../core/localization/app_translations.dart';
import '../../core/navigation/product_detail_route.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'community/public_profiles_repo.dart';
import 'favorites_provider.dart';
import 'flash_infos_screen.dart';
import 'formation/akora_formation_screen.dart';
import 'orders_tab.dart';
import 'product_detail_client.dart';
import 'wall/wall_tab.dart';

class CatalogTab extends ConsumerStatefulWidget {
  final VoidCallback onOpenCart;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCatalog;

  const CatalogTab({
    super.key,
    required this.onOpenCart,
    required this.onOpenProfile,
    required this.onOpenCatalog,
  });

  @override
  ConsumerState<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<CatalogTab> {
  bool _isLoading = true;
  String? _error;

  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String? _clientName;
  String? _clientAvatarUrl;
  String? _clientLocation;
  int _unreadMessagesCount = 0;
  List<_ActivityItem> _activityFeed = [];
  List<Map<String, dynamic>> _reorderSuggestions = [];
  String? _flashInfo;

  /// Id de l'annonce flash affichée — distinct de `_flashInfo` (son
  /// texte) pour pouvoir mémoriser localement laquelle a déjà été lue
  /// (voir `_dismissedFlashInfoPrefsKey`) sans dépendre du contenu, qui
  /// pourrait coïncider entre deux annonces différentes.
  String? _flashInfoId;
  static const _dismissedFlashInfoPrefsKey = 'dismissed_flash_info_id';

  List<Map<String, dynamic>> _recentFormationCourses = [];

  /// Devis en attente de réponse ou paiement en échec — la chose la plus
  /// urgente qui nécessite une action du client, mise en avant en haut de
  /// l'accueil plutôt que noyée dans l'onglet Commandes (Lot 4).
  Map<String, dynamic>? _pendingAction;

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  // Repli par défaut : utilisé tant que l'Admin n'a créé aucune bannière
  // dans home_banners (voir supabase/phase6_patch_home_banners.sql et
  // l'écran Admin home_banners_management.dart).
  static const List<_PromoSlide> _defaultPromoSlides = [
    _PromoSlide(
      title: 'Vos produits,\nen un clic',
      subtitle: 'Rapide, fiable, adapté à votre activité',
      icon: Icons.local_shipping_outlined,
    ),
    _PromoSlide(
      title: 'Tarifs Gros\ndès la 1ère palette',
      subtitle: 'Remises automatiques à partir du seuil de quantité',
      icon: Icons.local_offer_outlined,
    ),
    _PromoSlide(
      title: 'Un compte,\ntrois activités',
      subtitle: 'Hygiène, peinture (ARCA) et formation, au même endroit',
      icon: Icons.grid_view_rounded,
    ),
  ];

  List<_PromoSlide> _promoSlides = _defaultPromoSlides;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final profile = userId == null
          ? null
          : await SupabaseConfig.client
              .from('profiles')
              .select('full_name, avatar_url, location')
              .eq('id', userId)
              .single();

      // Les 5 blocs suivants sont indépendants les uns des autres (filtre
      // catégories, bannières, badge messages, fil d'activité, suggestions
      // de réapprovisionnement) — on les lance en parallèle plutôt qu'à la
      // suite, pour ne pas cumuler leurs temps de réseau. Chacun gère déjà
      // son propre repli silencieux en cas d'échec.
      Future<List<_PromoSlide>> loadBanners() async {
        try {
          final bannerRows = await SupabaseConfig.client
              .from('home_banners')
              .select()
              .eq('active', true)
              .order('sort_order');
          final rows = List<Map<String, dynamic>>.from(bannerRows);
          if (rows.isEmpty) return _defaultPromoSlides;
          return rows
              .map((b) => _PromoSlide(
                    title: (b['title'] ?? '').toString(),
                    subtitle: (b['subtitle'] ?? '').toString(),
                    imageUrl: b['image_url'] as String?,
                  ))
              .toList();
        } catch (_) {
          return _defaultPromoSlides;
        }
      }

      Future<Map<String, dynamic>?> loadFlashInfo() async {
        try {
          return await SupabaseConfig.client
              .from('flash_infos')
              .select('id, message')
              .eq('active', true)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
        } catch (_) {
          return null;
        }
      }

      // Annonce déjà lue par ce client sur cet appareil (voir
      // _dismissedFlashInfoPrefsKey) — ne doit pas réapparaître tant que
      // l'Admin n'en publie pas une nouvelle (id différent).
      Future<String?> loadDismissedFlashInfoId() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString(_dismissedFlashInfoPrefsKey);
        } catch (_) {
          return null;
        }
      }

      Future<int> loadUnreadCount() => fetchUnreadSupportMessagesCount();

      Future<List<_ActivityItem>> loadActivityFeed() async {
        try {
          final recentPosts = await SupabaseConfig.client
              .from('posts')
              .select()
              .eq('visibility', 'public')
              .order('created_at', ascending: false)
              .limit(5);
          final postList = List<Map<String, dynamic>>.from(recentPosts);
          final authorIds = postList
              .map((p) => p['author_id'] as String?)
              .whereType<String>()
              .toSet();
          final authorProfiles = await PublicProfilesRepo.fetchByIds(authorIds);

          final recentProducts = await SupabaseConfig.client
              .from('products')
              .select()
              .eq('visibility', true)
              .order('created_at', ascending: false)
              .limit(5);
          final productList = List<Map<String, dynamic>>.from(recentProducts);

          var feed = [
            ...postList.map((p) => _ActivityItem.post(
                  p,
                  authorProfiles[p['author_id']],
                  DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
                )),
            ...productList.map((p) => _ActivityItem.product(
                  p,
                  DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
                )),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (feed.length > 8) feed = feed.sublist(0, 8);
          return feed;
        } catch (_) {
          return <_ActivityItem>[];
        }
      }

      Future<List<Map<String, dynamic>>> loadReorderSuggestions() async {
        if (userId == null) return [];
        try {
          final orderItemRows = await SupabaseConfig.client
              .from('order_items')
              .select('product_id, order_id, orders!inner(customer_id)')
              .eq('orders.customer_id', userId);
          final itemList = List<Map<String, dynamic>>.from(orderItemRows);

          // Compte le nombre de commandes DISTINCTES contenant chaque
          // produit (pas le nombre de lignes, pour éviter qu'une grosse
          // quantité dans une seule commande fausse le classement).
          final ordersByProduct = <String, Set<String>>{};
          for (final item in itemList) {
            final productId = item['product_id'] as String?;
            final orderId = item['order_id'] as String?;
            if (productId == null || orderId == null) continue;
            ordersByProduct.putIfAbsent(productId, () => {}).add(orderId);
          }
          final frequentProductIds = ordersByProduct.entries
              .where((e) => e.value.length >= 2)
              .toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          if (frequentProductIds.isEmpty) return [];
          final topIds =
              frequentProductIds.take(5).map((e) => e.key).toList();
          final productRows = await SupabaseConfig.client
              .from('products')
              .select()
              .inFilter('id', topIds)
              .eq('visibility', true);
          final productsById = {
            for (final p in List<Map<String, dynamic>>.from(productRows))
              p['id'] as String: p
          };
          // Conserve l'ordre de fréquence (le plus recommandé en premier).
          return topIds
              .map((id) => productsById[id])
              .whereType<Map<String, dynamic>>()
              .toList();
        } catch (_) {
          return [];
        }
      }

      Future<List<Map<String, dynamic>>> loadRecentFormationCourses() async {
        try {
          final rows = await SupabaseConfig.client
              .from('formation_courses')
              .select('id, title, category, status')
              .eq('status', 'deja_developpee')
              .order('created_at', ascending: false)
              .limit(6);
          return List<Map<String, dynamic>>.from(rows);
        } catch (_) {
          return [];
        }
      }

      // Priorité : un devis envoyé attend une réponse du client avant tout
      // (décision à prendre) ; sinon, une commande dont le paiement a
      // échoué (action à refaire). "en_attente" n'est volontairement pas
      // inclus ici : ça signifie le plus souvent "en cours de vérification
      // manuelle par le staff", pas une action qui attend le client.
      Future<Map<String, dynamic>?> loadPendingAction() async {
        if (userId == null) return null;
        try {
          final quote = await SupabaseConfig.client
              .from('quotes')
              .select('id, quote_number')
              .eq('customer_id', userId)
              .eq('status', 'envoye')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (quote != null) {
            return {'type': 'quote', ...quote};
          }
          final order = await SupabaseConfig.client
              .from('orders')
              .select('id, order_number')
              .eq('customer_id', userId)
              .eq('payment_status', 'echoue')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (order != null) {
            return {'type': 'order_payment', ...order};
          }
          return null;
        } catch (_) {
          return null;
        }
      }

      final parallel = await Future.wait([
        loadBanners(),
        loadUnreadCount(),
        loadActivityFeed(),
        loadReorderSuggestions(),
        loadFlashInfo(),
        loadRecentFormationCourses(),
        loadPendingAction(),
        loadDismissedFlashInfoId(),
      ]);
      final loadedSlides = parallel[0] as List<_PromoSlide>;
      final unreadMessages = parallel[1] as int;
      final activityFeed = parallel[2] as List<_ActivityItem>;
      final reorderSuggestions = parallel[3] as List<Map<String, dynamic>>;
      final flashInfoRow = parallel[4] as Map<String, dynamic>?;
      final recentFormationCourses = parallel[5] as List<Map<String, dynamic>>;
      final pendingAction = parallel[6] as Map<String, dynamic>?;
      final dismissedFlashInfoId = parallel[7] as String?;
      final flashInfoId = flashInfoRow?['id'] as String?;
      // Déjà lue sur cet appareil (même id) : on ne la réaffiche pas.
      final flashInfo = (flashInfoId != null && flashInfoId == dismissedFlashInfoId)
          ? null
          : flashInfoRow?['message'] as String?;

      setState(() {
        _clientName = profile?['full_name'] as String?;
        _clientAvatarUrl = profile?['avatar_url'] as String?;
        _clientLocation = profile?['location'] as String?;
        _promoSlides = loadedSlides;
        _unreadMessagesCount = unreadMessages;
        _activityFeed = activityFeed;
        _reorderSuggestions = reorderSuggestions;
        _flashInfoId = flashInfoId;
        _flashInfo = flashInfo;
        _recentFormationCourses = recentFormationCourses;
        _pendingAction = pendingAction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les données.';
      });
    }
  }

  /// Masque le bandeau flash info dès que le client le consulte (tap) —
  /// mémorisé localement par id, ne réapparaît que si l'Admin publie une
  /// nouvelle annonce (voir `_dismissedFlashInfoPrefsKey`).
  Future<void> _dismissFlashInfo() async {
    final id = _flashInfoId;
    if (mounted) setState(() => _flashInfo = null);
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedFlashInfoPrefsKey, id);
    } catch (_) {
      // Pas grave : au pire l'annonce réapparaîtra à la prochaine
      // ouverture de l'app si le stockage local a échoué.
    }
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notifications',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 2.h),
              if (_unreadMessagesCount > 0)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(_unreadMessagesCount == 1
                      ? 'Un nouveau message de notre équipe'
                      : '$_unreadMessagesCount nouveaux messages de notre équipe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Center(
                    child: Text(
                      'Aucune nouvelle notification.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // Au retour (que la messagerie ait été ouverte ou non), on rafraîchit
    // le compteur — read_by_client aura pu passer à true entre-temps.
    _loadData();
  }

  void _quickAddToCart(Map<String, dynamic> product) {
    ref.read(cartProvider.notifier).addItem(
          CartItem(
            productId: product['id'],
            name: product['name'] ?? '',
            priceDetail: (product['price_detail'] ?? 0).toDouble(),
            priceGros: (product['price_gros'] ?? 0).toDouble(),
            grosThresholdQty: (product['gros_threshold_qty'] ?? 10) as int,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartCount = ref.watch(cartProvider).length;

    if (_isLoading) {
      return const _CatalogSkeleton();
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 5
        ? 'Bonsoir'
        : hour < 18
            ? 'Bonjour'
            : 'Bonsoir';
    final greetingName =
        (_clientName == null || _clientName!.trim().isEmpty)
            ? greetingPrefix
            : '$greetingPrefix, ${_clientName!.split(' ').first}';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // --- En-tête personnalisé : avatar, salutation, localisation, notifs ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onOpenProfile,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: _clientAvatarUrl != null
                          ? NetworkImage(_clientAvatarUrl!)
                          : null,
                      child: _clientAvatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_clientLocation != null &&
                            _clientLocation!.trim().isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _clientLocation!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$cartCount'),
                              isLabelVisible: cartCount > 0,
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined),
                                tooltip: 'Panier',
                                onPressed: widget.onOpenCart,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.receipt_long_outlined),
                              tooltip: 'Commandes',
                              // Commandes a quitté la barre du bas (04/08)
                              // pour laisser la place à l'onglet Catalogue
                              // — accès conservé ici, comme Messagerie.
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const OrdersTab()),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$_unreadMessagesCount'),
                              isLabelVisible: _unreadMessagesCount > 0,
                              child: IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                tooltip: 'Messagerie',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ChatScreen()),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$_unreadMessagesCount'),
                              isLabelVisible: _unreadMessagesCount > 0,
                              child: IconButton(
                                icon: const Icon(
                                    Icons.notifications_none_rounded),
                                tooltip: 'Notifications',
                                onPressed: _openNotifications,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- Raccourci recherche (04/08) : pas une vraie recherche
          // locale (la logique de recherche/pagination vit désormais
          // uniquement dans l'onglet Catalogue, voir
          // product_catalog_tab.dart, pour ne pas la dupliquer) — un tap
          // ouvre directement le Catalogue, comme sur beaucoup d'apps
          // e-commerce (barre de recherche "raccourci" sur l'accueil). ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.onOpenCatalog,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 1.6.h),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: 3.w),
                        Text(
                          ref.tr('search_hint'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Flash info (annonce courte de l'Admin, si présente) ---
          if (_flashInfo != null && _flashInfo!.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _dismissFlashInfo();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FlashInfosScreen()),
                    );
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _flashInfo!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Raccourci "en attente" (Lot 4) : devis à répondre ou
          // paiement en échec — la chose la plus urgente à traiter,
          // remontée en haut de l'accueil plutôt que noyée dans l'onglet
          // Commandes. ---
          if (_pendingAction != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  // OrdersTab a déjà sa propre AppBar (voir orders_tab.dart) —
                  // pas besoin de la ré-envelopper dans une seconde ici.
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdersTab(
                        initialTabIndex:
                            _pendingAction!['type'] == 'quote' ? 1 : 0,
                      ),
                    ),
                  ),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pendingAction!['type'] == 'quote'
                              ? Icons.request_quote_outlined
                              : Icons.error_outline,
                          size: 18,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _pendingAction!['type'] == 'quote'
                                ? 'Devis ${_pendingAction!['quote_number']} en attente de votre réponse'
                                : 'Le paiement de la commande ${_pendingAction!['order_number']} a échoué — à refaire',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onTertiaryContainer),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Bannière en carrousel ---
          SliverToBoxAdapter(
            child: SizedBox(
              height: 16.h,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _promoSlides.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, index) {
                  final slide = _promoSlides[index];
                  final hasImage =
                      slide.imageUrl != null && slide.imageUrl!.isNotEmpty;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.75),
                                ],
                              ),
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(slide.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.45),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slide.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    shadows: hasImage
                                        ? const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  slide.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.85),
                                    shadows: hasImage
                                        ? const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasImage && slide.icon != null)
                            Icon(
                              slide.icon,
                              size: 48,
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.85),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _promoSlides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _bannerIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _bannerIndex == i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Réapprovisionnement suggéré : produits commandés dans au
          // moins 2 commandes distinctes par ce client (voir _loadData).
          // Masqué si vide ou si le client n'a pas encore assez d'historique.
          if (_reorderSuggestions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Text('Vous recommandez souvent',
                    style: theme.textTheme.titleMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 26.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _reorderSuggestions.length,
                  itemBuilder: (context, index) {
                    final p = _reorderSuggestions[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: SizedBox(
                        width: 38.w,
                        // "Recommander" passé en badge interne à la carte
                        // (coin bas-gauche de la photo, seul coin libre :
                        // catégorie en haut-gauche, favori en haut-droite,
                        // ajout rapide en bas-droite) plutôt qu'empilé
                        // par-dessus dans un Stack séparé — évite la
                        // superposition avec l'étiquette de catégorie que ça
                        // provoquait auparavant (les deux au même repère
                        // top:8/left:8, dans deux Stack différents).
                        child: ProductCard(
                          product: p,
                          currency: _currency,
                          isFavorite:
                              ref.watch(favoritesProvider).contains(p['id']),
                          enableHero: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              productDetailRoute(
                                  ProductDetailClient(product: p)),
                            );
                          },
                          onQuickAdd: () => _quickAddToCart(p),
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(p['id']),
                          reorderBadge: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- "Pour vous" : fil d'activité mélangeant Communauté (ex-Mur)
          // + nouveaux produits (23/07). Masqué si vide (repli silencieux en cas
          // d'échec de chargement — voir _loadData). ---
          if (_activityFeed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('for_you'), style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WallTab()),
                      ),
                      child: const Text('Voir la Communauté'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 16.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _activityFeed.length,
                  itemBuilder: (context, index) {
                    final item = _activityFeed[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: SizedBox(
                        width: 55.w,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              if (item.isPost) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const WallTab()),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  productDetailRoute(ProductDetailClient(
                                      product: item.product!)),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(2.5.w),
                              child: item.isPost
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            width: 16.w,
                                            height: 16.w,
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: ((item.post!['image_url']
                                                        as String?) ??
                                                    '')
                                                .isEmpty
                                                ? Icon(
                                                    Icons.groups_outlined,
                                                    size: 20,
                                                    color: theme
                                                        .colorScheme.outline,
                                                  )
                                                : _productImage(
                                                    theme: theme,
                                                    imageUrl:
                                                        item.post!['image_url'],
                                                    enableHero: false,
                                                    tag:
                                                        'for-you-post-${item.post!['id']}',
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.groups_outlined,
                                                      size: 14,
                                                      color: theme.colorScheme
                                                          .primary),
                                                  SizedBox(width: 1.w),
                                                  Expanded(
                                                    child: Text(
                                                      PublicProfilesRepo
                                                          .displayName(item
                                                              .authorProfile),
                                                      style: theme.textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                (item.post!['content'] ?? '')
                                                        .toString()
                                                        .isNotEmpty
                                                    ? item.post!['content']
                                                    : 'Nouvelle publication'
                                                        ' dans la Communauté',
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            width: 16.w,
                                            height: 16.w,
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: ((item.product![
                                                            'image_url']
                                                        as String?) ??
                                                    '')
                                                .isEmpty
                                                ? Icon(
                                                    Icons
                                                        .inventory_2_outlined,
                                                    size: 20,
                                                    color: theme
                                                        .colorScheme.outline,
                                                  )
                                                : _productImage(
                                                    theme: theme,
                                                    imageUrl: item.product![
                                                        'image_url'],
                                                    enableHero: false,
                                                    tag:
                                                        'for-you-${item.product!['id']}',
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .fiber_new_outlined,
                                                      size: 14,
                                                      color: theme.colorScheme
                                                          .primary),
                                                  SizedBox(width: 1.w),
                                                  Text('Nouveau produit',
                                                      style: theme.textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                ],
                                              ),
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                item.product!['name'] ?? '',
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                              const Spacer(),
                                              Text(
                                                _currency.format((item
                                                            .product![
                                                        'price_detail'] as num?) ??
                                                    0),
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- Nouveautés Formation (Lot 4) : cours disponibles ajoutés
          // récemment — l'Académie a son propre onglet dans la barre du
          // bas, cette rangée sert juste de teaser/découvrabilité depuis
          // l'accueil. ---
          if (_recentFormationCourses.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nouveautés Formation',
                        style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AkoraFormationScreen()),
                      ),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 13.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _recentFormationCourses.length,
                  itemBuilder: (context, index) {
                    final course = _recentFormationCourses[index];
                    final category = (course['category'] ?? '').toString();
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AkoraFormationScreen(
                                initialCategory: category),
                          ),
                        ),
                        child: Container(
                          width: 45.w,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(iconForFormationCategory(category),
                                  color: Colors.white, size: 22),
                              const Spacer(),
                              Text(
                                course['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- Raccourci vers le catalogue complet (04/08) : la recherche,
          // les filtres et la grille paginée vivent maintenant dans leur
          // propre onglet (voir product_catalog_tab.dart) — Accueil se
          // contente d'un raccourci plutôt que de dupliquer cette UI. ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 2.h),
              child: OutlinedButton.icon(
                onPressed: widget.onOpenCatalog,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Voir tout le catalogue'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 4.h)),
        ],
      ),
    );
  }
}

class _PromoSlide {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imageUrl;

  const _PromoSlide(
      {required this.title,
      required this.subtitle,
      this.icon,
      this.imageUrl});
}

/// Un élément du fil d'activité "Pour vous" de l'Accueil (23/07) : soit une
/// publication publique de la Communauté, soit un produit récemment ajouté au
/// catalogue. Les deux sources sont mélangées et triées par date.
class _ActivityItem {
  final Map<String, dynamic>? post;
  final Map<String, dynamic>? authorProfile;
  final Map<String, dynamic>? product;
  final DateTime createdAt;

  _ActivityItem.post(this.post, this.authorProfile, this.createdAt)
      : product = null;
  _ActivityItem.product(this.product, this.createdAt)
      : post = null,
        authorProfile = null;

  bool get isPost => post != null;
}

/// Image produit avec loader/repli d'erreur, `Hero` optionnel (voir
/// `_ProductCard.enableHero`).
Widget _productImage({
  required ThemeData theme,
  required String imageUrl,
  required bool enableHero,
  required String tag,
}) {
  final image = Image.network(
    imageUrl,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stack) => Icon(
      Icons.inventory_2_outlined,
      size: 36,
      color: theme.colorScheme.outline,
    ),
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
  );
  return enableHero ? Hero(tag: tag, child: image) : image;
}

/// Fiche produit (image, prix, nom, favori, ajout rapide) — rendue
/// publique (04/08) pour être réutilisée par `product_catalog_tab.dart`
/// sans dupliquer ce widget.
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final VoidCallback onToggleFavorite;
  /// Un même produit peut apparaître à la fois dans la grille principale
  /// et dans "Vous recommandez souvent" (juste au-dessus) : deux `Hero`
  /// avec le même tag simultanément visibles sur le même écran cassent le
  /// vol (assertion Flutter ignorée en release — l'animation ne se
  /// déclenche simplement plus, sans erreur visible). Un seul des deux
  /// affichages doit donc porter le Hero ; la grille principale (entrée
  /// canonique) le garde, ce carrousel secondaire le désactive.
  final bool enableHero;

  /// Affiche un badge "Recommander" en bas à gauche de la photo — utilisé
  /// uniquement dans la section "Vous recommandez souvent" (catalog_tab).
  final bool reorderBadge;

  const ProductCard({
    required this.product,
    required this.currency,
    required this.isFavorite,
    required this.onTap,
    required this.onQuickAdd,
    required this.onToggleFavorite,
    this.enableHero = true,
    this.reorderBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = (product['category'] ?? '').toString();
    final imageUrl = (product['image_url'] as String?) ?? '';
    final stockQty = (product['stock_quantity'] as num?)?.toDouble();
    final stockThreshold = (product['low_stock_threshold'] as num?)?.toDouble();
    final outOfStock = stockQty != null && stockQty <= 0;
    final lowStock = !outOfStock &&
        stockQty != null &&
        stockThreshold != null &&
        stockQty <= stockThreshold;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: imageUrl.isEmpty
                            ? Icon(
                                Icons.inventory_2_outlined,
                                size: 36,
                                color: theme.colorScheme.outline,
                              )
                            : _productImage(
                                theme: theme,
                                imageUrl: imageUrl,
                                enableHero: enableHero,
                                tag: 'product-image-${product['id']}',
                              ),
                      ),
                    ),
                    if (category.isNotEmpty || outOfStock || lowStock)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category.isNotEmpty)
                              _Tag(label: category, theme: theme),
                            if (outOfStock || lowStock) ...[
                              if (category.isNotEmpty) const SizedBox(height: 4),
                              _StockBadge(outOfStock: outOfStock, theme: theme),
                            ],
                          ],
                        ),
                      ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Material(
                        color:
                            theme.colorScheme.surface.withValues(alpha: 0.85),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              size: 18,
                              color: isFavorite
                                  ? Colors.amber
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _QuickAddButton(onTap: onQuickAdd),
                    ),
                    if (reorderBadge)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onQuickAdd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay,
                                      size: 12,
                                      color: theme.colorScheme.onPrimary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Recommander',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                child: Text(
                  'Dès ${currency.format(product['price_detail'] ?? 0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Text(
                  product['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton "+" d'ajout rapide au panier — petit effet de rebond au tap,
/// pour donner un retour visuel immédiat que l'ajout a bien eu lieu
/// (auparavant seul un SnackBar discret confirmait l'action).
class _QuickAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _QuickAddButton({required this.onTap});

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: theme.colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.add,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final bool accent;

  const _Tag({required this.label, required this.theme, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Badge "Stock bas" / "Rupture de stock" (Lot 5) — même seuil que côté
/// admin (`stock_quantity <= low_stock_threshold`, voir alerts_center.dart),
/// purement informatif : ne bloque pas l'ajout au panier.
class _StockBadge extends StatelessWidget {
  final bool outOfStock;
  final ThemeData theme;

  const _StockBadge({required this.outOfStock, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        outOfStock ? 'Rupture de stock' : 'Stock bas',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rectangle qui pulse doucement (dégradé animé) — remplace le spinner
/// plein écran pendant le tout premier chargement du catalogue, pour
/// donner une impression de rapidité plutôt qu'un écran vide. Fait main
/// plutôt qu'un package tiers (`shimmer`) pour ne pas ajouter de
/// dépendance non testable sans SDK Flutter local.
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Aperçu de la mise en page de l'accueil pendant le premier chargement
/// (avant que `_loadData` n'ait de résultat) — reproduit approximativement
/// la forme de l'en-tête/bannière/grille de produits pour éviter un écran
/// vide ou un simple spinner central.
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          Row(
            children: [
              const _ShimmerBox(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(22)),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 40.w, height: 16),
                    SizedBox(height: 1.h),
                    _ShimmerBox(width: 28.w, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _ShimmerBox(
            width: double.infinity,
            height: 20.h,
            borderRadius: BorderRadius.circular(16),
          ),
          SizedBox(height: 2.5.h),
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: _ShimmerBox(
                  width: 15.w,
                  height: 15.w,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.5.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 0.72,
            children: List.generate(
              4,
              (i) => _ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
