import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Devis masqués par un membre du staff (voir `_hideQuote` dans
/// quotes_management.dart, phase271_patch_quote_staff_hide_delete.sql)
/// — jamais supprimés en base, juste retirés de la liste principale de
/// gestion. Distinct des devis archivés côté client (`hidden_by_customer`,
/// archived_quotes_screen.dart) : masquer un devis ici ne le masque pas
/// pour le client, et inversement. Même structure que
/// archived_orders_staff_screen.dart.
class ArchivedQuotesStaffScreen extends StatefulWidget {
  const ArchivedQuotesStaffScreen({super.key});

  @override
  State<ArchivedQuotesStaffScreen> createState() =>
      _ArchivedQuotesStaffScreenState();
}

class _ArchivedQuotesStaffScreenState
    extends State<ArchivedQuotesStaffScreen> {
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quotes = await SupabaseConfig.client
          .from('quotes')
          .select('*, profiles(full_name, company_name)')
          .eq('hidden_by_staff', true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _quotes = List<Map<String, dynamic>>.from(quotes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les devis archivés.';
      });
    }
  }

  Future<void> _restore(Map<String, dynamic> quote) async {
    try {
      await SupabaseConfig.client
          .from('quotes')
          .update({'hidden_by_staff': false}).eq('id', quote['id']);
      if (!mounted) return;
      setState(() => _quotes.removeWhere((q) => q['id'] == quote['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis réaffiché.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de réafficher ce devis.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devis archivés')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _quotes.isEmpty
                  ? const Center(child: Text('Aucun devis archivé.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _quotes.length,
                        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          final customer = quote['profiles'];
                          final customerName = customer != null
                              ? (customer['company_name'] ??
                                  customer['full_name'] ??
                                  'Client')
                              : 'Client';
                          return Card(
                            child: ListTile(
                              title: Text(quote['quote_number'] ?? ''),
                              subtitle: Text(
                                  '$customerName · ${_currency.format(quote['total_amount'] ?? 0)}'),
                              trailing: TextButton.icon(
                                onPressed: () => _restore(quote),
                                icon: const Icon(Icons.unarchive_outlined,
                                    size: 18),
                                label: const Text('Réafficher'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
