import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ajout de shared_preferences
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:soko/Screen/bottonNav.dart';

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

  // ⚠️ CONFIGURATION APPLE SIGN-IN (Android/Web uniquement)
  // 
  // 1. Créez un Service ID dans Apple Developer :
  //    - https://developer.apple.com/account → Certificates, Identifiers & Profiles → Identifiers
  //    - Créez un "Services IDs" (ex: com.sokofast.btc.signin)
  //    - Activez "Sign In with Apple" pour ce Service ID
  //    - Configurez le Return URL : https://sokofast.vercel.app/callbacks/sign_in_with_apple
  //
  // 2. Utilisez le Service ID créé ci-dessous (PAS le Bundle ID iOS)
  static const String _appleServiceId = 'com.sokofast.btc'; // ← REMPLACEZ par votre Service ID
  static const String _appleRedirectUri = 'https://sokofast.vercel.app/callbacks/sign_in_with_apple';

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

  Future<bool> signInWithApple() async {
    try {
      setState(() { _isLoading = true; _error = ''; });

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // iOS: natif, Android: flux Web avec Service ID + Redirect URI
        webAuthenticationOptions: Platform.isIOS
            ? null
            : WebAuthenticationOptions(
                clientId: _appleServiceId,
                redirectUri: Uri.parse(_appleRedirectUri),
              ),
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      String? idToken;
      final isInPhoneAttachment = FirebaseAuth.instance.currentUser?.isAnonymous == true;
      if (isInPhoneAttachment) {
        idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      }

      if (idToken != null) {
        try {
          await FirebaseAuth.instance.currentUser?.linkWithCredential(oauthCredential);
        } on FirebaseAuthException catch (e) {
          switch (e.code) {
            case "provider-already-linked":
              await FirebaseAuth.instance.signInWithCredential(oauthCredential);
              break;
            case "credential-already-in-use":
              if (e.credential != null) {
                await FirebaseAuth.instance.signInWithCredential(e.credential!);
              }
              break;
            case "email-already-in-use":
              // Signale via UI existante
              setState(() { _error = 'Email déjà utilisé.'; });
              return false;
            default:
              rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Enregistrer nom si retourné à la première connexion
        if ((appleCredential.givenName != null || appleCredential.familyName != null) && (user.displayName == null || user.displayName!.isEmpty)) {
          final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          if (displayName.isNotEmpty) {
            await user.updateDisplayName(displayName);
            await user.reload();
          }
        }

        await _saveUserData(FirebaseAuth.instance.currentUser!);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavExample()),
          );
        }
      }

      setState(() { _isLoading = false; });
      return true;
    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; _error = e.message ?? 'Erreur Firebase'; });
      return false;
    } on PlatformException catch (e) {
      setState(() { _isLoading = false; _error = e.message ?? 'Erreur plate-forme'; });
      return false;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) {
        setState(() { _isLoading = false; });
        return false;
      }
      setState(() { _isLoading = false; _error = e.toString(); });
      return false;
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
                      
                      // Sur iOS, Apple Sign-In doit être en premier (directive 4.8)
                      // Bouton de connexion Apple (prioritaire sur iOS)
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
                      const SizedBox(height: 12),
                      // Bouton de connexion Google
                      Text('OU', style: GoogleFonts.abel(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 12),
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