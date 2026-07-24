import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'favorites_screen.dart';

/// Profil client : affichage + édition des infos réelles (profiles table),
/// changement d'avatar. Étape 1-2 du plan d'amélioration du côté client.
class ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileTab({super.key, required this.onLogout});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Non connecté.';
      });
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le profil.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditSheet() async {
    if (_profile == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditProfileSheet(profile: _profile!),
    );
    if (updated == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = SupabaseConfig.client.auth.currentUser;
    final profile = _profile ?? {};
    final fullName = profile['full_name'] as String?;
    final companyName = profile['company_name'] as String?;
    final phone = profile['phone'] as String?;
    final location = profile['location'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    final sector = _sectorLabels[profile['client_type']];

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 44)
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Center(
            child: Text(
              (fullName == null || fullName.trim().isEmpty)
                  ? (user?.email ?? '')
                  : fullName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          if (sector != null)
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Chip(label: Text(sector)),
              ),
            ),
          SizedBox(height: 3.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Société'),
                  subtitle: Text(
                    (companyName == null || companyName.trim().isEmpty)
                        ? '—'
                        : companyName,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Téléphone'),
                  subtitle: Text(
                    (phone == null || phone.trim().isEmpty) ? '—' : phone,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Localisation'),
                  subtitle: Text(
                    (location == null || location.trim().isEmpty)
                        ? '—'
                        : location,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.pushNamed(context, '/client-chat'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Messagerie'),
          ),
          SizedBox(height: 1.h),
          FilledButton.tonalIcon(
            onPressed: _openEditSheet,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier mon profil'),
          ),
          SizedBox(height: 3.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_border),
                  title: const Text('Mes favoris'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;

  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  String? _clientType;
  File? _newAvatar;
  bool _isSaving = false;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile['full_name'] ?? '');
    _companyController =
        TextEditingController(text: widget.profile['company_name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.profile['phone'] ?? '');
    _locationController =
        TextEditingController(text: widget.profile['location'] ?? '');
    _latitude = (widget.profile['latitude'] as num?)?.toDouble();
    _longitude = (widget.profile['longitude'] as num?)?.toDouble();
    _clientType = widget.profile['client_type'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Autorisation de localisation refusée. Active-la dans les paramètres du téléphone.'),
          ),
        );
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Active le GPS/la localisation de ton téléphone puis réessaie.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // Reverse-géocodage indisponible (ex: hors ligne) — on garde les
        // coordonnées brutes comme repli, toujours utile pour la livraison.
      }

      if (!mounted) return;
      setState(() {
        _locationController.text = address;
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de récupérer ta position.')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      String? avatarUrl = widget.profile['avatar_url'] as String?;
      if (_newAvatar != null) {
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseConfig.client.storage
            .from('avatars')
            .upload(fileName, _newAvatar!);
        avatarUrl =
            SupabaseConfig.client.storage.from('avatars').getPublicUrl(fileName);
      }

      await SupabaseConfig.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'company_name': _companyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'client_type': _clientType,
        'avatar_url': avatarUrl,
      }).eq('id', userId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.profile['avatar_url'] as String?;
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier mon profil',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 2.h),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _newAvatar != null
                          ? FileImage(_newAvatar!) as ImageProvider
                          : (currentAvatarUrl != null
                              ? NetworkImage(currentAvatarUrl)
                              : null),
                      child: _newAvatar == null && currentAvatarUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 14,
                      child: Icon(Icons.camera_alt, size: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Société',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Localisation',
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
            SizedBox(height: 1.5.h),
            DropdownButtonFormField<String>(
              value: _clientType,
              decoration: const InputDecoration(
                labelText: 'Secteur',
                border: OutlineInputBorder(),
              ),
              items: _sectorLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _clientType = v),
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
      ),
    );
  }
}
