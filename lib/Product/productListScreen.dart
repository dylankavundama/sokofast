import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // NOUVEL IMPORT SHIMMER
import 'package:soko/Product/productCard.dart'; 
import 'package:soko/style.dart'; // Contient 'loading' et 'primaryYellow'

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // Clé pour le stockage dans SharedPreferences
  static const String _productsCacheKey = 'cachedProductsData';

  Map<String, List<dynamic>> categorizedProducts = {};
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, List<dynamic>> filteredProducts = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = categorizedProducts;
        _isSearching = false;
      });
      return;
    }

    Map<String, List<dynamic>> results = {};
    categorizedProducts.forEach((category, products) {
      List<dynamic> matchedProducts = products.where((product) {
        // Recherche insensible à la casse dans le nom du produit
        String name = product['name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      if (matchedProducts.isNotEmpty) {
        results[category] = matchedProducts;
      }
    });

    setState(() {
      filteredProducts = results;
      _isSearching = true;
    });
  }
  
  // Fonction utilitaire pour traiter les données (en ligne ou en cache) et mettre à jour l'état
  void _updateProductState(List<dynamic> data) {
    Map<String, List<dynamic>> grouped = {};

    for (var product in data) {
      List categories = product['categories'];
      // S'assurer que le produit a au moins une catégorie
      if (categories.isEmpty) continue;

      for (var cat in categories) {
        String name = cat['name'];
        if (!grouped.containsKey(name)) grouped[name] = [];
        grouped[name]!.add(product);
      }
    }

    setState(() {
      categorizedProducts = grouped;
      filteredProducts = grouped;
      isLoading = false;
      errorMessage = ''; // Réinitialiser l'erreur après un chargement réussi
    });
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Réinitialiser avant la nouvelle tentative
    });
    
    final prefs = await SharedPreferences.getInstance();

    try {
      // Tenter de récupérer les produits depuis l'API (connexion)
      final response = await http.get(
        Uri.parse(
              'https://www.babutik.com/wp-json/wc/v3/products?per_page=100'),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('ck_20c9eaf44a30b5028558551525a1b24201ce8293:cs_d2f987d16ac480a59f04a5fefdf563a269667ca3'))}',
          }
      );

      if (response.statusCode == 200) {
        // TÉLÉCHARGEMENT RÉUSSI: Mettre à jour le cache et afficher
        await prefs.setString(_productsCacheKey, response.body); 

        final data = json.decode(response.body) as List<dynamic>;
        _updateProductState(data); 
        
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      // ÉCHEC DU TÉLÉCHARGEMENT (Erreur réseau ou exception)
      
      final cachedDataString = prefs.getString(_productsCacheKey);
      
      if (cachedDataString != null && cachedDataString.isNotEmpty) {
        // Si le cache existe, l'utiliser et notifier l'utilisateur
        final data = json.decode(cachedDataString) as List<dynamic>;
        _updateProductState(data);
        
        setState(() {
           isLoading = false;
           errorMessage = 'Mode hors ligne activé. Données potentiellement obsolètes.';
        });
        
      } else {
        // Pas de connexion ET pas de cache : Afficher une erreur critique
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur de connexion et aucune donnée locale disponible.';
        });
      }
    }
    // Note: Le finally a été retiré car isLoading est géré dans chaque branche de la logique.
  }

  @override
  Widget build(BuildContext context) {
    final bool isProductListEmpty = filteredProducts.isEmpty && !isLoading;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: _searchProducts,
              )
            : Image.asset(height: 55, 'assets/icon.png'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: primaryYellow,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  filteredProducts = categorizedProducts;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      // --- REMPLACEMENT DU WIDGET 'loading()' PAR LE SHIMMER ---
      body: isLoading
          ? const ShimmerLoadingList()
          : isProductListEmpty && errorMessage.isEmpty
              ? Center(child: Text(_isSearching ? 'Aucun produit trouvé pour cette recherche.' : 'Aucun produit n\'est disponible.'))
              : RefreshIndicator(
                  onRefresh: fetchProducts,
                  child: Column(
                    children: [
                      // Affichage du message d'erreur ou du mode hors ligne en haut
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: errorMessage.contains('Mode hors ligne') ? Colors.orange : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      // Liste des produits si elle n'est pas vide
                      if (!isProductListEmpty)
                        Expanded(
                          child: ListView(
                            children: filteredProducts.entries.map((entry) {
                              final categoryName = entry.key;
                              final products = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 260,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 160,
                                          margin:
                                              const EdgeInsets.symmetric(horizontal: 8),
                                          child: ProductCard(product: products[index]),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// -----------------------------------------------------------------
// NOUVEAU WIDGET SHIMMER POUR SIMULER L'AFFICHAGE PENDANT LE CHARGEMENT
// -----------------------------------------------------------------

class ShimmerLoadingList extends StatelessWidget {
  const ShimmerLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    // Couleurs claires pour l'effet Shimmer
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (i) { // Simule 3 sections de catégories
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Simuler le Titre de Catégorie
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                // 2. Simuler la Liste Horizontale (Row de ProductCard)
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4, // Simule 4 produits par catégorie
                    itemBuilder: (context, index) {
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Simuler l'Image (grande boîte)
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Simuler le Nom du Produit (Ligne 1)
                            Container(
                              width: double.infinity,
                              height: 10,
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            // Simuler le Nom du Produit (Ligne 2)
                            Container(
                              width: 80,
                              height: 10,
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            const SizedBox(height: 8),
                            // Simuler le Prix
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }
}