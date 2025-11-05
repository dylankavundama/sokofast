# Guide de Diagnostic - Apple Sign-In

## ✅ Améliorations apportées

L'implémentation a été améliorée avec :
- ✅ Vérification de disponibilité d'Apple Sign-In
- ✅ Logs détaillés pour diagnostiquer les problèmes
- ✅ Gestion spécifique des erreurs Apple (`SignInWithAppleAuthorizationException`)
- ✅ Gestion des erreurs Firebase avec codes spécifiques
- ✅ Gestion du cas où l'utilisateur annule la connexion
- ✅ Gestion des informations de nom lors de la première connexion

## 🔍 Comment diagnostiquer le problème

### 1. Vérifier les logs dans la console

Lorsque vous essayez de vous connecter avec Apple, vous devriez voir des logs détaillés :

```
🍎 Démarrage de la connexion Apple...
🔑 Nonce généré: ...
✅ Credentials Apple obtenues
📧 Email: ...
👤 Nom: ...
🆔 Identity Token: présent/absent
🔐 Authorization Code: présent/absent
🔥 Authentification Firebase en cours...
```

**Si vous voyez une erreur spécifique, notez-la pour la vérification ci-dessous.**

### 2. Vérifications à faire

#### ✅ Vérification 1 : Apple Developer
- [ ] Aller sur [developer.apple.com](https://developer.apple.com)
- [ ] Certificates, Identifiers & Profiles → Identifiers
- [ ] Vérifier que `com.sokofast.btc` existe
- [ ] Cliquer sur l'App ID → Activer "Sign In with Apple"
- [ ] Sauvegarder les changements

#### ✅ Vérification 2 : Xcode Configuration
1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Sélectionner le projet "Runner" dans le navigateur
3. Sélectionner la cible "Runner"
4. Onglet **Signing & Capabilities**
   - [ ] Vérifier que "Team" est sélectionné
   - [ ] Vérifier que Bundle Identifier = `com.sokofast.btc`
   - [ ] Cliquer sur "+ Capability"
   - [ ] Ajouter "Sign In with Apple"
   - [ ] Vérifier qu'elle apparaît dans la liste

#### ✅ Vérification 3 : Firebase Console
1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionner votre projet (`njangi-6e1ea`)
3. Authentication → Sign-in method
   - [ ] Vérifier que "Apple" est activé
   - [ ] Si non activé, cliquer sur "Apple" → Activer → Enregistrer
4. Project Settings → Your apps
   - [ ] Vérifier que l'app iOS a le Bundle ID `com.sokofast.btc`
   - [ ] Si différent, ajouter une nouvelle app iOS avec le bon Bundle ID
   - [ ] Télécharger le nouveau `GoogleService-Info.plist`
   - [ ] Remplacer `ios/Runner/GoogleService-Info.plist`

#### ✅ Vérification 4 : Appareil de test
- [ ] Tester sur un **appareil iOS réel** (pas le simulateur)
- [ ] L'appareil doit être connecté avec un Apple ID
- [ ] iOS 13.0 ou supérieur

#### ✅ Vérification 5 : Code et dépendances
```bash
# Nettoyer et réinstaller
flutter clean
cd ios
pod install
cd ..
flutter pub get
flutter run
```

### 3. Erreurs courantes et solutions

#### ❌ "Connexion Apple non disponible sur cet appareil"
- **Cause** : Simulateur ou appareil sans Apple ID
- **Solution** : Tester sur un appareil réel connecté avec Apple ID

#### ❌ "Connexion Apple non activée dans Firebase"
- **Cause** : Provider Apple non activé dans Firebase
- **Solution** : Activer Apple dans Firebase Console → Authentication → Sign-in method

#### ❌ "Identity token manquant"
- **Cause** : Problème avec la configuration Apple Developer ou Xcode
- **Solution** : 
  1. Vérifier que Sign In with Apple est activé dans Apple Developer
  2. Vérifier la capability dans Xcode
  3. Nettoyer et reconstruire le projet

#### ❌ "Identifiants Apple invalides"
- **Cause** : Problème de nonce ou de token
- **Solution** : Vérifier que le projet est correctement configuré et reconstruire

#### ❌ "Un compte existe déjà avec cet email"
- **Cause** : L'email est déjà utilisé avec un autre provider (Google par exemple)
- **Solution** : Utiliser le même provider que la première connexion, ou lier les comptes dans Firebase

### 4. Test de diagnostic

Exécutez l'application et regardez les logs dans la console. Les messages suivants vous aideront à identifier où se situe le problème :

- ✅ `🍎 Démarrage de la connexion Apple...` → Le code commence à s'exécuter
- ❌ `❌ Apple Sign-In non disponible` → Problème de plateforme/appareil
- ✅ `✅ Credentials Apple obtenues` → Apple a retourné les credentials
- ❌ `❌ Identity token manquant` → Problème avec les credentials Apple
- ✅ `🔥 Authentification Firebase en cours...` → Tentative de connexion Firebase
- ❌ `❌ Erreur Firebase Auth: [code]` → Problème avec Firebase

### 5. Prochaines étapes

1. **Exécutez l'application** et essayez de vous connecter avec Apple
2. **Copiez tous les logs** de la console (avec les emojis 🍎, ✅, ❌)
3. **Vérifiez chaque point** de la liste ci-dessus
4. **Si le problème persiste**, les logs vous indiqueront exactement où ça bloque

## 📝 Notes importantes

- Apple Sign-In fonctionne uniquement sur **iOS 13+**
- Il faut un **compte Apple Developer payant** pour activer Sign In with Apple
- Le **Bundle ID doit être identique** partout :
  - Apple Developer
  - Xcode
  - Firebase
  - `android/app/build.gradle` (pour Android, mais différent de iOS)

