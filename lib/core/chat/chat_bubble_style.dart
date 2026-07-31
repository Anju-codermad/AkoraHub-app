import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Styles de présentation des bulles de messagerie, au choix dans
/// Paramètres — personnel à chaque utilisateur (client ou staff), comme
/// la langue ou le mode sombre (voir `theme_provider.dart`).
enum ChatBubbleStyle { classique, compact, confort }

extension ChatBubbleStyleX on ChatBubbleStyle {
  String get label {
    switch (this) {
      case ChatBubbleStyle.classique:
        return 'Classique';
      case ChatBubbleStyle.compact:
        return 'Compact';
      case ChatBubbleStyle.confort:
        return 'Confort';
    }
  }

  String get description {
    switch (this) {
      case ChatBubbleStyle.classique:
        return 'La présentation actuelle, équilibrée.';
      case ChatBubbleStyle.compact:
        return 'Bulles resserrées — plus de messages visibles à l\'écran.';
      case ChatBubbleStyle.confort:
        return 'Texte agrandi, bulles plus espacées — plus lisible.';
    }
  }

  EdgeInsets get bubblePadding {
    switch (this) {
      case ChatBubbleStyle.classique:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case ChatBubbleStyle.compact:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
      case ChatBubbleStyle.confort:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  double get borderRadius {
    switch (this) {
      case ChatBubbleStyle.classique:
        return 16;
      case ChatBubbleStyle.compact:
        return 12;
      case ChatBubbleStyle.confort:
        return 20;
    }
  }

  double get fontSize {
    switch (this) {
      case ChatBubbleStyle.classique:
        return 14;
      case ChatBubbleStyle.compact:
        return 13;
      case ChatBubbleStyle.confort:
        return 17;
    }
  }

  /// Espace entre deux bulles consécutives.
  double get bubbleSpacing {
    switch (this) {
      case ChatBubbleStyle.classique:
        return 10;
      case ChatBubbleStyle.compact:
        return 6;
      case ChatBubbleStyle.confort:
        return 14;
    }
  }
}

class ChatBubbleStyleNotifier extends StateNotifier<ChatBubbleStyle> {
  ChatBubbleStyleNotifier() : super(ChatBubbleStyle.classique) {
    _load();
  }

  static const _prefsKey = 'chat_bubble_style';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    state = ChatBubbleStyle.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => ChatBubbleStyle.classique,
    );
  }

  Future<void> setStyle(ChatBubbleStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, style.name);
  }
}

final chatBubbleStyleProvider =
    StateNotifierProvider<ChatBubbleStyleNotifier, ChatBubbleStyle>((ref) {
  return ChatBubbleStyleNotifier();
});
