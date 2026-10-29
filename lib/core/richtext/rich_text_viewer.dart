import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Affiche un contenu enrichi (gras, listes, titres...) écrit avec
/// [RichTextEditorField] — lecture seule. Si [deltaJson] est absent
/// ou illisible, retombe sur un simple `Text(plainText)` (contenu pas
/// encore réécrit avec le nouvel éditeur, voir
/// supabase/phase298_patch_formation_module_rich_text.sql).
class RichTextViewer extends StatefulWidget {
  final String? deltaJson;
  final String? plainText;
  final TextStyle? plainTextStyle;

  const RichTextViewer({
    super.key,
    this.deltaJson,
    this.plainText,
    this.plainTextStyle,
  });

  @override
  State<RichTextViewer> createState() => _RichTextViewerState();
}

class _RichTextViewerState extends State<RichTextViewer> {
  QuillController? _controller;
  FocusNode? _focusNode;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant RichTextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deltaJson != widget.deltaJson) {
      _disposeController();
      _setupController();
    }
  }

  void _setupController() {
    final json = widget.deltaJson;
    if (json == null || json.trim().isEmpty) return;
    try {
      final document = Document.fromJson(jsonDecode(json) as List);
      _controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      _focusNode = FocusNode(canRequestFocus: false);
      _scrollController = ScrollController();
    } catch (_) {
      // Delta corrompu/illisible — repli sur le texte brut dans build().
      _controller = null;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _focusNode?.dispose();
    _scrollController?.dispose();
    _controller = null;
    _focusNode = null;
    _scrollController = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return IgnorePointer(
        child: QuillEditor(
          controller: controller,
          focusNode: _focusNode!,
          scrollController: _scrollController!,
          config: const QuillEditorConfig(
            padding: EdgeInsets.zero,
            scrollable: false,
            expands: false,
            showCursor: false,
          ),
        ),
      );
    }
    final text = widget.plainText;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: widget.plainTextStyle);
  }
}
