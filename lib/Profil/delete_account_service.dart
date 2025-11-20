// delete_account_service.dart - Service pour gérer la suppression de compte et toutes les données

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Auth/LoginPage.dart';
import '../api_config.dart';

class DeleteAccountService {
  static const String baseUrl = ApiConfig.BASE_URL;

  /// Supprime le compte utilisateur et toutes ses données
  /// 
  /// Cette méthode :
  /// 1. Supprime les données de la base de données (utilisateur, produits, commandes, commentaires, etc.)
  /// 2. Supprime les données Firebase (Auth et Firestore)
  /// 3. Supprime toutes les données locales (SharedPreferences)
  /// 4. Déconnecte l'utilisateur de Google Sign-In
  static Future<Map<String, dynamic>> deleteAccount({
    required String firebaseUid,
    required String email,
    required BuildContext context,
  }) async {
    try {
      print("🗑️ Début de la suppression du compte: $email");

      // 1. Supprimer les données de la base de données backend
      final backendResult = await _deleteFromBackend(firebaseUid, email);
      if (!backendResult['success']) {
        print("⚠️ Erreur backend: ${backendResult['message']}");
        // On continue quand même pour supprimer Firebase et local
      }

      // 2. Supprimer les données Firebase Firestore
      await _deleteFromFirestore(firebaseUid);

      // 3. Supprimer le compte Firebase Auth
      await _deleteFromFirebaseAuth(context);

      // 4. Supprimer toutes les données locales
      await _deleteLocalData();

      // 5. Déconnecter de Google Sign-In
      await GoogleSignIn().signOut();

      print("✅ Compte supprimé avec succès: $email");

      return {
        'success': true,
        'message': 'Compte et toutes les données supprimés avec succès',
      };
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la suppression du compte: $e");
      print("Stack trace: $stackTrace");
      return {
        'success': false,
        'message': 'Erreur lors de la suppression: $e',
      };
    }
  }

  /// Supprime les données de la base de données backend
  static Future<Map<String, dynamic>> _deleteFromBackend(
    String firebaseUid,
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firebase_uid': firebaseUid,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      print("📡 Réponse backend: ${response.statusCode}");
      print("📄 Corps: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Données supprimées du backend',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors de la suppression backend',
        };
      }
    } catch (e) {
      print("❌ Erreur backend: $e");
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Supprime les données Firestore
  static Future<void> _deleteFromFirestore(String firebaseUid) async {
    try {
      // Supprimer le document utilisateur dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .delete();
      print("✅ Données Firestore supprimées");
    } catch (e) {
      print("⚠️ Erreur suppression Firestore (peut ne pas exister): $e");
      // Ne pas bloquer si le document n'existe pas
    }
  }

  /// Supprime le compte Firebase Auth
  static Future<void> _deleteFromFirebaseAuth(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        print("✅ Compte Firebase Auth supprimé");
      }
    } on FirebaseAuthException catch(e) {
      if (e.code == "requires-recent-login"){
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text(
              '⚠️ Vérification',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'Veuillez vous déconnecter et vous reconnecter à nouveau pour supprimer votre compte.',
            ),
            actions: [
              // TextButton(
              //   onPressed: () => Navigator.pop(context),
              //   child: const Text('Annuler'),
              // ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async{
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: const Text('SE DECONNECTER'),
              ),
            ],
          ),
        );
      }
    }
    catch (e) {
      print("⚠️ Erreur suppression Firebase Auth: $e");
      // Si l'utilisateur n'est pas connecté, on continue
      rethrow;
    }
  }

  /// Supprime toutes les données locales (SharedPreferences)
  static Future<void> _deleteLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Liste de toutes les clés à supprimer
      final keysToDelete = [
        'user_email',
        'user_name',
        'user_photo_url',
        'user_id',
        'user_statut',
        'user_db_id',
        'is_logged_in',
        'is_livreur',
        'livreur_id',
        'cartItems',
        'orderHistory',
        'onboarding_done',
        // Supprimer aussi les caches de produits
      ];

      // Supprimer les clés spécifiques
      for (final key in keysToDelete) {
        await prefs.remove(key);
      }

      // Supprimer les caches de produits (format: cached_products_$email)
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('cached_products_') || 
            key.startsWith('cachedProductsData')) {
          await prefs.remove(key);
        }
      }

      // Optionnel : Supprimer toutes les données (plus radical)
      // await prefs.clear();

      print("✅ Données locales supprimées");
    } catch (e) {
      print("⚠️ Erreur suppression données locales: $e");
    }
  }

  /// Vérifie si l'utilisateur peut supprimer son compte
  /// (par exemple, s'il n'a pas de commandes en cours)
  static Future<Map<String, dynamic>> canDeleteAccount({
    required String firebaseUid,
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check_delete_user.php?firebase_uid=$firebaseUid&email=${Uri.encodeComponent(email)}'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'can_delete': data['can_delete'] ?? true,
          'message': data['message'] ?? '',
          'warnings': data['warnings'] ?? [],
        };
      }

      return {
        'can_delete': true,
        'message': '',
        'warnings': [],
      };
    } catch (e) {
      // En cas d'erreur, on autorise la suppression
      return {
        'can_delete': true,
        'message': '',
        'warnings': [],
      };
    }
  }
}

