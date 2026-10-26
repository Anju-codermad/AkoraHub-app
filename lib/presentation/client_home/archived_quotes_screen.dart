import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Devis masqués par le client lui-même (voir `_hideQuote` dans
/// orders_tab.dart, phase264_patch_quote_archiving.sql) — jamais
/// supprimés en base, juste retirés de la liste principale. Même
/// principe que `ArchivedOrdersScreen` pour les commandes : aucune
/// perte de données, entièrement réversible.
class ArchivedQuotesScreen extends StatefulWidget {
  const ArchivedQuotesScreen({super.key});

  @override
  State<ArchivedQuotesScreen> createState() => _ArchivedQuotesScreenState();
}

class _ArchivedQuotesScreenState extends State<ArchivedQuotesScreen> {
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
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
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
          .select()
          .eq('customer_id', userId)
          .eq('hidden_by_customer', true)
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
      await SupabaseConfig.client.rpc('set_quote_hidden', params: {
        'p_quote_id': quote['id'],
        'p_hidden': false,
      });
      if (!mounted) return;
      setState(() => _quotes.removeWhere((q) => q['id'] == quote['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis réaffiché dans votre liste.')),
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
                          return Card(
                            child: ListTile(
                              title: Text(quote['quote_number'] ?? ''),
                              subtitle: Text(_currency
                                  .format(quote['total_amount'] ?? 0)),
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
