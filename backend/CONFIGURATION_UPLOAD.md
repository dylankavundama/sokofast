# Configuration pour résoudre l'erreur d'upload d'image

## Problème
L'erreur `The uploaded file exceeds the upload_max_filesize directive in php.ini` indique que la limite d'upload PHP est trop petite (actuellement 2 Mo).

## Solutions appliquées

### 1. Fichier `.user.ini` créé
Un fichier `.user.ini` a été créé dans le dossier `backend/` avec les limites suivantes :
- `upload_max_filesize = 20M` (augmenté de 2M à 20M)
- `post_max_size = 25M` (augmenté de 20M à 25M)
- `memory_limit = 256M` (augmenté de 128M à 256M)
- `max_execution_time = 300` (augmenté de 30 à 300 secondes)
- `max_input_time = 300` (augmenté de 60 à 300 secondes)

**Note:** Les modifications dans `.user.ini` prennent effet après quelques minutes ou après redémarrage du serveur.

### 2. Fichier `.htaccess` créé (alternative)
Un fichier `.htaccess` a également été créé avec les mêmes valeurs au cas où `.user.ini` ne serait pas pris en compte.

### 3. Code Flutter amélioré
Le code d'upload dans `lib/Product/add.dart` a été amélioré pour :
- Vérifier la taille du fichier avant l'upload (limite: 10 Mo)
- Afficher des messages d'erreur plus clairs et explicites
- Gérer spécifiquement l'erreur de taille de fichier

## Instructions pour activer les modifications

### Option 1: Via cPanel (Recommandé)
1. Connectez-vous à cPanel
2. Allez dans **Software >> MultiPHP INI Editor**
3. Sélectionnez le domaine/sous-domaine concerné
4. Modifiez les valeurs suivantes :
   - `upload_max_filesize` → `20M`
   - `post_max_size` → `25M`
   - `memory_limit` → `256M`
   - `max_execution_time` → `300`
   - `max_input_time` → `300`
5. Cliquez sur **Save**

### Option 2: Fichiers créés automatiquement
Les fichiers `.user.ini` et `.htaccess` ont été créés dans le dossier `backend/`. 
- Si vous utilisez cPanel, le fichier `.user.ini` devrait être pris en compte automatiquement
- Si vous utilisez Apache standard, le fichier `.htaccess` sera utilisé

### Option 3: Vérification manuelle
Pour vérifier que les modifications sont actives, créez un fichier `phpinfo.php` dans le dossier `backend/` :

```php
<?php
phpinfo();
?>
```

Puis accédez à `https://votre-domaine.com/backend/phpinfo.php` et cherchez :
- `upload_max_filesize` → devrait afficher `20M`
- `post_max_size` → devrait afficher `25M`

**⚠️ Important:** Supprimez le fichier `phpinfo.php` après vérification pour des raisons de sécurité.

## Limites recommandées

Pour les applications mobiles avec upload d'images :
- **upload_max_filesize**: 20 Mo (photos haute résolution) ✅ Configuré
- **post_max_size**: 25 Mo (doit être > upload_max_filesize) ✅ Configuré
- **memory_limit**: 256 Mo (pour traiter les images) ✅ Configuré
- **max_execution_time**: 300 secondes (5 minutes pour uploads lents) ✅ Configuré
- **max_input_time**: 300 secondes (5 minutes pour traiter les données POST) ✅ Configuré

## Vérification côté Flutter

Le code Flutter vérifie maintenant :
- La taille du fichier avant l'upload (affiche un message si > 20 Mo)
- Les erreurs spécifiques du serveur avec messages explicites
- Affiche la taille du fichier dans les logs

## Notes importantes

1. **WordPress**: L'application upload actuellement vers WordPress (babutik.com). Si vous voulez uploader vers votre propre backend, vous devrez créer un endpoint d'upload d'image.

2. **Sécurité**: Les fichiers `.user.ini` et `.htaccess` sont des fichiers de configuration sensibles. Ne les partagez pas publiquement.

3. **Performance**: Augmenter les limites peut affecter les performances du serveur. Surveillez l'utilisation des ressources.

## Support

Si les modifications ne fonctionnent pas :
1. Vérifiez les permissions des fichiers (`.user.ini` et `.htaccess` doivent être lisibles)
2. Vérifiez les logs d'erreur PHP
3. Contactez votre hébergeur si vous n'avez pas accès à cPanel

