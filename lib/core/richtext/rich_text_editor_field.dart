import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Éditeur de texte enrichi réutilisable (gras, italique, souligné,
/// titres, listes...) — une vraie barre d'outils, l'auteur choisit la
/// mise en forme au moment d'écrire plutôt qu'une syntaxe à apprendre
/// (demande explicite 29/10). Basé sur `flutter_quill`, déjà présent
/// dans pubspec.yaml mais jamais câblé jusqu'ici.
///
/// Conçu pour être réutilisé partout où du contenu enrichi est utile
/// (pour l'instant branché uniquement sur le texte des modules de
/// formation — voir formation_course_modules_management.dart).
///
/// Le contenu se lit/s'écrit au format Quill Delta (JSON) via
/// [initialDeltaJson]/[onChanged]. Si [initialDeltaJson] est absent
/// mais [initialPlainText] est fourni (ancien contenu en texte brut,
/// avant ce patch), il est chargé comme point de départ modifiable.
class RichTextEditorField extends StatefulWidget {
  final String? initialDeltaJson;
  final String? initialPlainText;
  final ValueChanged<RichTextEditorValue> onChanged;
  final String placeholder;

  const RichTextEditorField({
    super.key,
    this.initialDeltaJson,
    this.initialPlainText,
    required this.onChanged,
    this.placeholder = 'Texte du module…',
  });

  @override
  State<RichTextEditorField> createState() => _RichTextEditorFieldState();
}

/// Valeur renvoyée par [RichTextEditorField.onChanged] : le contenu au
/// format Delta (à sauvegarder dans `content_delta`) et son
/// équivalent en texte brut (à sauvegarder dans `content_text`, pour
/// rester lisible partout ailleurs dans l'app sans changement).
class RichTextEditorValue {
  final String deltaJson;
  final String plainText;

  const RichTextEditorValue(
      {required this.deltaJson, required this.plainText});
}

class _RichTextEditorFieldState extends State<RichTextEditorField> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    final initialDelta = widget.initialDeltaJson;
    final initialPlain = widget.initialPlainText;
    if (initialDelta != null && initialDelta.trim().isNotEmpty) {
      try {
        _controller.document =
            Document.fromJson(jsonDecode(initialDelta) as List);
      } catch (_) {
        // Delta corrompu/illisible — on retombe sur le texte brut
        // s'il y en a un, plutôt que de planter l'écran.
        if (initialPlain != null && initialPlain.isNotEmpty) {
          _controller.document = Document()..insert(0, initialPlain);
        }
      }
    } else if (initialPlain != null && initialPlain.isNotEmpty) {
      _controller.document = Document()..insert(0, initialPlain);
    }
    _controller.changes.listen((_) => _emitChange());
  }

  void _emitChange() {
    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
    final plainText = _controller.document.toPlainText().trim();
    widget.onChanged(
        RichTextEditorValue(deltaJson: deltaJson, plainText: plainText));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: _controller,
            config: const QuillSimpleToolbarConfig(),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 160, maxHeight: 320),
            child: QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                placeholder: widget.placeholder,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
