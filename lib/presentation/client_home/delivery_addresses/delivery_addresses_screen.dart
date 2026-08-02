import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';

/// Carnet d'adresses de livraison (Profil client, Lot 4, 03/08) —
/// supabase/phase57_patch_delivery_addresses.sql.
///
/// ⚠️ Limite assumée : ce carnet est autonome pour l'instant — le
/// checkout (cart_tab.dart) garde son champ de saisie libre actuel, non
/// branché sur ces adresses enregistrées dans ce lot (touche le flux de
/// commande en production, chantier séparé à faire avec prudence).
class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _myId;
    if (uid == null || !SupabaseConfig.isConfigured) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final rows = await SupabaseConfig.client
          .from('delivery_addresses')
          .select()
          .eq('customer_id', uid)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _addresses = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(Map<String, dynamic> address) async {
    final uid = _myId;
    if (uid == null) return;
    try {
      await SupabaseConfig.client
          .from('delivery_addresses')
          .update({'is_default': false})
          .eq('customer_id', uid);
      await SupabaseConfig.client
          .from('delivery_addresses')
          .update({'is_default': true}).eq('id', address['id']);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  Future<void> _delete(Map<String, dynamic> address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette adresse ?'),
        content: Text('"${address['label']}" sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('delivery_addresses')
          .delete()
          .eq('id', address['id']);
      if (!mounted) return;
      setState(() => _addresses.removeWhere((a) => a['id'] == address['id']));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressEditorSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Adresses de livraison')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Adresse'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _addresses.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Aucune adresse enregistrée. Ajoutez-en une pour la retrouver rapidement.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        final isDefault = address['is_default'] == true;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isDefault
                                  ? Icons.push_pin
                                  : Icons.location_on_outlined,
                              color: isDefault
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            title: Text(address['label'] ?? ''),
                            subtitle: Text(address['address'] ?? ''),
                            onTap: () => _openEditor(existing: address),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'default') _setDefault(address);
                                if (v == 'edit') {
                                  _openEditor(existing: address);
                                }
                                if (v == 'delete') _delete(address);
                              },
                              itemBuilder: (context) => [
                                if (!isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Définir par défaut'),
                                  ),
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Modifier')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
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

class _AddressEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _AddressEditorSheet({this.existing});

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.existing?['label'] ?? '');
    _addressController =
        TextEditingController(text: widget.existing?['address'] ?? '');
    _latitude = (widget.existing?['latitude'] as num?)?.toDouble();
    _longitude = (widget.existing?['longitude'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Autorisation de localisation refusée.')));
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      String address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.subLocality, p.locality, p.administrativeArea]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _addressController.text = address;
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de récupérer la position.')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;
    if (_labelController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        'customer_id': uid,
        'label': _labelController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
      };
      if (widget.existing != null) {
        await SupabaseConfig.client
            .from('delivery_addresses')
            .update(payload)
            .eq('id', widget.existing!['id']);
      } else {
        await SupabaseConfig.client
            .from('delivery_addresses')
            .insert(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              widget.existing != null
                  ? 'Modifier l\'adresse'
                  : 'Nouvelle adresse',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Nom (ex : Domicile, Bureau...)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Adresse',
              border: const OutlineInputBorder(),
              suffixIcon: _isLocating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Utiliser ma position actuelle',
                      onPressed: _useCurrentLocation,
                    ),
            ),
          ),
          SizedBox(height: 2.5.h),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
