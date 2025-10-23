import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:soko/style.dart';
import 'dart:convert';
import 'category_item.dart';
import 'products_by_category_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // Importation nécessaire pour Shimmer

// Clé de cache pour les catégories
const String _categoriesCacheKey = 'cachedCategoriesData';

Future<void> addActivity(String message) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> activities = prefs.getStringList('activities') ?? [];
  activities.insert(0, message); // ajoute en haut
  if (activities.length > 30) {
    activities = activities.sublist(0, 30); // limite à 30
  }
  await prefs.setStringList('activities', activities);
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fonction utilitaire pour mettre à jour l'état et traiter les données
  void _updateCategoryState(List<dynamic> data) {
    // Filtrer les catégories qui n'ont pas de nom, ou celles qui sont des catégories "non catégorisées" (id 0 ou 1)
    final filteredCategories = data.where((cat) {
      final name = cat['name']?.toString().toLowerCase() ?? '';
      return name.isNotEmpty && cat['id'] != 0 && cat['id'] != 1;
    }).toList();

    setState(() {
      _categories = filteredCategories;
      _isLoading = false;
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Tenter de récupérer les données via l'API (mode en ligne)
      final response = await http.get(
        Uri.parse('https://www.babutik.com/wp-json/wc/v3/products/categories'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('ck_20c9eaf44a30b5028558551525a1b24201ce8293:cs_d2f987d16ac480a59f04a5fefdf563a269667ca3'))}',
        },
      ).timeout(const Duration(seconds: 10)); // Timeout pour ne pas bloquer trop longtemps

      if (response.statusCode == 200) {
        // Succès : Mettre à jour le cache et l'état
        await prefs.setString(_categoriesCacheKey, response.body);
        final data = json.decode(response.body) as List<dynamic>;
        _updateCategoryState(data);
        
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      // 2. Échec de la connexion/API : Tenter de charger le cache
      final cachedDataString = prefs.getString(_categoriesCacheKey);
      
      if (cachedDataString != null && cachedDataString.isNotEmpty) {
        // Succès du cache : Utiliser les données locales et afficher un avertissement
        final data = json.decode(cachedDataString) as List<dynamic>;
        _updateCategoryState(data);

        setState(() {
           _errorMessage = 'Mode hors ligne activé. Données potentiellement obsolètes.';
        });
        
      } else {
        // Échec total : Pas de connexion et pas de cache
        setState(() {
          _errorMessage = 'Erreur de connexion et aucune donnée locale disponible.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: backdColor,
        title: const Text(
          'Catégories',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        child: Column(
          children: [
            // Affichage du message d'erreur ou d'avertissement hors ligne
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: _errorMessage.contains('Mode hors ligne') ? Colors.orange : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Contenu principal (Chargement, Erreur ou Grille)
            Expanded(
              child: _isLoading
                  ? const ShimmerCategoryGrid() // UTILISATION DU SHIMMER
                  : _categories.isEmpty && _errorMessage.isEmpty
                      ? const Center(child: Text('Aucune catégorie disponible.'))
                      : GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return CategoryItem(
                                category: category,
                                onTap: () {
                                  addActivity('Catégorie consultée: ${category['name']}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductsByCategoryScreen(
                                        categoryId: category['id'],
                                        categoryName: category['name'],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// WIDGET SHIMMER POUR SIMULER LA GRILLE DE CATÉGORIES
// -----------------------------------------------------------------

class ShimmerCategoryGrid extends StatelessWidget {
  const ShimmerCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Couleurs pour l'effet Shimmer
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        physics: const NeverScrollableScrollPhysics(), // Empêche le défilement
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: 6, // Simule un nombre fixe de catégories
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simuler l'Image/Icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                const SizedBox(height: 10),
                // Simuler le Nom de la Catégorie
                Container(
                  width: 100,
                  height: 15,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}