# Guide : Obtenir le Service ID Apple (_appleServiceId)

## 📋 Récapitulatif

Le **Service ID** est différent du **Bundle ID** de votre app iOS :
- **Bundle ID iOS** : `com.sokofast.btc` (pour l'app iOS native)
- **Service ID** : `com.sokofast.btc.signin` (pour Sign In with Apple sur Android/Web)

## 🔧 Étapes détaillées

### Étape 1 : Accéder à Apple Developer

1. Allez sur https://developer.apple.com/account
2. Connectez-vous avec votre compte Apple Developer (abonnement payant requis)

### Étape 2 : Créer un Service ID

1. Dans le menu, cliquez sur **"Certificates, Identifiers & Profiles"**
2. Dans la barre latérale, cliquez sur **"Identifiers"**
3. Cliquez sur le bouton **"+"** en haut à gauche
4. Sélectionnez **"Services IDs"** puis cliquez sur **"Continue"**
5. Remplissez le formulaire :
   - **Description** : `Soko Fast Sign In with Apple` (ou autre description)
   - **Identifier** : `com.sokofast.btc.signin` ⚠️ **C'est celui-ci que vous utiliserez dans le code !**
6. Cliquez sur **"Continue"** puis **"Register"**

### Étape 3 : Configurer Sign In with Apple

1. Cliquez sur le **Service ID** que vous venez de créer (`com.sokofast.btc.signin`)
2. Cochez la case **"Sign In with Apple"**
3. Cliquez sur le bouton **"Configure"** à droite
4. Dans la fenêtre qui s'ouvre :
   - **Primary App ID** : Sélectionnez votre App ID iOS (`com.sokofast.btc`)
   - **Domains and Subdomains** : Entrez votre domaine Vercel (ex: `sokofast.vercel.app`)
   - **Return URLs** : Cliquez sur **"+"** et ajoutez :
     ```
     https://sokofast.vercel.app/callbacks/sign_in_with_apple
     ```
5. Cliquez sur **"Save"** en bas à droite
6. Cliquez sur **"Continue"** puis **"Save"** à nouveau

### Étape 4 : Vérifier le domaine (si demandé)

Apple peut demander de vérifier que vous possédez le domaine. Si c'est le cas :

1. Téléchargez le fichier de vérification proposé
2. Sur Vercel, créez un fichier dans le dossier `public/.well-known/` :
   - Nom du fichier : celui fourni par Apple (généralement `apple-app-site-association`)
   - Contenu : celui fourni par Apple
3. Déployez sur Vercel
4. Apple vérifiera automatiquement l'accès à :
   `https://sokofast.vercel.app/.well-known/apple-app-site-association`

### Étape 5 : Mettre à jour le code

Une fois le Service ID créé, mettez à jour `lib/Auth/loginPage.dart` :

```dart
static const String _appleServiceId = 'com.sokofast.btc.signin'; // ← Votre Service ID
static const String _appleRedirectUri = 'https://sokofast.vercel.app/callbacks/sign_in_with_apple';
```

## ✅ Vérification

Votre configuration devrait être :

- ✅ **Service ID créé** : `com.sokofast.btc.signin` (ou celui que vous avez choisi)
- ✅ **Sign In with Apple activé** pour ce Service ID
- ✅ **Primary App ID** : `com.sokofast.btc` (votre app iOS)
- ✅ **Return URL** : `https://sokofast.vercel.app/callbacks/sign_in_with_apple`
- ✅ **Page de callback** déployée sur Vercel
- ✅ **Code mis à jour** avec le bon Service ID

## 📝 Notes importantes

- Le **Service ID** doit être **unique** dans votre compte Apple Developer
- Il ne peut pas être le même que votre **Bundle ID** iOS
- Le format recommandé : `com.votredomaine.app.service` ou `com.votredomaine.app.signin`
- La **Return URL** doit correspondre **exactement** à celle configurée dans Apple Developer
- La **Return URL** doit utiliser **HTTPS** (pas HTTP)

## 🐛 Problèmes courants

### "Invalid client_id"
- Vérifiez que le Service ID dans le code correspond exactement à celui dans Apple Developer
- Vérifiez que Sign In with Apple est bien activé pour ce Service ID

### "Invalid redirect_uri"
- Vérifiez que l'URL dans le code correspond exactement à celle dans Apple Developer
- Respectez la casse (majuscules/minuscules)
- Vérifiez qu'il n'y a pas d'espace ou de caractère supplémentaire

### "Domain verification failed"
- Vérifiez que le fichier `.well-known/apple-app-site-association` est accessible
- Vérifiez que le fichier est au bon endroit dans votre déploiement Vercel

