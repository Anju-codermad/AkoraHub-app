import 'package:http/http.dart' as http;

class LinkPreviewData {
  final String url;
  final String? title;
  final String? imageUrl;
  final String? siteName;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.imageUrl,
    this.siteName,
  });
}

/// Aperçu automatique des liens partagés (29/09), façon WhatsApp/Telegram
/// — extrait les balises Open Graph (`og:title`/`og:image`/`og:site_name`)
/// de la page. Recherche par expressions régulières plutôt qu'un vrai
/// parseur HTML (aucun package de parsing HTML dans ce projet, et les
/// balises `<meta property="og:...">` sont simples/prévisibles) — repli
/// silencieux (aucun aperçu affiché) si la page ne répond pas ou n'a pas
/// ces balises, jamais une erreur visible pour l'utilisateur.
class LinkPreviewService {
  LinkPreviewService._();

  static final _urlPattern = RegExp(r'https?://[^\s<>"]+');

  static final _cache = <String, LinkPreviewData?>{};

  /// Premier lien http(s) trouvé dans un texte, ou `null`.
  static String? extractFirstUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    final match = _urlPattern.firstMatch(text);
    return match?.group(0);
  }

  static Future<LinkPreviewData?> fetch(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        _cache[url] = null;
        return null;
      }
      final html = response.body;
      final data = LinkPreviewData(
        url: url,
        title: _extractMeta(html, 'og:title') ?? _extractTitleTag(html),
        imageUrl: _extractMeta(html, 'og:image'),
        siteName: _extractMeta(html, 'og:site_name') ?? Uri.parse(url).host,
      );
      _cache[url] = data;
      return data;
    } catch (_) {
      _cache[url] = null;
      return null;
    }
  }

  static String? _extractMeta(String html, String property) {
    final patterns = [
      RegExp(
        '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']*)["\'][^>]+property=["\']$property["\']',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _extractTitleTag(String html) {
    final match =
        RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
            .firstMatch(html);
    return match?.group(1)?.trim();
  }
}
