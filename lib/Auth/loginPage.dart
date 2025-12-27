<<<<<<< Updated upstream
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:crypto/crypto.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// // import 'package:soko/style.dart'; // Supposé être un fichier de style local
// import 'package:shared_preferences/shared_preferences.dart';
// // NOUVEAUX IMPORTS POUR APPLE
// import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;
// import 'package:soko/Screen/bottonNav.dart';
// import 'package:soko/services/user_service.dart';
//
// // Utilitaires de sécurité pour Apple Sign-In
// String generateNonce({int length = 32}) {
//   const charset =
//       '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
//   final random = Random.secure();
//   return List.generate(length, (_) => charset[random.nextInt(charset.length)])
//       .join();
// }
//
// String sha256ofString(String input) {
//   final bytes = utf8.encode(input);
//   final digest = sha256.convert(bytes);
//   return digest.toString();
// }
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String _error = '';
//   bool _isLoading = false;
//   bool _isAppleLoading = false;
//
//   // --- START: Méthodes de Gestion de Session (Corrigent l'erreur) ---
//
//   // ✅ SAUVEGARDER LES DONNÉES UTILISATEUR DANS SHARED_PREFERENCES
//   Future<void> _saveUserData(User user) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('user_email', user.email ?? '');
//       await prefs.setString('user_name', user.displayName ?? 'Utilisateur');
//       await prefs.setString('user_photo_url', user.photoURL ?? '');
//       await prefs.setString('user_id', user.uid);
//       await prefs.setBool('is_logged_in', true);
//
//       print("✅ Données utilisateur sauvegardées: ${user.email}");
//     } catch (e) {
//       print("❌ Erreur sauvegarde utilisateur: $e");
//     }
//   }
//
//   // 💡 NOUVEAU : Enregistrer l'utilisateur dans la base de données
//   Future<void> _registerUserInDatabase(User user) async {
//     try {
//       await UserService.registerUserAfterLogin(user);
//       print("✅ Utilisateur enregistré dans la base de données: ${user.email}");
//     } catch (e) {
//       print("❌ Erreur enregistrement base de données: $e");
//     }
//   }
//
//   // 🔎 VÉRIFIER SI UN UTILISATEUR EST DÉJÀ CONNECTÉ
//   Future<bool> _checkExistingUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getBool('is_logged_in') ?? false;
//     } catch (e) {
//       print("❌ Erreur vérification connexion: $e");
//       return false;
//     }
//   }
//
//   // ✅ RÉCUPÉRER LES DONNÉES UTILISATEUR (Méthode statique inchangée)
//   static Future<Map<String, String>> getUserData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return {
//         'email': prefs.getString('user_email') ?? '',
//         'name': prefs.getString('user_name') ?? 'Utilisateur',
//         'photo_url': prefs.getString('user_photo_url') ?? '',
//         'uid': prefs.getString('user_id') ?? '',
//       };
//     } catch (e) {
//       print("❌ Erreur récupération données utilisateur: $e");
//       return {};
//     }
//   }
//
//   // ✅ DÉCONNEXION ET SUPPRESSION DES DONNÉES (Méthode statique inchangée)
//   static Future<void> logoutUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('user_email');
//       await prefs.remove('user_name');
//       await prefs.remove('user_photo_url');
//       await prefs.remove('user_id');
//       await prefs.remove('is_logged_in');
//
//       // Déconnexion Google
//       await GoogleSignIn().signOut();
//       // Déconnexion Firebase
//       await FirebaseAuth.instance.signOut();
//
//       print("✅ Utilisateur déconnecté et données supprimées");
//     } catch (e) {
//       print("❌ Erreur déconnexion: $e");
//     }
//   }
//
//   // --- END: Méthodes de Gestion de Session ---
//
//   // ✅ UTILITAIRE: NAVIGUER VERS L'ÉCRAN PRINCIPAL
//   void _navigateToHome() {
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => BottomNavExample()),
//       );
//     }
//   }
//
//   // ✅ UTILITAIRE: GÉRER LES ERREURS FIREBASE
//   void _handleAuthError(FirebaseAuthException e) {
//     throw (e);
//     // setState(() {
//     //   _isLoading = false;
//     //   if (e.code == 'account-exists-with-different-credential') {
//     //     _error = 'Un compte existe déjà avec cet email.';
//     //   } else if (e.code == 'invalid-credential') {
//     //     _error = 'Identifiants invalides. Veuillez réessayer.';
//     //   } else if (e.code == 'user-disabled') {
//     //     _error = 'Ce compte a été désactivé.';
//     //   } else if (e.code == 'user-not-found') {
//     //     _error = 'Aucun compte trouvé avec cet email.';
//     //   } else if (e.code == 'wrong-password') {
//     //     _error = 'Mot de passe incorrect.';
//     //   } else {
//     //     _error = 'Échec de la connexion. Veuillez réessayer.';
//     //   }
//     // });
//   }
//
//   // ✅ UTILITAIRE: GÉRER LES ERREURS GÉNÉRIQUES
//   void _handleGenericError(dynamic e, String defaultMessage) {
//     setState(() {
//       _isLoading = false;
//       _error = defaultMessage;
//     });
//   }
//
//   // 1. FONCTION DE CONNEXION GOOGLE
//   Future<void> signInWithGoogle() async {
//     setState(() {
//       _isLoading = true;
//       _error = '';
//     });
//
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       final User? user = userCredential.user;
//
//       if (user != null) {
//         await _saveUserData(user);
//         // 💡 NOUVEAU : Enregistrer l'utilisateur dans la base de données
//         await _registerUserInDatabase(user);
//         print("🎉 Connexion Google réussie: ${user.email}");
//         _navigateToHome();
//       } else {
//         throw Exception("Utilisateur null après connexion Google");
//       }
//     } on FirebaseAuthException catch (e) {
//       _handleAuthError(e);
//       print('Erreur Firebase Auth (Google): $e');
//     } catch (e) {
//       _handleGenericError(e, 'Échec de la connexion Google. Veuillez réessayer.');
//       print('Erreur de connexion Google: $e');
//     }
//   }
//
//   // 2. FONCTION DE CONNEXION APPLE
//   Future<void> signInWithApple() async {
//     setState(() {
//       _isAppleLoading = true;
//       _error = '';
//     });
//
//     try {
//       final rawNonce = generateNonce();
//       final nonce = sha256ofString(rawNonce);
//
//       final appleCredential = await apple.SignInWithApple.getAppleIDCredential(
//         scopes: [
//           apple.AppleIDAuthorizationScopes.email,
//           apple.AppleIDAuthorizationScopes.fullName,
//         ],
//         nonce: nonce,
//       );
//
//       final AuthCredential credential = OAuthProvider('apple.com').credential(
//         idToken: appleCredential.identityToken,
//         rawNonce: rawNonce,
//       );
//
//       final UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       final User? user = userCredential.user;
//
//       if (user != null) {
//         // Optionnel: Mettre à jour le nom si c'est la première fois
//         if (user.displayName == null && appleCredential.givenName != null) {
//             await user.updateDisplayName(
//                 '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}');
//         }
//
//         await _saveUserData(user);
//         // 💡 NOUVEAU : Enregistrer l'utilisateur dans la base de données
//         await _registerUserInDatabase(user);
//         print("🎉 Connexion Apple réussie: ${user.email}");
//         setState(() {
//           _isAppleLoading = false;
//         });
//         _navigateToHome();
//       } else {
//         throw Exception("Utilisateur null après connexion Apple");
//       }
//     } on FirebaseAuthException catch (e) {
//       setState(() {
//         _isAppleLoading = false;
//       });
//       _handleAuthError(e);
//       print('Erreur Firebase Auth (Apple): $e');
//     } on apple.SignInWithAppleAuthorizationException catch (e) {
//       // Gérer l'annulation par l'utilisateur
//       if (e.code == apple.AuthorizationErrorCode.canceled) {
//         print("Connexion Apple annulée par l'utilisateur.");
//         setState(() {
//           _isAppleLoading = false;
//         });
//       } else {
//         setState(() {
//           _isAppleLoading = false;
//         });
//         _handleGenericError(e, 'Échec de la connexion Apple.');
//       }
//     } catch (e) {
//       setState(() {
//         _isAppleLoading = false;
//       });
//       _handleGenericError(e, 'Échec de la connexion Apple. Veuillez réessayer.');
//       print('Erreur de connexion Apple: $e');
//     }
//   }
//
//
//   // 3. VÉRIFICATION AUTOMATIQUE DE CONNEXION AU DÉMARRAGE
//   @override
//   void initState() {
//     super.initState();
//     _checkAndAutoLogin();
//   }
//
//   Future<void> _checkAndAutoLogin() async {
//     final isLoggedIn = await _checkExistingUser();
//     if (isLoggedIn && mounted) {
//       final currentUser = _auth.currentUser;
//       if (currentUser != null) {
//         print("🔄 Connexion automatique pour: ${currentUser.email}");
//         // 💡 NOUVEAU : S'assurer que l'utilisateur est enregistré dans la base de données
//         await _registerUserInDatabase(currentUser);
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => BottomNavExample()),
//             );
//           }
//         });
//       } else {
//         await logoutUser();
//       }
//     }
//   }
//
//   // 4. WIDGET BUILD
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.white,
//               Colors.white,
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Section de l'en-tête (Logo et titre)
//                 Column(
//                   children: [
//                     Image.asset(
//                       'assets/icon.png',
//                       height: 120,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Bienvenue',
//                       style: GoogleFonts.actor(
//                         fontSize: 32,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.blue.shade900,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Connectez-vous pour continuer',
//                       style: GoogleFonts.abel(
//                         fontSize: 18,
//                         color: Colors.blue.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),
//
//                 // Conteneur de connexion
//                 Padding(
//                   padding: const EdgeInsets.all(32),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Message d'erreur
//                       if (_error.isNotEmpty)
//                         Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[50],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.red[200]!),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.error_outline, color: Colors.red[700]),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       _error,
//                                       style: TextStyle(
//                                         color: Colors.red[700],
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                           ],
//                         ),
//
//                       // Indicateur de chargement
//                       if (_isLoading)
//                         Column(
//                           children: [
//                             const SizedBox(height: 16),
//                             Text(
//                               'Connexion en cours...',
//                               style: GoogleFonts.abel(
//                                 fontSize: 16,
//                                 color: Colors.blue.shade700,
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                           ],
//                         ),
//
//                       // Bouton de connexion Google
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _isLoading ? null : signInWithGoogle,
//                           style: ElevatedButton.styleFrom(
//                             foregroundColor: Colors.black87,
//                             backgroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             elevation: 2,
//                           ),
//                           icon: Image.asset(
//                             'assets/google.png',
//                             height: 24,
//                           ),
//                           label: _isLoading
//                               ? const SizedBox(
//                                   height: 24,
//                                   width: 24,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.blue,
//                                   ),
//                                 )
//                               : Text(
//                                   'Se connecter avec Google',
//                                   style: GoogleFonts.aBeeZee(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                         ),
//                       ),
//
//                       // Bouton de connexion Apple (Visible uniquement sur iOS/macOS)
//                       if (Platform.isIOS || Platform.isMacOS)
//
//                         SizedBox(height: 15,),
//
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: _isAppleLoading ? null : Platform.isIOS ? signInWithApple : (){},
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.black87,
//                               backgroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 side: BorderSide(color: Colors.grey.shade300),
//                               ),
//                               elevation: 2,
//                             ),
//                             icon: Image.asset(
//                               'assets/apple.png',
//                               height: 24,
//                             ),
//                             label: _isAppleLoading
//                                 ? const SizedBox(
//                               height: 24,
//                               width: 24,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.blue,
//                               ),
//                             )
//                                 : Text(
//                               'Se connecter avec Apple',
//                               style: GoogleFonts.aBeeZee(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         // Column(
//                         //   children: [
//                         //     const SizedBox(height: 16),
//                         //     SizedBox(
//                         //       width: double.infinity,
//                         //       height: 56,
//                         //       child: apple.SignInWithAppleButton(
//                         //         onPressed: (_isAppleLoading || _isAppleLoading) ? null : signInWithApple,
//                         //         style: apple.SignInWithAppleButtonStyle.black,
//                         //         borderRadius: BorderRadius.circular(12),
//                         //         iconAlignment: _isAppleLoading
//                         //           ? apple.IconAlignment.center
//                         //           : apple.IconAlignment.left,
//                         //         text: _isAppleLoading ? 'Connexion…' : 'Se connecter avec Apple',
//                         //       ),
//                         //     ),
//                         //   ],
//                         // ),
//
//                       // Information sur la persistance des données
//                       const SizedBox(height: 20),
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'Votre session sera sauvegardée pour une reconnexion automatique',
//                                 style: GoogleFonts.abel(
//                                   fontSize: 12,
//                                   color: Colors.blue[700],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:convert';
import 'dart:io';
=======
>>>>>>> Stashed changes
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
<<<<<<< Updated upstream
import 'package:shared_preferences/shared_preferences.dart'; // Ajout de shared_preferences
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:soko/Screen/bottonNav.dart';
import 'package:soko/utils/responsive.dart';
=======
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
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
  bool _isAppleLoading = false;

  // ✅ SAUVEGARDER LES DONNÉES UTILISATEUR DANS SHARED_PREFERENCES
=======

>>>>>>> Stashed changes
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_name', user.displayName ?? 'Utilisateur');
      await prefs.setString('user_photo_url', user.photoURL ?? '');
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('is_logged_in', true);
<<<<<<< Updated upstream

      print("✅ Données utilisateur sauvegardées: ${user.email}");
=======
>>>>>>> Stashed changes
    } catch (e) {
      print("Erreur sauvegarde utilisateur: $e");
    }
  }
<<<<<<< Updated upstream

  // ✅ VÉRIFIER SI UN UTILISATEUR EST DÉJÀ CONNECTÉ
=======
>>>>>>> Stashed changes
  Future<bool> _checkExistingUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print("Erreur vérification connexion: $e");
      return false;
    }
  }

<<<<<<< Updated upstream
  // ✅ RÉCUPÉRER LES DONNÉES UTILISATEUR
=======
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
  // ✅ DÉCONNEXION ET SUPPRESSION DES DONNÉES
=======
>>>>>>> Stashed changes
  static Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_photo_url');
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');
<<<<<<< Updated upstream

      // Déconnexion Google
=======
      
>>>>>>> Stashed changes
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
<<<<<<< Updated upstream

      print("✅ Utilisateur déconnecté et données supprimées");
=======
>>>>>>> Stashed changes
    } catch (e) {
      print("Erreur déconnexion: $e");
    }
  }

<<<<<<< Updated upstream
=======
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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    }
    on FirebaseAuthException catch (e) {
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
=======
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, loc);
      print('Erreur Firebase Auth (Google): $e');
    } catch (e) {
      _handleGenericError(e, loc, isGoogle: true);
>>>>>>> Stashed changes
      print('Erreur de connexion Google: $e');
    }
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isAppleLoading = true;
      _error = '';
    });
    try {

      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        // Line added after the latest firebase_auth update [today it's Jun 4th 2025]
        accessToken: appleCredential.authorizationCode,
      );

      // Connexion à Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;

      if (user != null) {
        // Sauvegarder les données utilisateur

        /* N.B: Apple ne fournit les details de l'utilisateur qu'à sa toute première authentification dans  l'appli, pour toutes les prochaines
        authentifications les details du user sont renvoyés avec des valeurs nulles, il faut trouver un moyen efficace de persist ces details
        moi même dans Yapp j'avais pas trouvé un excellent moyen de le faire parce que des fois ça renvoyait des valeurs nulles meme apès les avoir
        persist, raison pour laquelle actuellement on avait decidé au moment où un utilisateur est connecté avec apple j'écris just
        "Your apple account"

        */
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
<<<<<<< Updated upstream
        throw Exception("Utilisateur null après connexion");
=======
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
>>>>>>> Stashed changes
      }
    }
    on FirebaseAuthException catch (e) {
      setState(() {
        _isAppleLoading = false;
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
<<<<<<< Updated upstream
      setState(() {
        _isAppleLoading = false;
        _error = 'Échec de la connexion Apple. Veuillez réessayer.';
      });
      print('Erreur de connexion Google: $e');
=======
      _handleGenericError(e, loc);
      print('Erreur de connexion Apple: $e');
>>>>>>> Stashed changes
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
    final loc = AppLocalizations.of(context);
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
<<<<<<< Updated upstream
        child: Responsive.centerContent(
          context,
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getHorizontalPadding(context) * 1.5,
                vertical: Responsive.getVerticalPadding(context) * 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section de l'en-tête (Logo et titre)
                  Column(
                    children: [
                      Image.asset(
                        'assets/icon.png',
                        height: Responsive.isMobile(context) ? 120.0 : 150.0,
                      ),
                      SizedBox(height: Responsive.getVerticalPadding(context) * 2),
                      Text(
                        'Bienvenue',
                        style: GoogleFonts.actor(
                          fontSize: Responsive.getAdaptiveFontSize(context, mobile: 32, tablet: 40, desktop: 48),
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade900,
                        ),
=======
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
>>>>>>> Stashed changes
                      ),
                      SizedBox(height: Responsive.getVerticalPadding(context) * 0.5),
                      Text(
                        'Connectez-vous pour continuer',
                        style: GoogleFonts.abel(
                          fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 22),
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.getVerticalPadding(context) * 3.75),

                  // Conteneur de connexion
                  Padding(
                    padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 2),
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
                      if (_isLoading || _isAppleLoading)
                        Column(
                          children: [
                            //    const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
<<<<<<< Updated upstream
                              'Connexion automatique...',
=======
                              loc.loginProgress,
>>>>>>> Stashed changes
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
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.getVerticalPadding(context) * 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            elevation: 2,
                          ),
                          icon: Image.asset(
                            'assets/google.png',
                            height: Responsive.isMobile(context) ? 24.0 : 28.0,
                          ),
                          label: _isLoading
                              ? SizedBox(
                            height: Responsive.isMobile(context) ? 24.0 : 28.0,
                            width: Responsive.isMobile(context) ? 24.0 : 28.0,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                              : Text(
<<<<<<< Updated upstream
                            'Se connecter avec Google',
                            style: GoogleFonts.aBeeZee(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
=======
                                  loc.loginGoogle,
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
>>>>>>> Stashed changes
                        ),
                      ),

                      // Séparateur "OU"
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
<<<<<<< Updated upstream
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: GoogleFonts.abel(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey[300],
=======
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
>>>>>>> Stashed changes
                              ),
                            ),
                          ],
                        ),
                      ),

                      //Boutton de connexion avec Apple
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAppleLoading ? null : Platform.isIOS ? signInWithApple : (){},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.getVerticalPadding(context) * 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            elevation: 2,
                          ),
                          icon: Image.asset(
                            'assets/apple.png',
                            height: Responsive.isMobile(context) ? 24.0 : 28.0,
                          ),
                          label: _isAppleLoading
                              ? SizedBox(
                            height: Responsive.isMobile(context) ? 24.0 : 28.0,
                            width: Responsive.isMobile(context) ? 24.0 : 28.0,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                              : Text(
                            'Se connecter avec Apple',
                            style: GoogleFonts.aBeeZee(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Information sur la persistance des données
                      const SizedBox(height: 40),
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

                      // Bouton "Sauter"
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => BottomNavExample()),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.getVerticalPadding(context) * 1.5,
                          ),
                        ),
                        child: Text(
                          'Sauter',
                          style: GoogleFonts.abel(
                            fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
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
      ),
    );
  }
}