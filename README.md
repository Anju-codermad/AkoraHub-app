# AkoraHub

Application mobile Flutter + Supabase pour Akora Fanadiovana (fabrication et
distribution de produits d'hygiène/nettoyage à Madagascar), incluant les
pôles Akora Paints et AkoraFormation.

## 📋 Prérequis

- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code avec les extensions Flutter
- Android SDK / Xcode (pour le développement iOS)
- Un projet Supabase configuré (voir `supabase/*.sql` pour le schéma)

## 🛠️ Installation

1. Installer les dépendances :
```bash
flutter pub get
```

2. Configurer `env.json` à la racine (URL et clé publique Supabase) :
```json
{
  "SUPABASE_URL": "https://xxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "..."
}
```

3. Lancer l'application :
```bash
flutter run
```

## 📁 Structure du projet

```
AkoraHub-app/
├── android/            # Configuration spécifique Android
├── ios/                # Configuration spécifique iOS
├── lib/
│   ├── core/           # Services partagés (Supabase, notifications, paiement...)
│   ├── presentation/   # Écrans et widgets
│   ├── routes/         # Routage de l'application
│   ├── theme/          # Configuration du thème
│   ├── widgets/        # Composants UI réutilisables
│   └── main.dart       # Point d'entrée
├── supabase/           # Scripts SQL (schéma, migrations par phase)
├── assets/             # Ressources statiques (images, sons)
├── pubspec.yaml        # Dépendances et configuration du projet
└── PROJECT_CONTEXT.md  # Documentation détaillée du projet
```

## 📦 Build de production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

Voir `PROJECT_CONTEXT.md` pour l'historique détaillé des fonctionnalités,
les scripts SQL à exécuter et les conventions du projet.
