// user_service.dart - Service pour gérer les utilisateurs et leur statut

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api_config.dart';

class UserService {
  static const String baseUrl = ApiConfig.BASE_URL;
  
  // Enregistrer ou mettre à jour un utilisateur dans la base de données
  static Future<Map<String, dynamic>?> registerUser({
    required String firebaseUid,
    required String email,
    String? nom,
    String? photoUrl,
    String statut = 'client',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firebase_uid': firebaseUid,
          'email': email,
          'nom': nom,
          'photo_url': photoUrl,
          'statut': statut,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Sauvegarder le statut dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_statut', data['user']['statut']);
          await prefs.setInt('user_db_id', data['user']['id']);
          
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'utilisateur: $e');
      return null;
    }
  }

  // Récupérer les informations d'un utilisateur
  static Future<Map<String, dynamic>?> getUser({String? firebaseUid, String? email}) async {
    try {
      String url = '$baseUrl/get_user.php?';
      if (firebaseUid != null) {
        url += 'firebase_uid=$firebaseUid';
      } else if (email != null) {
        url += 'email=$email';
      } else {
        return null;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Sauvegarder le statut dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_statut', data['user']['statut']);
          await prefs.setInt('user_db_id', data['user']['id']);
          
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Récupérer le statut de l'utilisateur actuel via l'email
  static Future<String?> getUserStatut() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return null;
      
      // 💡 NOUVEAU : Vérifier d'abord le cache
      final prefs = await SharedPreferences.getInstance();
      String? statut = prefs.getString('user_statut');
      
      // Si le statut n'est pas en cache, le récupérer depuis l'API via l'email
      if (statut == null) {
        final userData = await getUserByEmail(user.email!);
        statut = userData?['statut'];
        if (statut != null) {
          await prefs.setString('user_statut', statut);
        }
      }
      
      return statut;
    } catch (e) {
      print('Erreur lors de la récupération du statut: $e');
      return null;
    }
  }
  
  // 💡 NOUVEAU : Récupérer un utilisateur par email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final url = '$baseUrl/get_user.php?email=${Uri.encodeComponent(email)}';
      print("🌐 Appel API: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print("📡 Réponse HTTP: ${response.statusCode}");
      print("📄 Corps de la réponse: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 Données décodées: $data");
        
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          print("👤 Utilisateur trouvé: ${user['email']}, Statut: ${user['statut']}");
          
          // Sauvegarder le statut dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_statut', user['statut'] ?? 'client');
          await prefs.setInt('user_db_id', user['id'] ?? 0);
          
          return user;
        } else {
          print("⚠️ Utilisateur non trouvé ou success = false");
        }
      } else {
        print("❌ Erreur HTTP: ${response.statusCode}");
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la récupération de l\'utilisateur par email: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Vérifier si l'utilisateur est vendeur
  static Future<bool> isVendeur() async {
    final statut = await getUserStatut();
    return statut == 'vendeur';
  }

  // Vérifier si l'utilisateur est client
  static Future<bool> isClient() async {
    final statut = await getUserStatut();
    return statut == 'client' || statut == null; // Par défaut, client
  }

  // 💡 NOUVEAU : Vérifier si l'utilisateur est livreur via firebase_uid
  static Future<bool> isLivreur() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/check_livreur.php?firebase_uid=${user.uid}'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['is_livreur'] == true) {
          // Sauvegarder l'info dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_livreur', true);
          if (data['livreur'] != null) {
            await prefs.setInt('livreur_id', data['livreur']['id']);
          }
          return true;
        }
      }
      
      // Sauvegarder que ce n'est pas un livreur
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_livreur', false);
      return false;
    } catch (e) {
      print('Erreur lors de la vérification livreur: $e');
      return false;
    }
  }
  
  // 💡 NOUVEAU : Vérifier si l'utilisateur est livreur via l'email
  static Future<bool> isLivreurByEmail(String email) async {
    try {
      final url = '$baseUrl/check_livreur.php?email=${Uri.encodeComponent(email)}';
      print("🌐 Appel API livreur: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print("📡 Réponse HTTP livreur: ${response.statusCode}");
      print("📄 Corps de la réponse livreur: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 Données décodées livreur: $data");
        
        if (data['success'] == true && data['is_livreur'] == true) {
          // Sauvegarder l'info dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_livreur', true);
          if (data['livreur'] != null) {
            await prefs.setInt('livreur_id', data['livreur']['id']);
          }
          print("✅ Utilisateur est livreur (vérifié via email: $email)");
          return true;
        } else {
          print("⚠️ is_livreur = false ou success = false");
        }
      } else {
        print("❌ Erreur HTTP livreur: ${response.statusCode}");
      }
      
      // Sauvegarder que ce n'est pas un livreur
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_livreur', false);
      print("❌ Utilisateur n'est pas livreur (email: $email)");
      return false;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la vérification livreur par email: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Enregistrer l'utilisateur après connexion Firebase
  static Future<void> registerUserAfterLogin(User user) async {
    try {
      print("📝 Enregistrement de l'utilisateur dans la base de données: ${user.email}");
      final result = await registerUser(
        firebaseUid: user.uid,
        email: user.email ?? '',
        nom: user.displayName,
        photoUrl: user.photoURL,
        statut: 'client', // Par défaut, tous les nouveaux utilisateurs sont clients
      );
      
      if (result != null) {
        print("✅ Utilisateur enregistré/mis à jour avec succès: ${result['email']} (Statut: ${result['statut']})");
      } else {
        print("⚠️ Échec de l'enregistrement de l'utilisateur");
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement après connexion: $e');
      // Ne pas bloquer la connexion si l'enregistrement échoue
      // L'utilisateur pourra toujours utiliser l'app
    }
  }
}

