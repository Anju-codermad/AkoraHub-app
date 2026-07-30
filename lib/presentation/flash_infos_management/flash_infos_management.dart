import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion des "Flash infos" (annonces courtes) affichées sur l'Accueil
/// client. Strictement réservé à l'Admin (RLS côté serveur : voir
/// supabase/phase26_patch_flash_infos.sql) — texte seul, pas de photo,
/// pensé pour publier une annonce rapidement (contrairement à la bannière
/// hero qui demande une image).
class FlashInfosManagement extends StatefulWidget {
  const FlashInfosManagement({super.key});

  @override
  State<FlashInfosManagement> createState() => _FlashInfosManagementState();
}

class _FlashInfosManagementState extends State<FlashInfosManagement> {
  List<Map<String, dynamic>> _infos = [];
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
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
      final data = await SupabaseConfig.client
          .from('flash_infos')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _infos = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.code == '42501'
            ? 'Accès réservé à l\'Admin.'
            : 'Impossible de charger les flash infos.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les flash infos.';
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> info) async {
    try {
      await SupabaseConfig.client
          .from('flash_infos')
          .update({'active': !(info['active'] as bool? ?? true)}).eq(
              'id', info['id']);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier le statut.')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce flash info ?'),
        content: const Text('Cette annonce sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client.from('flash_infos').delete().eq(
          'id', info['id']);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer.')),
      );
    }
  }

  Future<void> _showAddSheet() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            5.w,
            3.h,
            5.w,
            MediaQuery.of(context).viewInsets.bottom + 3.h,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouveau flash info',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Ex : Promo -10% sur les insecticides '
                        'cette semaine !',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Message requis'
                      : null,
                ),
                SizedBox(height: 1.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ??
                                false)) {
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              final userId = SupabaseConfig
                                  .client.auth.currentUser?.id;
                              await SupabaseConfig.client
                                  .from('flash_infos')
                                  .insert({
                                'message': controller.text.trim(),
                                'created_by': userId,
                              });
                              if (context.mounted) Navigator.pop(context);
                              _load();
                            } catch (_) {
                              setSheetState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Impossible de publier ce flash info.')),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publier'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Flash infos — Accueil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Publier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 2.h),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _infos.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            const Center(
                                child: Text('Aucun flash info publié.')),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _infos.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final info = _infos[index];
                            final active = info['active'] as bool? ?? true;
                            final createdAt =
                                DateTime.tryParse(info['created_at'] ?? '');
                            return Card(
                              child: ListTile(
                                title: Text(info['message'] ?? ''),
                                subtitle: createdAt != null
                                    ? Text(
                                        'Publié le ${_dateFormat.format(createdAt.toLocal())}')
                                    : null,
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: active,
                                      onChanged: (_) => _toggleActive(info),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: theme.colorScheme.error),
                                      onPressed: () => _delete(info),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
