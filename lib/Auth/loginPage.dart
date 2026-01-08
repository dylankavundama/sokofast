import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;
import 'package:soko/Screen/bottonNav.dart';
import 'package:soko/l10n/app_localizations.dart';

String generateNonce({int length = 32}) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

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

  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_name', user.displayName ?? '');
      await prefs.setString('user_photo_url', user.photoURL ?? '');
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      print("Erreur sauvegarde utilisateur: $e");
    }
  }
  Future<bool> _checkExistingUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print("Erreur vérification connexion: $e");
      return false;
    }
  }

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
      print("Erreur récupération données utilisateur: $e");
      return {};
    }
  }

  static Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_photo_url');
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');
      
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Erreur déconnexion: $e");
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavExample()),
      );
    }
  }

  void _handleAuthError(FirebaseAuthException e, AppLocalizations loc) {
    setState(() {
      _isLoading = false;
      if (e.code == 'account-exists-with-different-credential') {
        _error = loc.loginErrorAccountExists;
      } else if (e.code == 'invalid-credential') {
        _error = loc.loginErrorInvalidCredential;
      } else if (e.code == 'user-disabled') {
        _error = loc.loginErrorUserDisabled;
      } else if (e.code == 'user-not-found') {
        _error = loc.loginErrorUserNotFound;
      } else if (e.code == 'wrong-password') {
        _error = loc.loginErrorWrongPassword;
      } else {
        _error = loc.loginErrorGeneric;
      }
    });
  }

  // ✅ UTILITAIRE: GÉRER LES ERREURS GÉNÉRIQUES
  void _handleGenericError(dynamic e, AppLocalizations loc, {bool isGoogle = false}) {
    setState(() {
      _isLoading = false;
      _error = isGoogle ? loc.loginErrorGoogleFailed : loc.loginErrorAppleFailed;
    });
  }

  // 1. FONCTION DE CONNEXION GOOGLE
  Future<void> signInWithGoogle() async {
    final loc = AppLocalizations.of(context);
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

      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserData(user);
        print("🎉 Connexion Google réussie: ${user.email}");
        _navigateToHome();
      } else {
        throw Exception("Utilisateur null après connexion Google");
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, loc);
      print('Erreur Firebase Auth (Google): $e');
    } catch (e) {
      _handleGenericError(e, loc, isGoogle: true);
      print('Erreur de connexion Google: $e');
    }
  }

  // 2. FONCTION DE CONNEXION APPLE
  Future<void> signInWithApple() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final rawNonce = generateNonce();
      
      final appleCredential = await apple.SignInWithApple.getAppleIDCredential(
        scopes: [
          apple.AppleIDAuthorizationScopes.email,
          apple.AppleIDAuthorizationScopes.fullName,
        ],
        nonce: rawNonce,
      );

      final AuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Optionnel: Mettre à jour le nom si c'est la première fois
        if (user.displayName == null && appleCredential.givenName != null) {
            await user.updateDisplayName(
                '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}');
        }
        
        await _saveUserData(user);
        print("🎉 Connexion Apple réussie: ${user.email}");
        _navigateToHome();
      } else {
        throw Exception("Utilisateur null après connexion Apple");
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, loc);
      print('Erreur Firebase Auth (Apple): $e');
    } on apple.SignInWithAppleAuthorizationException catch (e) {
      // Gérer l'annulation par l'utilisateur
      if (e.code == apple.AuthorizationErrorCode.canceled) {
        print("Connexion Apple annulée par l'utilisateur.");
        setState(() {
          _isLoading = false;
        });
      } else {
        _handleGenericError(e, loc);
      }
    } catch (e) {
      _handleGenericError(e, loc);
      print('Erreur de connexion Apple: $e');
    }
  }


  // 3. VÉRIFICATION AUTOMATIQUE DE CONNEXION AU DÉMARRAGE
  @override
  void initState() {
    super.initState();
    _checkAndAutoLogin();
  }

  Future<void> _checkAndAutoLogin() async {
    final isLoggedIn = await _checkExistingUser();
    if (isLoggedIn && mounted) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print("🔄 Connexion automatique pour: ${currentUser.email}");
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BottomNavExample()),
            );
          }
        });
      } else {
        await logoutUser();
      }
    }
  }

  // 4. WIDGET BUILD
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                      loc.loginTitle,
                      style: GoogleFonts.actor(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.loginSubtitle,
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
                      
                      // Indicateur de chargement
                      if (_isLoading)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              loc.loginProgress,
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
                                  loc.loginGoogle,
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Bouton de connexion Apple (Visible uniquement sur iOS/macOS)
                      if (Platform.isIOS || Platform.isMacOS)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: apple.SignInWithAppleButton(
                                onPressed: _isLoading ? null : signInWithApple,
                                style: apple.SignInWithAppleButtonStyle.black,
                                height: 56,
                                borderRadius: BorderRadius.circular(12),
                                iconAlignment: _isLoading 
                                  ? apple.IconAlignment.center 
                                  : apple.IconAlignment.left,
                                text: _isLoading ? loc.loginAppleConnecting : loc.loginAppleButton,
                              ),
                            ),
                          ],
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
                                loc.loginSessionInfo,
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