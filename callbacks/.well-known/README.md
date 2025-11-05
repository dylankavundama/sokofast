# Vérification du domaine Apple

Si Apple demande de vérifier votre domaine, vous devrez créer un fichier ici.

## 📁 Structure sur Vercel

Pour que Vercel serve le fichier à `https://votre-domaine.vercel.app/.well-known/apple-app-site-association`, placez-le dans :

```
public/.well-known/apple-app-site-association
```

## 🔧 Configuration Vercel

1. Dans Apple Developer, lors de la configuration du Service ID, téléchargez le fichier de vérification
2. Créez le dossier `public/.well-known/` à la racine de votre projet
3. Placez le fichier téléchargé dans ce dossier
4. Déployez sur Vercel
5. Vérifiez l'accès : `https://votre-domaine.vercel.app/.well-known/apple-app-site-association`

## ⚠️ Note

Le fichier doit être accessible sans extension `.json` même s'il contient du JSON.

Vercel servira automatiquement les fichiers dans `public/.well-known/` à l'URL `/.well-known/`.

