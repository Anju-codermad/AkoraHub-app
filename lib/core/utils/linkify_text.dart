import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Affiche un texte en rendant cliquable tout lien http(s) qu'il contient
/// (souligné, couleur primaire, ouvert dans le navigateur) et en
/// interprétant une mise en forme simple façon WhatsApp — demande
/// explicite (27/10, pour les flash infos) : `*gras*`, `_italique_`,
/// `~barré~`. Pas de dépendance type Markdown/Quill (flutter_quill est
/// dans pubspec.yaml mais jamais utilisé ailleurs dans l'app) : juste
/// quelques RegExp, cohérent avec le reste de l'app (ex.
/// `LinkPreviewService`, core/chat/link_preview_service.dart, pour la
/// détection de liens). Pas d'imbrication de styles pris en charge (ex.
/// gras+italique en même temps) — volontairement simple.
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _urlPattern = RegExp(r'https?://[^\s<>"]+');
  // Un seul niveau de formatage à la fois : *gras*, _italique_, ~barré~.
  // `[^\n*]` etc. pour ne jamais franchir un saut de ligne (évite qu'un
  // astérisque oublié n'avale tout le reste du message).
  static final _formatPattern =
      RegExp(r'\*([^\n*]+)\*|_([^\n_]+)_|~([^\n~]+)~');

  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final linkColor = Theme.of(context).colorScheme.primary;
    final spans = _buildFormattedSpans(text, baseStyle, linkColor);

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static List<InlineSpan> _buildFormattedSpans(
      String text, TextStyle baseStyle, Color linkColor) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _formatPattern.allMatches(text)) {
      if (match.start > last) {
        spans.addAll(_linkify(
            text.substring(last, match.start), baseStyle, linkColor));
      }
      TextStyle innerStyle;
      String inner;
      if (match.group(1) != null) {
        inner = match.group(1)!;
        innerStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
      } else if (match.group(2) != null) {
        inner = match.group(2)!;
        innerStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
      } else {
        inner = match.group(3)!;
        innerStyle = baseStyle.copyWith(decoration: TextDecoration.lineThrough);
      }
      spans.addAll(_linkify(inner, innerStyle, linkColor));
      last = match.end;
    }
    if (last < text.length) {
      spans.addAll(_linkify(text.substring(last), baseStyle, linkColor));
    }
    return spans;
  }

  static List<InlineSpan> _linkify(
      String segment, TextStyle style, Color linkColor) {
    final matches = _urlPattern.allMatches(segment);
    if (matches.isEmpty) return [TextSpan(text: segment, style: style)];

    // Combine le souligné du lien avec un éventuel barré déjà posé par
    // `_buildFormattedSpans` (ex. lien à l'intérieur d'un `~barré~`).
    final existingDecoration = style.decoration;
    final linkStyle = style.copyWith(
      color: linkColor,
      decoration: TextDecoration.combine([
        TextDecoration.underline,
        if (existingDecoration != null &&
            existingDecoration != TextDecoration.none)
          existingDecoration,
      ]),
    );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: segment.substring(last, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      last = match.end;
    }
    if (last < segment.length) {
      spans.add(TextSpan(text: segment.substring(last)));
    }
    return spans;
  }
}
