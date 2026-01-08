


// lib/services/ville_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
 
import '../api_config.dart';
// lib/models/ville.dart
class Ville {
  final int id;
  final String nom;

  Ville({required this.id, required this.nom});

  factory Ville.fromJson(Map<String, dynamic> json) {
    return Ville(
      id: json['id'],
      nom: json['nom'],
    );
  }
}
class VilleService {
  static Future<List<Ville>> getVillesDisponibles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}/villes.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ville.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des villes');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}

String initServer = 'www.sokofast.com/backend';
const String baseUrl = 'https://www.sokofast.com/backend';
