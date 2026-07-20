import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion de l'équipe : promeut un utilisateur inscrit vers un rôle
/// (Commercial / Production / Comptable / Admin) et l'assigne à un ou
/// plusieurs piliers d'entreprise.
///
/// Note : pour éviter d'avoir besoin d'une clé d'administration côté app
/// (dangereuse à embarquer dans un APK), la personne doit d'abord créer
/// un compte normal (écran d'inscription), puis un Admin la retrouve ici
/// par email et lui attribue son rôle.
class StaffManagement extends StatefulWidget {
  const StaffManagement({super.key});

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _businessUnits = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, String>> _roles = const [
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'commercial', 'label': 'Commercial'},
    {'value': 'production', 'label': 'Production'},
    {'value': 'comptable', 'label': 'Comptable'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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
      final staffData = await SupabaseConfig.client
          .from('profiles')
          .select()
          .neq('role', 'client')
          .order('created_at');
      final unitsData =
          await SupabaseConfig.client.from('business_units').select();

      setState(() {
        _staff = List<Map<String, dynamic>>.from(staffData);
        _businessUnits = List<Map<String, dynamic>>.from(unitsData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger l\'équipe.';
      });
    }
  }

  Future<void> _promoteByEmail() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promouvoir un membre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'La personne doit déjà avoir créé un compte via l\'écran d\'inscription. Entrez son email pour la retrouver.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    // On ne peut pas interroger auth.users directement avec la clé publique ;
    // on retrouve le profil via une fonction RPC dédiée côté base de données.
    try {
      final result = await SupabaseConfig.client
          .rpc('find_profile_by_email', params: {'search_email': email});

      if (result == null || (result as List).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucun compte trouvé avec cet email.')),
        );
        return;
      }

      final profile = Map<String, dynamic>.from(result.first);
      if (!mounted) return;
      await _showRoleAssignDialog(profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Recherche indisponible. Vérifiez que la fonction find_profile_by_email existe.')),
      );
    }
  }

  Future<void> _showRoleAssignDialog(Map<String, dynamic> profile) async {
    String selectedRole =
        (profile['role'] == 'client' ? 'commercial' : profile['role']) ??
            'commercial';
    final Set<String> selectedUnits =
        Set<String>.from((profile['business_unit_ids'] as List?) ?? []);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(profile['full_name'] ?? 'Membre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rôle'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _roles.map((r) {
                    return ChoiceChip(
                      label: Text(r['label']!),
                      selected: selectedRole == r['value'],
                      onSelected: (_) {
                        setDialogState(() => selectedRole = r['value']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Piliers assignés'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _businessUnits.map((u) {
                    final id = u['id'] as String;
                    return FilterChip(
                      label: Text(u['name']),
                      selected: selectedUnits.contains(id),
                      onSelected: (sel) {
                        setDialogState(() {
                          if (sel) {
                            selectedUnits.add(id);
                          } else {
                            selectedUnits.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await SupabaseConfig.client.from('profiles').update({
                    'role': selectedRole,
                    'business_unit_ids': selectedUnits.toList(),
                  }).eq('id', profile['id']);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de la mise à jour.')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  String _initial(dynamic name) {
    final s = (name ?? '?').toString().trim();
    return s.isEmpty ? '?' : s[0].toUpperCase();
  }

  String _roleLabel(String role) {
    return _roles.firstWhere(
      (r) => r['value'] == role,
      orElse: () => {'label': role},
    )['label']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Équipe & rôles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promoteByEmail,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Promouvoir'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _staff.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucun membre d\'équipe pour le moment.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _staff.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final member = _staff[index];
                            final units = List<String>.from(
                                member['business_unit_ids'] ?? []);
                            return Card(
                              child: ListTile(
                                title: Text(member['full_name'] ?? 'Sans nom'),
                                subtitle: Text(
                                  '${_roleLabel(member['role'])} · ${units.length} pilier(s)',
                                ),
                                leading: CircleAvatar(
                                  child: Text(
                                    _initial(member['full_name']),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showRoleAssignDialog(member),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
