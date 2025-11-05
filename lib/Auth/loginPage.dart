import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:io' show Platform;
import 'package:soko/Screen/bottonNav.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ajout de shared_preferences

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _error = '';
  bool _isLoading = false;

  // REMPLACEZ-LES PAR VOS VALEURS (Android/Web uniquement)
  static const String _appleServiceId = 'com.sokofast.btc';
  static const String _appleRedirectUri = 'https://apple.com/callbacks/sign_in_with_apple';

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ✅ SAUVEGARDER LES DONNÉES UTILISATEUR DANS SHARED_PREFERENCES
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_name', user.displayName ?? 'Utilisateur');
      await prefs.setString('user_photo_url', user.photoURL ?? '');
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('is_logged_in', true);
      
      print("✅ Données utilisateur sauvegardées: ${user.email}");
    } catch (e) {
      print("❌ Erreur sauvegarde utilisateur: $e");
    }
  }

  // ✅ VÉRIFIER SI UN UTILISATEUR EST DÉJÀ CONNECTÉ
  Future<bool> _checkExistingUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print("❌ Erreur vérification connexion: $e");
      return false;
    }
  }

  // ✅ RÉCUPÉRER LES DONNÉES UTILISATEUR
  static Future<Map<String, String>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'email': prefs.getString('user_email') ?? '',
        'name': prefs.getString('user_name') ?? 'Utilisateur',
        'photo_url': prefs.getString('user_photo_url') ?? '',
        'uid': prefs.getString('user_id') ?? '',
      };
    } catch (e) {
      print("❌ Erreur récupération données utilisateur: $e");
      return {};
    }
  }

  // ✅ DÉCONNEXION ET SUPPRESSION DES DONNÉES
  static Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_photo_url');
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');
      
      // Déconnexion Google
      await GoogleSignIn().signOut();
      // Déconnexion Firebase
      await FirebaseAuth.instance.signOut();
      
      print("✅ Utilisateur déconnecté et données supprimées");
    } catch (e) {
      print("❌ Erreur déconnexion: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion à Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Sauvegarder les données utilisateur
        await _saveUserData(user);
        
        print("🎉 Connexion réussie: ${user.email}");
        
        // Navigation vers l'écran principal
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavExample()),
          );
        }
      } else {
        throw Exception("Utilisateur null après connexion");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'account-exists-with-different-credential') {
          _error = 'Un compte existe déjà avec cet email.';
        } else if (e.code == 'invalid-credential') {
          _error = 'Identifiants invalides. Veuillez réessayer.';
        } else if (e.code == 'user-disabled') {
          _error = 'Ce compte a été désactivé.';
        } else if (e.code == 'user-not-found') {
          _error = 'Aucun compte trouvé avec cet email.';
        } else if (e.code == 'wrong-password') {
          _error = 'Mot de passe incorrect.';
        } else {
          _error = 'Échec de la connexion. Veuillez réessayer.';
        }
      });
      print('Erreur Firebase Auth: $e');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Échec de la connexion Google. Veuillez réessayer.';
      });
      print('Erreur de connexion Google: $e');
    }
  }

  Future<void> signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Vérifier si Apple Sign-In est disponible
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        setState(() {
          _isLoading = false;
          _error = 'Connexion Apple non disponible sur cet appareil.';
        });
        print('❌ Apple Sign-In non disponible');
        return;
      }

      print('🍎 Démarrage de la connexion Apple...');
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      print('🔑 Nonce généré: ${rawNonce.substring(0, 8)}...');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // Requis sur Android/Web: fournir clientId (Service ID) et redirectUri
        webAuthenticationOptions: Platform.isIOS
            ? null
            : WebAuthenticationOptions(
                clientId: _appleServiceId,
                redirectUri: Uri.parse(_appleRedirectUri),
              ),
      );

      print('✅ Credentials Apple obtenues');
      print('📧 Email: ${appleCredential.email ?? 'non fourni'}');
      print('👤 Nom: ${appleCredential.givenName ?? 'non fourni'} ${appleCredential.familyName ?? ''}');
      print('🆔 Identity Token: ${appleCredential.identityToken != null && appleCredential.identityToken!.isNotEmpty ? 'présent' : 'absent'}');
      print('🔐 Authorization Code: ${appleCredential.authorizationCode.isNotEmpty ? 'présent' : 'absent'}');

      if (appleCredential.identityToken == null) {
        throw Exception('Identity token manquant');
      }

      final oauthProvider = OAuthProvider("apple.com");
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      print('🔥 Authentification Firebase en cours...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Gérer les informations de nom si fournies lors de la première connexion
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          if (displayName.isNotEmpty && user.displayName == null) {
            await user.updateDisplayName(displayName);
            await user.reload();
            final updatedUser = _auth.currentUser;
            if (updatedUser != null) {
              await _saveUserData(updatedUser);
            }
          } else {
            await _saveUserData(user);
          }
        } else {
          await _saveUserData(user);
        }

        print("🎉 Connexion Apple réussie: ${user.email ?? 'Email masqué'}");
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavExample()),
          );
        }
      } else {
        throw Exception('Utilisateur null après connexion Apple');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          print('❌ Connexion Apple annulée par l\'utilisateur');
          // Ne pas afficher d'erreur si l'utilisateur a annulé
          return;
        case AuthorizationErrorCode.failed:
          _error = 'Échec de l\'autorisation Apple.';
          print('❌ Erreur d\'autorisation Apple: ${e.message}');
          break;
        case AuthorizationErrorCode.invalidResponse:
          _error = 'Réponse invalide d\'Apple.';
          print('❌ Réponse invalide: ${e.message}');
          break;
        case AuthorizationErrorCode.notHandled:
          _error = 'Connexion Apple non gérée.';
          print('❌ Non géré: ${e.message}');
          break;
        case AuthorizationErrorCode.notInteractive:
          _error = 'Connexion Apple non interactive.';
          print('❌ Non interactif: ${e.message}');
          break;
        case AuthorizationErrorCode.unknown:
          _error = 'Erreur inconnue lors de la connexion Apple.';
          print('❌ Erreur inconnue: ${e.message}');
          break;
      }
      
      setState(() {
        _error = _error;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'invalid-credential':
          _error = 'Identifiants Apple invalides. Veuillez réessayer.';
          break;
        case 'account-exists-with-different-credential':
          _error = 'Un compte existe déjà avec cet email (utilisez un autre moyen de connexion).';
          break;
        case 'operation-not-allowed':
          _error = 'Connexion Apple non activée dans Firebase.';
          break;
        case 'network-request-failed':
          _error = 'Erreur réseau. Vérifiez votre connexion.';
          break;
        default:
          _error = 'Échec de la connexion Apple: ${e.message ?? e.code}';
      }
      
      setState(() {
        _error = _error;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors de la connexion Apple: ${e.toString()}';
      });
      print('❌ Erreur inattendue Apple Sign-In: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ✅ VÉRIFICATION AUTOMATIQUE DE CONNEXION AU DÉMARRAGE
  @override
  void initState() {
    super.initState();
    _checkAndAutoLogin();
  }

  Future<void> _checkAndAutoLogin() async {
    final isLoggedIn = await _checkExistingUser();
    if (isLoggedIn && mounted) {
      // Vérifier si l'utilisateur Firebase est toujours connecté
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print("🔄 Connexion automatique pour: ${currentUser.email}");
        // Navigation automatique après un court délai
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BottomNavExample()),
            );
          }
        });
      } else {
        // L'utilisateur n'est plus connecté à Firebase, nettoyer les données
        await logoutUser();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section de l'en-tête (Logo et titre)
                Column(
                  children: [
                    Image.asset(
                      'assets/icon.png',
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue',
                      style: GoogleFonts.actor(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connectez-vous pour continuer',
                      style: GoogleFonts.abel(
                        fontSize: 18,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Conteneur de connexion
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Message d'erreur
                      if (_error.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      
                      // Indicateur de chargement pour connexion auto
                      if (_isLoading)
                        Column(
                          children: [
                        //    const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Connexion automatique...',
                              style: GoogleFonts.abel(
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      
                      // Bouton de connexion Google
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            elevation: 2,
                          ),
                          icon: Image.asset(
                            'assets/google.png',
                            height: 24,
                          ),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                              : Text(
                                  'Se connecter avec Google',
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bouton de connexion Apple
                      Text('OU', style: GoogleFonts.abel(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 12),   
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : signInWithApple,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.apple, color: Colors.white),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Se connecter avec Apple',
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      // Information sur la persistance des données
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Votre session sera sauvegardée pour une reconnexion automatique',
                                style: GoogleFonts.abel(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}