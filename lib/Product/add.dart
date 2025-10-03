import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// import 'package:soko/Profil/mes_produits.dart'; // Assurez-vous que ce chemin est correct

// =======================================================
// ⚠️ CONSTANTES DE CONFIGURATION - À DÉFINIR
// =======================================================
const String _consumerKey = 'ck_898b353c3d1e748271c6e873948caaf87ec30d1e';
const String _consumerSecret = 'cs_b2ee223b023699dd8de97b409a23b929963422c2';
const String _baseUrl = "https://www.easykivu.com/wp/wp-json/wc/v3";
const String _wpBaseUrl = "https://www.easykivu.com/wp";

// ⚠️ REMPLACEZ AVEC VOS VRAIS IDENTIFIANTS WORDPRESS (pour l'upload image/JWT)
const String _wpUsername = "admin"; // Votre email ou username WordPress
const String _wpPassword = "igUA 9IIx Vqhg cuXj k1qR ggZ7";

// =======================================================
// 📚 Modèle de Catégorie (simplifié)
// =======================================================
class ProductCategory {
  final int id;
  final String name;

  ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

// =======================================================
// 🚀 ÉCRAN D'AJOUT DE PRODUIT
// =======================================================
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _selectedImage;
  bool _isPublishing = false;
  String? _jwtToken;

  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory;
  bool _isLoadingCategories = true;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =======================================================
  // 🔄 LOGIQUE DE RÉCUPÉRATION DES CATÉGORIES
  // =======================================================
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final auth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
      final response = await http.get(
        Uri.parse("$_baseUrl/products/categories?per_page=100"),
        headers: {"Authorization": "Basic $auth"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _categories = jsonList
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        // Optionnel : Sélectionner la première catégorie par défaut
        // _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur de récupération des catégories: $e");
      _categoryError = "Erreur de chargement des catégories: $e";
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // =======================================================
  // 🖼️ LOGIQUE DE SÉLECTION D'IMAGE
  // =======================================================
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  // =======================================================
  // 🔑 OBTAIN JWT TOKEN
  // =======================================================
  Future<bool> _getJWTToken() async {
    if (_jwtToken != null) return true; // Token déjà obtenu

    try {
      print("🔐 Tentative de connexion JWT...");
      final response = await http.post(
        Uri.parse("$_wpBaseUrl/wp-json/jwt-auth/v1/token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _wpUsername,
          'password': _wpPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        print("✅ JWT Token obtenu avec succès");
        return true;
      } else {
        print("❌ Erreur JWT: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Exception JWT: $e");
      return false;
    }
  }

  // =======================================================
  // 📤 UPLOAD IMAGE WITH JWT
  // =======================================================
  Future<int?> _uploadImageWithJWT() async {
    if (_selectedImage == null) return null;

    if (!await _getJWTToken()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Échec authentification WordPress pour l'image"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_wpBaseUrl/wp-json/wp/v2/media"),
      );
      request.headers['Authorization'] = 'Bearer $_jwtToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 201) {
        print("✅ IMAGE UPLOADÉE AVEC SUCCÈS");
        return jsonResponse['id'];
      } else {
        print("❌ ÉCHEC UPLOAD: ${jsonResponse['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur upload image: ${jsonResponse['message']}"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      print("❌ EXCEPTION UPLOAD: $e");
      return null;
    }
  }

  // =======================================================
  // 📦 CRÉATION PRODUIT WOOCOMMERCE
  // =======================================================
  Future<void> _createProductWithImage() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Veuillez sélectionner une catégorie."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isPublishing = true);

    final auth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    final headers = {
      "Authorization": "Basic $auth",
      "Content-Type": "application/json",
    };

    try {
      // 1. Uploader l'image
      int? imageId;
      if (_selectedImage != null) {
        imageId = await _uploadImageWithJWT();
        // La gestion d'erreur de l'upload est déjà dans _uploadImageWithJWT
      }

      // 2. Préparer les données du produit
      final Map<String, dynamic> productData = {
        "name": _nameController.text,
        "type": "simple",
        "regular_price": _priceController.text,
        "description": _descriptionController.text,
        "status": "publish",
        // AJOUT DE LA CATÉGORIE
        "categories": [
          {"id": _selectedCategory!.id}
        ],
        // MÉTADONNÉES
        "meta_data": [
          {
            "key": "vendor_user_id",
            "value": FirebaseAuth.instance.currentUser?.uid ?? ""
          },
          {
            "key": "user_email",
            "value": FirebaseAuth.instance.currentUser?.email ?? ""
          }
        ]
      };

      // 3. Associer l'image si upload réussit
      if (imageId != null) {
        productData["images"] = [
          {"id": imageId}
        ];
      }

      // 4. Créer le produit
      final response = await http.post(
        Uri.parse("$_baseUrl/products"),
        headers: headers,
        body: jsonEncode(productData),
      );

      print("=== RÉPONSE PRODUIT: ${response.statusCode} ===");

      if (response.statusCode == 201) {
        final product = jsonDecode(response.body);
        final hasImage = product['images'] != null && product['images'].isNotEmpty;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasImage ? "✅ Produit créé avec image!" : "✅ Produit créé!",
              ),
              backgroundColor: hasImage ? Colors.green : Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _resetForm();
      } else {
        final error = jsonDecode(response.body);
        print("❌ Erreur création produit: ${error['message']}");
        throw Exception("Erreur création produit: ${error['message']}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  // =======================================================
  // 🧹 NETTOYAGE DU FORMULAIRE
  // =======================================================
  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _selectedCategory = null;
      _jwtToken = null; // Optionnel, forcer la nouvelle acquisition
    });
  }

  // =======================================================
  // 🧪 TEST DE CONNEXION WORDPRESS/JWT
  // =======================================================
  Future<void> _testConnection() async {
    final success = await _getJWTToken();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "✅ Connexion WordPress réussie!" : "❌ Échec connexion WordPress",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // =======================================================
  // 📐 INTERFACE UTILISATEUR
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("ajouter produit"),
        actions: [
          // Bouton pour Mes Produits (Assurez-vous que MyProductsScreen est importé)
          // IconButton(
          //   icon: const Icon(Icons.production_quantity_limits_outlined),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => MyProductsScreen()),
          //     );
          //   },
          //   tooltip: "Voir Mes Produits",
          // ),
          // IconButton(
          //   icon: const Icon(Icons.security_outlined),
          //   onPressed: _testConnection, // Utilisation de la fonction de test JWT
          //   tooltip: "Tester connexion WordPress (JWT)",
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ℹ️ Instructions (Raccourcies)
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📋 Configuration requise:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text("1. JWT Auth & REST API actifs.", style: TextStyle(color: Colors.white)),
                      Text("2. Identifiants WP corrects.", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📝 Champs de saisie
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom du produit"),
                validator: (v) => v?.isEmpty ?? true ? "Nom requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v?.isEmpty ?? true ? "Prix requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // 🏷️ SÉLECTION DE CATÉGORIE
              const Text("Catégorie du produit :", style: TextStyle(fontWeight: FontWeight.bold)),
              _isLoadingCategories
                  ? const LinearProgressIndicator()
                  : _categoryError != null
                      ? Text(_categoryError!, style: const TextStyle(color: Colors.red))
                      : DropdownButtonFormField<ProductCategory>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                          hint: const Text("Sélectionnez une catégorie"),
                          value: _selectedCategory,
                          validator: (v) => v == null ? "Catégorie requise" : null,
                          items: _categories.map((category) {
                            return DropdownMenuItem<ProductCategory>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (ProductCategory? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                        ),
              const SizedBox(height: 20),

              // 📸 Affichage et sélection de l'image
              if (_selectedImage != null)
                Column(
                  children: [
                    Image.file(File(_selectedImage!.path), height: 150),
                    const SizedBox(height: 10),
                  ],
                ),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_selectedImage == null ? "Choisir une image" : "Changer l'image"),
              ),

              const SizedBox(height: 24),

              // 🟢 Bouton de publication
              ElevatedButton(
                onPressed: _isPublishing ? null : _createProductWithImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isPublishing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text("Publication...", style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text(
                        "Créer le produit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}