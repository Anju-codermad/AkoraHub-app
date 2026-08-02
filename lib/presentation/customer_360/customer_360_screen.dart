import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/loyalty/loyalty_tiers.dart';
import '../../core/supabase/supabase_config.dart';

/// Fiche client 360° (CRM, Lot 1/5, 02/08) — regroupe pour un client
/// donné ce qui était jusqu'ici éparpillé entre plusieurs écrans admin :
/// commandes, devis, factures, avis produits, activité Communauté,
/// fidélité et adresses de livraison. Toutes les tables sources sont
/// déjà lisibles par le staff via leurs policies `..._select_own_or_staff`
/// existantes, sauf `delivery_addresses` (policy staff ajoutée en
/// Phase 60) et l'email du client (vit uniquement dans `auth.users`,
/// lu via la nouvelle fonction `staff_get_customer_email`).
///
/// Volontairement une agrégation en LECTURE de données existantes en
/// Lot 1 ; notes internes/étiquettes/relances (Lot 2, Phase 61) et
/// statut VIP/avantages accordés/note moyenne/signalements (Lot 3,
/// Phase 62) sont venus l'enrichir ensuite. Segmentation avancée
/// reste pour un lot suivant.
class Customer360Screen extends StatefulWidget {
  final String customerId;

  const Customer360Screen({super.key, required this.customerId});

  @override
  State<Customer360Screen> createState() => _Customer360ScreenState();
}

class _ActivityEvent {
  final DateTime date;
  final IconData icon;
  final String title;
  final String? subtitle;

  _ActivityEvent({
    required this.date,
    required this.icon,
    required this.title,
    this.subtitle,
  });
}

class _Customer360ScreenState extends State<Customer360Screen> {
  Map<String, dynamic>? _profile;
  String? _email;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _quotes = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _benefits = [];
  List<Map<String, dynamic>> _reportsFiled = [];
  List<Map<String, dynamic>> _reportsReceived = [];
  Map<String, String> _productNames = {};
  Map<String, String> _staffNames = {};
  bool _isLoading = true;
  String? _error;
  final _newNoteController = TextEditingController();
  final _newTagController = TextEditingController();
  final _newBenefitController = TextEditingController();
  bool _isSavingNote = false;
  bool _isSavingTags = false;
  bool _isSavingBenefit = false;
  bool _isSavingVip = false;

  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  final Map<String, String> _clientTypeLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };
  final Map<String, String> _orderStatusLabels = const {
    'recue': 'Reçue',
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'livree': 'Livrée',
    'annulee': 'Annulée',
  };
  final Map<String, String> _quoteStatusLabels = const {
    'en_attente': 'En attente',
    'envoye': 'Envoyé',
    'accepte': 'Accepté',
    'refuse': 'Refusé',
    'expire': 'Expiré',
  };
  final Map<String, String> _reportStatusLabels = const {
    'en_attente': 'En attente',
    'traite': 'Traité',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newNoteController.dispose();
    _newTagController.dispose();
    _newBenefitController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('id', widget.customerId)
            .maybeSingle(),
        SupabaseConfig.client
            .from('orders')
            .select()
            .eq('customer_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('quotes')
            .select()
            .eq('customer_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('invoices')
            .select()
            .eq('customer_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('product_reviews')
            .select()
            .eq('author_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('posts')
            .select()
            .eq('author_id', widget.customerId)
            .order('created_at', ascending: false)
            .limit(20),
        SupabaseConfig.client
            .from('delivery_addresses')
            .select()
            .eq('customer_id', widget.customerId)
            .order('is_default', ascending: false),
        SupabaseConfig.client
            .rpc('staff_get_customer_email', params: {
          'customer_id': widget.customerId,
        }).catchError((_) => null),
        SupabaseConfig.client
            .from('customer_notes')
            .select()
            .eq('customer_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('conversations')
            .select()
            .eq('customer_id', widget.customerId)
            .maybeSingle(),
        SupabaseConfig.client
            .from('customer_benefits')
            .select()
            .eq('customer_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('post_reports')
            .select()
            .eq('reporter_id', widget.customerId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('post_reports')
            .select('*, posts!inner(content, author_id)')
            .eq('posts.author_id', widget.customerId)
            .order('created_at', ascending: false),
      ]);

      final reviews = List<Map<String, dynamic>>.from(results[4]);
      final productIds =
          reviews.map((r) => r['product_id'] as String?).whereType<String>().toSet();
      var productNames = <String, String>{};
      if (productIds.isNotEmpty) {
        try {
          final products = await SupabaseConfig.client
              .from('products')
              .select('id, name')
              .inFilter('id', productIds.toList());
          productNames = {
            for (final p in products) p['id'] as String: p['name'] as String
          };
        } catch (_) {}
      }

      final notes = List<Map<String, dynamic>>.from(results[8]);
      final benefits = List<Map<String, dynamic>>.from(results[10]);
      var staffNames = <String, String>{};
      final staffIds = {
        ...notes.map((n) => n['author_id'] as String?).whereType<String>(),
        ...benefits.map((b) => b['granted_by'] as String?).whereType<String>(),
      };
      if (staffIds.isNotEmpty) {
        try {
          final authors = await SupabaseConfig.client
              .from('profiles')
              .select('id, full_name, company_name')
              .inFilter('id', staffIds.toList());
          staffNames = {
            for (final a in authors)
              a['id'] as String:
                  (a['company_name'] ?? a['full_name'] ?? 'Staff') as String,
          };
        } catch (_) {}
      }

      final conversation = results[9] as Map<String, dynamic>?;
      var messages = <Map<String, dynamic>>[];
      if (conversation != null) {
        try {
          messages = List<Map<String, dynamic>>.from(await SupabaseConfig
              .client
              .from('messages')
              .select()
              .eq('conversation_id', conversation['id'])
              .order('created_at', ascending: false)
              .limit(50));
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _orders = List<Map<String, dynamic>>.from(results[1]);
        _quotes = List<Map<String, dynamic>>.from(results[2]);
        _invoices = List<Map<String, dynamic>>.from(results[3]);
        _reviews = reviews;
        _posts = List<Map<String, dynamic>>.from(results[5]);
        _addresses = List<Map<String, dynamic>>.from(results[6]);
        _email = results[7] as String?;
        _productNames = productNames;
        _notes = notes;
        _staffNames = staffNames;
        _messages = messages;
        _benefits = benefits;
        _reportsFiled = List<Map<String, dynamic>>.from(results[11]);
        _reportsReceived = List<Map<String, dynamic>>.from(results[12]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger la fiche client.';
      });
    }
  }

  num get _lifetimeValue => _orders
      .where((o) => o['status'] != 'annulee')
      .fold<num>(0, (sum, o) => sum + ((o['total_amount'] as num?) ?? 0));

  List<_ActivityEvent> get _timeline {
    final events = <_ActivityEvent>[];
    for (final o in _orders) {
      events.add(_ActivityEvent(
        date: DateTime.parse(o['created_at']),
        icon: Icons.shopping_bag_outlined,
        title: 'Commande ${o['order_number'] ?? ''}',
        subtitle:
            '${_currency.format(o['total_amount'] ?? 0)} · ${_orderStatusLabels[o['status']] ?? o['status']}',
      ));
    }
    for (final q in _quotes) {
      events.add(_ActivityEvent(
        date: DateTime.parse(q['created_at']),
        icon: Icons.request_quote_outlined,
        title: 'Devis ${q['quote_number'] ?? ''}',
        subtitle:
            '${_currency.format(q['total_amount'] ?? 0)} · ${_quoteStatusLabels[q['status']] ?? q['status']}',
      ));
    }
    for (final i in _invoices) {
      events.add(_ActivityEvent(
        date: DateTime.parse(i['created_at']),
        icon: Icons.receipt_long_outlined,
        title: 'Facture ${i['invoice_number'] ?? ''}',
        subtitle: _currency.format(i['total_amount'] ?? 0),
      ));
    }
    for (final r in _reviews) {
      final stars = '★' * ((r['rating'] as num?)?.toInt() ?? 0);
      events.add(_ActivityEvent(
        date: DateTime.parse(r['created_at']),
        icon: Icons.star_outline,
        title: 'Avis $stars sur ${_productNames[r['product_id']] ?? 'un produit'}',
        subtitle: (r['comment'] as String?)?.isNotEmpty == true
            ? r['comment'] as String
            : null,
      ));
    }
    for (final p in _posts) {
      final content = (p['content'] as String? ?? '').trim();
      events.add(_ActivityEvent(
        date: DateTime.parse(p['created_at']),
        icon: Icons.forum_outlined,
        title: 'Publication Communauté',
        subtitle: content.isEmpty
            ? null
            : (content.length > 80 ? '${content.substring(0, 80)}…' : content),
      ));
    }
    for (final m in _messages) {
      final content = (m['content'] as String? ?? '').trim();
      events.add(_ActivityEvent(
        date: DateTime.parse(m['created_at']),
        icon: Icons.chat_bubble_outline,
        title: m['sender_role'] == 'staff'
            ? 'Message envoyé par le staff'
            : 'Message du client',
        subtitle: content.length > 80 ? '${content.substring(0, 80)}…' : content,
      ));
    }
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  /// Devis acceptés sans commande visible du même client créée après —
  /// approximation (aucun lien formel `quotes`/`orders` n'existe dans le
  /// schéma, voir supabase/phase61_patch_crm_lot2_a.sql), donc affichée
  /// comme une alerte à vérifier manuellement, pas une certitude.
  List<Map<String, dynamic>> get _staleAcceptedQuotes {
    return _quotes.where((q) {
      if (q['status'] != 'accepte') return false;
      final quoteDate = DateTime.parse(q['created_at']);
      return !_orders.any((o) =>
          DateTime.parse(o['created_at']).isAfter(quoteDate) ||
          DateTime.parse(o['created_at']).isAtSameMomentAs(quoteDate));
    }).toList();
  }

  double? get _averageRating {
    if (_reviews.isEmpty) return null;
    final sum = _reviews.fold<num>(
        0, (s, r) => s + ((r['rating'] as num?) ?? 0));
    return sum / _reviews.length;
  }

  Future<void> _toggleVip(bool value) async {
    if (_profile == null) return;
    setState(() => _isSavingVip = true);
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'is_vip': value}).eq('id', widget.customerId);
      if (!mounted) return;
      setState(() => _profile = {..._profile!, 'is_vip': value});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier le statut VIP.')));
    } finally {
      if (mounted) setState(() => _isSavingVip = false);
    }
  }

  Future<void> _addBenefit() async {
    final description = _newBenefitController.text.trim();
    if (description.isEmpty) return;
    final grantedBy = SupabaseConfig.client.auth.currentUser?.id;
    setState(() => _isSavingBenefit = true);
    try {
      await SupabaseConfig.client.from('customer_benefits').insert({
        'customer_id': widget.customerId,
        'granted_by': grantedBy,
        'description': description,
      });
      _newBenefitController.clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ajouter cet avantage.')));
    } finally {
      if (mounted) setState(() => _isSavingBenefit = false);
    }
  }

  Future<void> _addNote() async {
    final content = _newNoteController.text.trim();
    if (content.isEmpty) return;
    final authorId = SupabaseConfig.client.auth.currentUser?.id;
    setState(() => _isSavingNote = true);
    try {
      await SupabaseConfig.client.from('customer_notes').insert({
        'customer_id': widget.customerId,
        'author_id': authorId,
        'content': content,
      });
      _newNoteController.clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ajouter la note.')));
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  Future<void> _addTag() async {
    final tag = _newTagController.text.trim();
    if (tag.isEmpty || _profile == null) return;
    final tags = List<String>.from(_profile!['tags'] ?? []);
    if (tags.contains(tag)) {
      _newTagController.clear();
      return;
    }
    tags.add(tag);
    await _saveTags(tags);
    _newTagController.clear();
  }

  Future<void> _removeTag(String tag) async {
    if (_profile == null) return;
    final tags = List<String>.from(_profile!['tags'] ?? [])..remove(tag);
    await _saveTags(tags);
  }

  Future<void> _saveTags(List<String> tags) async {
    setState(() => _isSavingTags = true);
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'tags': tags}).eq('id', widget.customerId);
      if (!mounted) return;
      setState(() => _profile = {..._profile!, 'tags': tags});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier les étiquettes.')));
    } finally {
      if (mounted) setState(() => _isSavingTags = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile;
    final timeline = _timeline;

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche client')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || profile == null
              ? Center(child: Text(_error ?? 'Client introuvable.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      _buildHeader(theme, profile),
                      SizedBox(height: 1.5.h),
                      _buildTags(theme, profile),
                      SizedBox(height: 2.h),
                      if (_staleAcceptedQuotes.isNotEmpty) ...[
                        Card(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.4),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_outlined,
                                    color: theme.colorScheme.error),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    '${_staleAcceptedQuotes.length} devis accepté(s) '
                                    'sans commande visible pour ce client : '
                                    '${_staleAcceptedQuotes.map((q) => q['quote_number']).join(', ')}. '
                                    'À vérifier manuellement — approximation, pas certain.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],
                      _buildStats(theme),
                      SizedBox(height: 2.h),
                      Text('Notes internes', style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final n in _notes) ...[
                                Text(
                                  _staffNames[n['author_id']] ?? 'Staff',
                                  style: theme.textTheme.labelMedium,
                                ),
                                Text(n['content'] ?? ''),
                                Text(
                                  _dateFormat
                                      .format(DateTime.parse(n['created_at'])),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                                SizedBox(height: 1.h),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newNoteController,
                                      decoration: const InputDecoration(
                                        hintText: 'Ajouter une note interne…',
                                        isDense: true,
                                      ),
                                      minLines: 1,
                                      maxLines: 3,
                                    ),
                                  ),
                                  IconButton(
                                    icon: _isSavingNote
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send_outlined),
                                    onPressed: _isSavingNote ? null : _addNote,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text('Avantages accordés',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_benefits.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1.h),
                                  child: Text(
                                    'Aucun avantage accordé pour l\'instant.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              for (final b in _benefits) ...[
                                Text(
                                  _staffNames[b['granted_by']] ?? 'Staff',
                                  style: theme.textTheme.labelMedium,
                                ),
                                Text(b['description'] ?? ''),
                                Text(
                                  _dateFormat
                                      .format(DateTime.parse(b['created_at'])),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                                SizedBox(height: 1.h),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newBenefitController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ex : remise 10% offerte, livraison gratuite…',
                                        isDense: true,
                                      ),
                                      minLines: 1,
                                      maxLines: 3,
                                    ),
                                  ),
                                  IconButton(
                                    icon: _isSavingBenefit
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.card_giftcard),
                                    onPressed:
                                        _isSavingBenefit ? null : _addBenefit,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_reportsFiled.isNotEmpty ||
                          _reportsReceived.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text('Signalements liés au client',
                            style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        Card(
                          child: Column(
                            children: [
                              for (final r in _reportsReceived)
                                ListTile(
                                  leading: Icon(Icons.flag_outlined,
                                      color: theme.colorScheme.error),
                                  title: const Text(
                                      'Publication de ce client signalée'),
                                  subtitle: Text(
                                      '${r['reason'] ?? ''} · ${_reportStatusLabels[r['status']] ?? r['status'] ?? ''}'),
                                  trailing: Text(
                                    _dateFormat.format(
                                        DateTime.parse(r['created_at'])),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              for (final r in _reportsFiled)
                                ListTile(
                                  leading:
                                      const Icon(Icons.outlined_flag),
                                  title: const Text(
                                      'Signalement déposé par ce client'),
                                  subtitle: Text(
                                      '${r['reason'] ?? ''} · ${_reportStatusLabels[r['status']] ?? r['status'] ?? ''}'),
                                  trailing: Text(
                                    _dateFormat.format(
                                        DateTime.parse(r['created_at'])),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      if (_addresses.isNotEmpty) ...[
                        Text('Adresses de livraison',
                            style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        Card(
                          child: Column(
                            children: [
                              for (final a in _addresses)
                                ListTile(
                                  leading: Icon(
                                    a['is_default'] == true
                                        ? Icons.push_pin
                                        : Icons.location_on_outlined,
                                  ),
                                  title: Text(a['label'] ?? ''),
                                  subtitle: Text(a['address'] ?? ''),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],
                      Text('Chronologie d\'activité',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      if (timeline.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Center(
                            child: Text('Aucune activité pour ce client.',
                                style: theme.textTheme.bodyMedium),
                          ),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < timeline.length; i++) ...[
                                ListTile(
                                  leading: Icon(timeline[i].icon,
                                      color: theme.colorScheme.primary),
                                  title: Text(timeline[i].title),
                                  subtitle: timeline[i].subtitle != null
                                      ? Text(timeline[i].subtitle!)
                                      : null,
                                  trailing: Text(
                                    _dateFormat.format(timeline[i].date),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                if (i != timeline.length - 1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ThemeData theme, Map<String, dynamic> profile) {
    final points = (profile['loyalty_points'] as num?)?.toInt() ?? 0;
    final tier = currentLoyaltyTier(points);
    final memberSince = profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'])
        : null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (profile['avatar_url'] as String?)
                              ?.isNotEmpty ==
                          true
                      ? NetworkImage(profile['avatar_url'] as String)
                      : null,
                  child: (profile['avatar_url'] as String?)?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['company_name'] ??
                            profile['full_name'] ??
                            'Client',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (profile['company_name'] != null &&
                          profile['full_name'] != null)
                        Text(profile['full_name'],
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile['is_vip'] == true)
                  Chip(
                    avatar: const Icon(Icons.workspace_premium, size: 16),
                    label: const Text('VIP'),
                    backgroundColor: Colors.amber.withValues(alpha: 0.25),
                    visualDensity: VisualDensity.compact,
                  ),
                if (profile['client_type'] != null)
                  Chip(
                    label: Text(
                        _clientTypeLabels[profile['client_type']] ??
                            profile['client_type']),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: const Icon(Icons.emoji_events, size: 16),
                  label: Text('${tier.name} · $points pts'),
                  backgroundColor: tier.color.withValues(alpha: 0.15),
                  visualDensity: VisualDensity.compact,
                ),
                if (_averageRating != null)
                  Chip(
                    avatar: const Icon(Icons.star, size: 16),
                    label: Text(
                        '${_averageRating!.toStringAsFixed(1)} ★ (${_reviews.length} avis)'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Text('Client VIP', style: theme.textTheme.bodyMedium),
                const Spacer(),
                _isSavingVip
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: profile['is_vip'] == true,
                        onChanged: _toggleVip,
                      ),
              ],
            ),
            SizedBox(height: 1.5.h),
            if ((profile['phone'] as String?)?.isNotEmpty == true)
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16),
                  SizedBox(width: 2.w),
                  Text(profile['phone']),
                ],
              ),
            if (_email != null) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(child: Text(_email!)),
                ],
              ),
            ],
            if (memberSince != null) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  SizedBox(width: 2.w),
                  Text('Client depuis le ${_dateFormat.format(memberSince)}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTags(ThemeData theme, Map<String, dynamic> profile) {
    final tags = List<String>.from(profile['tags'] ?? []);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in tags)
          Chip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
            onDeleted: _isSavingTags ? null : () => _removeTag(tag),
          ),
        SizedBox(
          width: 40.w,
          child: TextField(
            controller: _newTagController,
            enabled: !_isSavingTags,
            decoration: const InputDecoration(
              hintText: '+ Étiquette',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addTag(),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    final lastOrderDate = _orders.isNotEmpty
        ? DateTime.tryParse(_orders.first['created_at'])
        : null;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.payments_outlined,
            label: 'Valeur totale',
            value: _currency.format(_lifetimeValue),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Commandes',
            value: '${_orders.length}',
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _StatCard(
            icon: Icons.event_outlined,
            label: 'Dernière commande',
            value: lastOrderDate != null
                ? _dateFormat.format(lastOrderDate)
                : '—',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            SizedBox(height: 0.5.h),
            Text(value,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
