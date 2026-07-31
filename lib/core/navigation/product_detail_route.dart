import 'package:flutter/material.dart';

/// Transition personnalisée vers la fiche produit — plus lente que le
/// `MaterialPageRoute` par défaut (500ms au lieu de ~300ms), pour que le
/// vol de la photo (voir `Hero` sur `_ProductCard`/`_FavoriteCard`) soit
/// bien visible. Un simple fondu (pas de zoom) pour ne pas concurrencer
/// visuellement le flight du Hero.
Route<T> productDetailRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
