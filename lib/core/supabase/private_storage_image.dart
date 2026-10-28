import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'supabase_config.dart';

/// Affiche une image d'un bucket Storage PRIVÉ via un téléchargement
/// authentifié (`storage.from(bucket).download(path)`), jamais via une
/// URL publique/signée — voir supabase/phase275_patch_formation_videos_bucket.sql
/// (28/10, protection maximale des formations payantes demandée
/// explicitement : aucun lien copiable/partageable, même à durée
/// limitée). Utilisé pour les photos de modules de formation, côté
/// Admin (aperçu à l'upload) et côté client (lecture).
///
/// Cache mémoire simple par session (pas de persistance disque) : évite
/// de retélécharger la même photo à chaque reconstruction du widget.
class PrivateStorageImage extends StatefulWidget {
  final String bucket;
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PrivateStorageImage({
    super.key,
    required this.bucket,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<PrivateStorageImage> createState() => _PrivateStorageImageState();
}

class _PrivateStorageImageState extends State<PrivateStorageImage> {
  static final Map<String, Uint8List> _cache = {};
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PrivateStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket != widget.bucket || oldWidget.path != widget.path) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final key = '${widget.bucket}/${widget.path}';
    final cached = _cache[key];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    try {
      final bytes =
          await SupabaseConfig.client.storage.from(widget.bucket).download(
                widget.path,
              );
      _cache[key] = bytes;
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    final bytes = _bytes;
    if (bytes == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Image.memory(bytes,
        width: widget.width, height: widget.height, fit: widget.fit);
  }
}
