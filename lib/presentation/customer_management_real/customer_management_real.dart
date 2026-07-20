import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Liste réelle des clients (comptes créés via l'inscription), avec leur
/// type (Hôtel/Hôpital/Entreprise/Particulier) et coordonnées.
class CustomerManagementReal extends StatefulWidget {
  const CustomerManagementReal({super.key});

  @override
  State<CustomerManagementReal> createState() =>
      _CustomerManagementRealState();
}

class _CustomerManagementRealState extends State<CustomerManagementReal> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _error;
  String _typeFilter = 'tous';

  final Map<String, String> _typeLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
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
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('role', 'client')
          .order('created_at', ascending: false);
      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les clients.';
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_typeFilter == 'tous') return _customers;
    return _customers.where((c) => c['client_type'] == _typeFilter).toList();
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel;
      case 'hopital':
        return Icons.local_hospital;
      case 'entreprise':
        return Icons.business_center;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: _typeFilter == 'tous',
                            onSelected: (_) =>
                                setState(() => _typeFilter = 'tous'),
                          ),
                          SizedBox(width: 2.w),
                          ..._typeLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _typeFilter == entry.key,
                                  onSelected: (_) =>
                                      setState(() => _typeFilter = entry.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucun client.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final c = _filtered[index];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(
                                            _iconForType(c['client_type'])),
                                      ),
                                      title: Text(c['company_name'] ??
                                          c['full_name'] ??
                                          'Client'),
                                      subtitle: Text(
                                        [
                                          _typeLabels[c['client_type']] ?? '',
                                          if ((c['phone'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            c['phone'],
                                        ].where((s) => s != '').join(' · '),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
