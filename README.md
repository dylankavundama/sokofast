# 🛒 SOKO FAST - Application E-Commerce Mobile

![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-Proprietary-red.svg)

**SOKO FAST** est une application mobile de commerce électronique développée avec Flutter, permettant aux utilisateurs d'acheter des produits en ligne avec un système de livraison intégré.

## 📋 Table des matières

- [À propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Captures d'écran](#-captures-décran)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Structure du projet](#-structure-du-projet)
- [Technologies utilisées](#-technologies-utilisées)
- [Dépendances principales](#-dépendances-principales)
- [Utilisation](#-utilisation)
- [Build et déploiement](#-build-et-déploiement)
- [API et Backend](#-api-et-backend)
- [Contributions](#-contributions)
- [Licence](#-licence)

## 🎯 À propos

SOKO FAST est une plateforme e-commerce complète qui offre une expérience d'achat fluide et sécurisée. L'application permet aux utilisateurs de :

- Parcourir et rechercher des produits par catégories
- Gérer un panier d'achat
- Passer des commandes avec suivi en temps réel
- Gérer leur profil utilisateur
- Utiliser plusieurs méthodes d'authentification
- Effectuer des paiements sécurisés via FlexPay

L'application supporte également un système de livraison avec une interface dédiée pour les livreurs.

## ✨ Fonctionnalités

### 👤 Pour les clients

- **Catalogue de produits** : Navigation intuitive avec recherche et filtres
- **Catégories** : Organisation des produits par catégories
- **Panier d'achat** : Gestion complète du panier avec quantité
- **Historique des commandes** : Suivi de toutes les commandes passées
- **Profil utilisateur** : Gestion du compte et des informations personnelles
- **Authentification multiple** :
  - Email/Mot de passe (Firebase)
  - Connexion Google
  - Connexion Apple (Sign in with Apple)
- **Géolocalisation** : Utilisation de la position pour la livraison
- **Paiement sécurisé** : Intégration avec FlexPay Gateway

### 🚚 Pour les livreurs

- **Interface livreur** : Connexion et gestion des commandes
- **Suivi des commandes** : Visualisation et gestion des livraisons
- **Statut des commandes** : Mise à jour en temps réel

### 👨‍💼 Pour les administrateurs/vendeurs

- **Gestion des produits** : Ajout, modification et suppression de produits
- **Mes produits** : Vue d'ensemble des produits publiés
- **Gestion des commandes** : Suivi et traitement des commandes

## 📸 Captures d'écran

Des captures d'écran de l'application sont disponibles dans le dossier `capture/` :
- Écran d'accueil
- Détails des produits
- Panier d'achat

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- **Flutter SDK** (version 3.24.0 ou supérieure)
- **Dart SDK** (version 3.5.0 ou supérieure)
- **Android Studio** ou **Xcode** (pour iOS)
- **Git**
- **Firebase CLI** (optionnel, pour la configuration Firebase)
- Un compte **Firebase** avec les services suivants activés :
  - Authentication
  - Cloud Firestore
- Un compte **FlexPay** (pour les paiements)

## 🚀 Installation

### 1. Cloner le repository

```bash
git clone <url-du-repository>
cd sokofast-feat-run-ios-app
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configuration Firebase

#### Android

1. Téléchargez le fichier `google-services.json` depuis la console Firebase
2. Placez-le dans `android/app/google-services.json`
3. Le fichier est également présent dans `assets/google-services.json`

#### iOS

1. Téléchargez le fichier `GoogleService-Info.plist` depuis la console Firebase
2. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### 4. Configuration de l'API

Éditez le fichier `lib/api_config.dart` et configurez :

```dart
static const String BASE_URL = 'https://sokofast.com/backend';
static const String MERCHANT_ID = 'VOTRE_MERCHANT_ID';
static const String BEARER_TOKEN = 'VOTRE_TOKEN';
```

### 5. Exécuter l'application

```bash
# Pour Android
flutter run

# Pour iOS
flutter run -d ios

# Pour un appareil spécifique
flutter devices
flutter run -d <device-id>
```

## ⚙️ Configuration

### Variables d'environnement

L'application utilise plusieurs configurations qui doivent être personnalisées :

1. **API Backend** : Modifier `lib/api_config.dart`
2. **Firebase** : Configurer les fichiers de configuration Firebase
3. **Permissions** : Vérifier les permissions dans :
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/Info.plist`

### Permissions requises

#### Android (`AndroidManifest.xml`)
- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `CAMERA` (pour l'image picker)
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`

#### iOS (`Info.plist`)
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 📁 Structure du projet

```
lib/
├── admin/                    # Interface administrateur
│   ├── login_livreur.dart
│   └── order.dart
├── Auth/                     # Authentification
│   └── loginPage.dart
├── Categorie/                # Gestion des catégories
│   ├── category_item.dart
│   ├── category_screen.dart
│   └── products_by_category_screen.dart
├── livreur/                  # Interface livreur
│   ├── login_livreur.dart
│   └── order.dart
├── Product/                  # Gestion des produits
│   ├── add.dart
│   ├── productCard.dart
│   ├── productDetailScreen.dart
│   └── productListScreen.dart
├── Profil/                   # Profil utilisateur
│   ├── delete_account_screen.dart
│   ├── delete_account_service.dart
│   ├── EditProductScreen.dart
│   └── mes_produits.dart
├── Screen/                   # Écrans principaux
│   ├── bottonNav.dart        # Navigation principale
│   ├── CartScreen.dart       # Panier
│   ├── ProfileScreen.dart    # Profil
│   └── splashScreen.dart     # Écran de démarrage
├── services/                 # Services
│   └── user_service.dart
├── utils/                    # Utilitaires
│   └── responsive.dart
├── Widget/                   # Widgets réutilisables
│   └── fullImage.dart
├── api_config.dart           # Configuration API
├── comment.dart              # Système de commentaires
├── firebase_options.dart     # Options Firebase
├── main.dart                 # Point d'entrée
├── onBoarding.dart           # Écran d'onboarding
├── order.dart                # Gestion des commandes
├── OrderHistoryScreen.dart   # Historique des commandes
├── services.dart             # Services globaux
└── style.dart                # Styles et thèmes
```

## 🛠 Technologies utilisées

- **Flutter** : Framework de développement cross-platform
- **Dart** : Langage de programmation
- **Firebase** :
  - Authentication (Email, Google, Apple)
  - Cloud Firestore (Base de données)
- **Provider** : Gestion d'état
- **HTTP/Dio** : Communication avec l'API backend
- **Geolocator/Geocoding** : Services de géolocalisation
- **Image Picker** : Sélection d'images
- **Shared Preferences** : Stockage local

## 📦 Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.3
  shimmer: ^3.0.0
  cached_network_image: ^3.2.0
  shared_preferences: ^2.0.8
  provider: ^6.0.2
  intl: ^0.17.0
  google_fonts: latest
  image_picker: latest
  url_launcher: ^6.0.12
  flutter_html: latest
  dio: ^5.0.0
  html_unescape: latest
  path_provider: ^2.1.1
  firebase_auth: latest
  cloud_firestore: latest
  google_sign_in: ^6.1.5
  geolocator: ^11.0.1
  geocoding: latest
  permission_handler: ^11.0.1
  sign_in_with_apple: ^7.0.1
  crypto: ^3.0.7
```

## 💻 Utilisation

### Premier lancement

1. L'application affiche un écran d'onboarding lors de la première utilisation
2. L'utilisateur peut ensuite se connecter ou créer un compte
3. Les méthodes d'authentification disponibles :
   - Email/Mot de passe
   - Google Sign-In
   - Apple Sign-In (iOS uniquement)

### Navigation

L'application utilise une barre de navigation inférieure avec trois onglets :
- **Accueil** : Liste des produits
- **Catégories** : Navigation par catégories
- **Profil** : Gestion du compte utilisateur

### Passer une commande

1. Parcourir les produits ou utiliser la recherche
2. Ajouter des produits au panier
3. Accéder au panier depuis l'icône dans la barre de navigation
4. Valider la commande
5. Choisir le mode de paiement (FlexPay)
6. Suivre la commande dans l'historique

## 🔨 Build et déploiement

### Build Android (APK)

```bash
flutter build apk --release
```

Le fichier APK sera généré dans `build/app/outputs/flutter-apk/app-release.apk`

### Build Android (App Bundle)

```bash
flutter build appbundle --release
```

Le fichier AAB sera généré dans `build/app/outputs/bundle/release/app-release.aab`

### Build iOS

```bash
flutter build ios --release
```

Pour iOS, vous devrez ensuite ouvrir le projet dans Xcode :
```bash
open ios/Runner.xcworkspace
```

Puis archiver et publier depuis Xcode.

### Configuration des icônes

Les icônes de l'application sont configurées via `flutter_launcher_icons`. L'image source est `assets/logo.png`.

## 🌐 API et Backend

L'application communique avec un backend PHP situé à `https://sokofast.com/backend`.

### Endpoints principaux

- **Produits** : Récupération de la liste des produits
- **Catégories** : Liste des catégories disponibles
- **Commandes** : Création et suivi des commandes
- **Paiement** : Intégration FlexPay Gateway

### Configuration FlexPay

L'application utilise FlexPay pour le traitement des paiements. La configuration se fait dans `lib/api_config.dart` :

```dart
static const String FLEXPAY_GATEWAY_URL = 
    'http://backend.flexpay.cd/api/rest/v1/paymentService';
```

## 🧪 Tests

Pour exécuter les tests :

```bash
flutter test
```

## 📝 Notes de développement

- L'application utilise Material Design 3
- Le thème principal utilise une couleur jaune personnalisée (`customYellowSwatch`)
- Les données du panier sont stockées localement avec `SharedPreferences`
- L'application supporte le mode sombre (selon les préférences système)

## 🤝 Contributions

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est propriétaire. Tous droits réservés.

## 👥 Équipe

Développé avec ❤️ pour SOKO FAST

## 📞 Support

Pour toute question ou problème, veuillez ouvrir une issue sur le repository ou contacter l'équipe de développement.

---

**Version actuelle** : 2.2.0+27  
**Dernière mise à jour** : 2026
