import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/payment/payment_methods.dart';
import '../../core/supabase/supabase_config.dart';

/// Une ligne de commande en cours de saisie (même logique Gros/Détail que
/// `CartItem`, core/providers/cart_provider.dart — pas réutilisé tel quel
/// car ce panier-ci est propre à cet écran, pas celui du compte staff
/// connecté).
class _ManualOrderItem {
  final String productId;
  final String? variantId;
  final String name;
  final double priceDetail;
  final double priceGros;
  final int grosThresholdQty;
  int quantity;

  _ManualOrderItem({
    required this.productId,
    this.variantId,
    required this.name,
    required this.priceDetail,
    required this.priceGros,
    required this.grosThresholdQty,
    this.quantity = 1,
  });

  double get unitPrice => quantity >= grosThresholdQty ? priceGros : priceDetail;
  bool get isGrosPrice => quantity >= grosThresholdQty;
  double get total => unitPrice * quantity;
  String get key => variantId ?? productId;
}

/// Saisie manuelle d'une commande passée par WhatsApp ou directement
/// (pas via l'app) pour un client qui a déjà un compte AkoraHub — demande
/// explicite (27/10) : ces commandes n'apparaissaient nulle part, le
/// client ne pouvait donc pas les suivre dans l'onglet Commandes comme
/// pour une commande passée depuis l'app. Mêmes tables (`orders`/
/// `order_items`) et mêmes statuts que order_management_real.dart — une
/// fois créée, cette commande se comporte exactement comme les autres
/// (suivi, changement de statut...), voir supabase/phase267_patch_manual_orders.sql.
class CreateManualOrderScreen extends StatefulWidget {
  const CreateManualOrderScreen({super.key});

  @override
  State<CreateManualOrderScreen> createState() =>
      _CreateManualOrderScreenState();
}

class _CreateManualOrderScreenState extends State<CreateManualOrderScreen> {
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  Map<String, dynamic>? _selectedClient;
  final _clientSearchController = TextEditingController();
  List<Map<String, dynamic>> _clientResults = [];
  bool _searchingClients = false;
  Timer? _clientDebounce;

  final _productSearchController = TextEditingController();
  List<Map<String, dynamic>> _productResults = [];
  bool _searchingProducts = false;
  Timer? _productDebounce;

  final List<_ManualOrderItem> _items = [];
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.paiementLivraison;
  bool _isSaving = false;

  @override
  void dispose() {
    _clientDebounce?.cancel();
    _productDebounce?.cancel();
    _clientSearchController.dispose();
    _productSearchController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onClientQueryChanged(String value) {
    _clientDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _clientResults = []);
      return;
    }
    _clientDebounce =
        Timer(const Duration(milliseconds: 350), () => _searchClients(value));
  }

  Future<void> _searchClients(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searchingClients = true);
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, company_name, phone, avatar_url')
          .eq('role', 'client')
          .or('full_name.ilike.%$q%,company_name.ilike.%$q%,phone.ilike.%$q%')
          .limit(15);
      if (!mounted) return;
      setState(() {
        _clientResults = List<Map<String, dynamic>>.from(data);
        _searchingClients = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingClients = false);
    }
  }

  void _onProductQueryChanged(String value) {
    _productDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _productResults = []);
      return;
    }
    _productDebounce = Timer(
        const Duration(milliseconds: 350), () => _searchProducts(value));
  }

  Future<void> _searchProducts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searchingProducts = true);
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select(
              'id, name, price_detail, price_gros, gros_threshold_qty, image_url, '
              'product_variants(id, price_detail, price_gros, gros_threshold_qty, '
              'formats(name), parfums(name))')
          .eq('visibility', true)
          .ilike('name', '%$q%')
          .limit(20);
      if (!mounted) return;
      setState(() {
        _productResults = List<Map<String, dynamic>>.from(data);
        _searchingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingProducts = false);
    }
  }

  void _addItem(_ManualOrderItem item) {
    setState(() {
      final index = _items.indexWhere((i) => i.key == item.key);
      if (index >= 0) {
        _items[index].quantity += item.quantity;
      } else {
        _items.add(item);
      }
    });
  }

  double get _total => _items.fold(0, (sum, item) => sum + item.total);

  Future<void> _pickProduct(Map<String, dynamic> product) async {
    final variants =
        List<Map<String, dynamic>>.from(product['product_variants'] ?? []);
    if (variants.isEmpty) {
      final quantity = await _askQuantity();
      if (quantity == null || quantity <= 0) return;
      _addItem(_ManualOrderItem(
        productId: product['id'],
        name: product['name'] ?? '',
        priceDetail: (product['price_detail'] ?? 0).toDouble(),
        priceGros: (product['price_gros'] ?? 0).toDouble(),
        grosThresholdQty: (product['gros_threshold_qty'] ?? 10) as int,
        quantity: quantity,
      ));
      return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product['name'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 1.5.h),
              const Text('Choisir le format/parfum :'),
              SizedBox(height: 1.h),
              ...variants.map((v) {
                final format = v['formats']?['name'] as String?;
                final parfum = v['parfums']?['name'] as String?;
                final label = [format, parfum]
                    .where((s) => s != null && s.trim().isNotEmpty)
                    .join(' — ');
                return ListTile(
                  title: Text(label.isEmpty ? 'Standard' : label),
                  subtitle: Text(_currency
                      .format((v['price_detail'] ?? 0).toDouble())),
                  onTap: () => Navigator.pop(context, v),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    final quantity = await _askQuantity();
    if (quantity == null || quantity <= 0) return;
    _addItem(_ManualOrderItem(
      productId: product['id'],
      variantId: picked['id'],
      name: product['name'] ?? '',
      priceDetail: (picked['price_detail'] ?? 0).toDouble(),
      priceGros: (picked['price_gros'] ?? 0).toDouble(),
      grosThresholdQty: (picked['gros_threshold_qty'] ?? 10) as int,
      quantity: quantity,
    ));
  }

  Future<int?> _askQuantity() async {
    final controller = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quantité'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedClient == null || _items.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final staffId = SupabaseConfig.client.auth.currentUser?.id;
      final now = DateTime.now();
      final orderNumber =
          'CMD-${DateFormat('yyyyMM').format(now)}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final order = await SupabaseConfig.client
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'customer_id': _selectedClient!['id'],
            'total_amount': _total,
            'delivery_address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'payment_method': _paymentMethod.id,
            'created_by_staff': staffId,
            'manual_note': _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          })
          .select()
          .single();

      await SupabaseConfig.client.from('order_items').insert(
            _items
                .map((item) => {
                      'order_id': order['id'],
                      'product_id': item.productId,
                      'variant_id': item.variantId,
                      'product_name': item.name,
                      'quantity': item.quantity,
                      'unit_price': item.unitPrice,
                      'is_gros_price': item.isGrosPrice,
                    })
                .toList(),
          );

      if (!mounted) return;
      // Pas de SnackBar ici : le contexte de cet écran n'est plus valide
      // une fois `pop` appelé. La confirmation est affichée par l'écran
      // appelant (order_management_real.dart) à la réception de `true`.
      Navigator.pop(context, orderNumber);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de créer cette commande.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande (hors app)')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Text('1. Client', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          if (_selectedClient == null) ...[
            TextField(
              controller: _clientSearchController,
              onChanged: _onClientQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Nom, entreprise ou téléphone…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            if (_searchingClients)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._clientResults.map((c) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: c['avatar_url'] != null
                            ? NetworkImage(c['avatar_url'])
                            : null,
                        child: c['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(c['company_name'] ??
                          c['full_name'] ??
                          'Client'),
                      subtitle: Text(c['phone'] ?? ''),
                      onTap: () => setState(() => _selectedClient = c),
                    ),
                  )),
          ] else
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(_selectedClient!['company_name'] ??
                    _selectedClient!['full_name'] ??
                    'Client'),
                subtitle: Text(_selectedClient!['phone'] ?? ''),
                trailing: TextButton(
                  onPressed: () => setState(() {
                    _selectedClient = null;
                    _clientResults = [];
                    _clientSearchController.clear();
                  }),
                  child: const Text('Changer'),
                ),
              ),
            ),
          SizedBox(height: 2.5.h),
          Text('2. Produits', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          TextField(
            controller: _productSearchController,
            onChanged: _onProductQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Rechercher un produit…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          if (_searchingProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._productResults.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(p['name'] ?? ''),
                    subtitle:
                        Text(_currency.format((p['price_detail'] ?? 0))),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _pickProduct(p),
                  ),
                )),
          if (_items.isNotEmpty) ...[
            SizedBox(height: 2.5.h),
            Text('Articles ajoutés', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            ..._items.map((item) => Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.quantity} × ${_currency.format(item.unitPrice)}'
                        '${item.isGrosPrice ? ' (prix Gros)' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currency.format(item.total)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _items.remove(item)),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          SizedBox(height: 2.5.h),
          Text('3. Détails', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse de livraison (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 1.5.h),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Mode de paiement',
              border: OutlineInputBorder(),
            ),
            items: PaymentMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (m) {
              if (m != null) setState(() => _paymentMethod = m);
            },
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note interne (ex. "Commande WhatsApp du 27/10")',
              helperText: 'Visible uniquement par le staff, jamais par le client.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.5.h),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                  Text(_currency.format(_total),
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  (_selectedClient != null && _items.isNotEmpty && !_isSaving)
                      ? _submit
                      : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer la commande'),
            ),
          ),
        ],
      ),
    );
  }
}
