import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importez vos styles si nécessaire
// import 'package:soko/style.dart'; 

// =======================================================
// ⚠️ CONSTANTES DE CONFIGURATION - À METTRE À JOUR
// =======================================================
// CLÉS WOOCOMMERCE (UTILISÉES POUR L'API WC /wc/v2)
const String _consumerKey = 'ck_20c9eaf44a30b5028558551525a1b24201ce8293';
const String _consumerSecret = 'cs_d2f987d16ac480a59f04a5fefdf563a269667ca3';

// IDENTIFIANTS POUR L'API MEDIA (UTILISÉES POUR L'API WP /wp/v2/media)
// Remplacez ces valeurs par le nom d'utilisateur/email et le mot de passe d'application généré.
const String _mediaUsername = "info@babutik.com"; 
const String _mediaPassword = "nQs5 LctW 9hyO Mm33 GB7n gyNQ"; 

// Points de terminaison
const String _baseUrl = "https://www.babutik.com";
const String _wcApiPath = "/wp-json/wc/v2";
const String _wpApiPath = "/wp-json/wp/v2";

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
  const AddProductScreen({super.key});

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

  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory;
  bool _isLoadingCategories = true;
  String? _categoryError;

  // En-têtes d'authentification précalculés
  late final Map<String, String> _wcAuthHeaders;
  late final Map<String, String> _mediaAuthHeaders;

  @override
  void initState() {
    super.initState();
    // 1. Calcul de l'en-tête Basic Auth pour l'API WooCommerce (WC)
    final wcAuth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    _wcAuthHeaders = {"Authorization": "Basic $wcAuth"};

    // 2. Calcul de l'en-tête Basic Auth pour l'API Media (WP)
    final mediaAuth = base64Encode(utf8.encode("$_mediaUsername:$_mediaPassword"));
    _mediaAuthHeaders = {"Authorization": "Basic $mediaAuth"};

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
  // 🔄 LOGIQUE DE RÉCUPÉRATION DES CATÉGORIES (WooCommerce)
  // =======================================================
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl$_wcApiPath/products/categories?per_page=100"),
        headers: _wcAuthHeaders, // Utilisation des clés WC
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _categories =
            jsonList.map((json) => ProductCategory.fromJson(json)).toList();
      } else {
        throw Exception(
            "Échec du chargement des catégories: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur de récupération des catégories: $e");
      _categoryError = "Erreur de chargement des catégories. Vérifiez les clés WC.";
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
  // 📤 UPLOAD IMAGE AVEC MOT DE PASSE D'APPLICATION (WP REST API)
  // =======================================================
  Future<int?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      print("📷 Tentative d'upload d'image avec Mot de passe d'application...");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl$_wpApiPath/media"), // API Media de WordPress
      );

      // Utilisation des en-têtes d'auth du Mot de passe d'application
      request.headers.addAll({
        'Content-Disposition': 'attachment; filename="${_selectedImage!.name}"',
        'Content-Type': 'image/jpeg', 
        ..._mediaAuthHeaders, // Utilisation des clés WP Media
      });
      
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
        print("✅ IMAGE UPLOADÉE AVEC SUCCÈS (ID: ${jsonResponse['id']})");
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

    try {
      // 1. Uploader l'image
      int? imageId;
      if (_selectedImage != null) {
        imageId = await _uploadImage();
        if (_selectedImage != null && imageId == null) {
           // Si l'image a été sélectionnée mais l'upload a échoué, on arrête.
           throw Exception("Échec de l'upload d'image. Arrêt de la création du produit.");
        }
      }

      // 2. Préparer les données du produit
      final Map<String, dynamic> productData = {
        "name": _nameController.text,
        "type": "simple",
        "regular_price": _priceController.text,
        "description": _descriptionController.text,
        "status": "publish",
        "categories": [
          {"id": _selectedCategory!.id}
        ],
        // MÉTADONNÉES (pour le vendeur)
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
        Uri.parse("$_baseUrl$_wcApiPath/products"),
        // Fusionner les en-têtes WC avec l'en-tête Content-Type JSON
        headers: {..._wcAuthHeaders, "Content-Type": "application/json"},
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
                hasImage ? "✅ Produit créé avec image!" : "✅ Produit créé sans image.",
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
            content: Text("Erreur de publication: $e"),
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
    });
  }

  // =======================================================
  // 📐 INTERFACE UTILISATEUR
  // =======================================================
  @override
  Widget build(BuildContext context) {
    // Note: 'primaryYellow' n'étant pas défini, j'utilise une couleur standard.
    final Color primaryYellow = Colors.yellow.shade700; 
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Ajouter un produit"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ℹ️ Instructions 
              Card(
                color: Colors.blue.shade700,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📋 Configuration requise:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text("1. Clés WC pour Produits/Catégories.",
                          style: TextStyle(color: Colors.white)),
                      Text("2. Mot de passe d'application pour l'Upload d'image (WP API).",
                          style: TextStyle(color: Colors.white)),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              const Text("Catégorie du produit :",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _isLoadingCategories
                  ? const LinearProgressIndicator()
                  : _categoryError != null
                      ? Text(_categoryError!,
                          style: const TextStyle(color: Colors.red))
                      : DropdownButtonFormField<ProductCategory>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          hint: const Text("Sélectionnez une catégorie"),
                          value: _selectedCategory,
                          validator: (v) =>
                              v == null ? "Catégorie requise" : null,
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
                label: Text(_selectedImage == null
                    ? "Choisir une image"
                    : "Changer l'image"),
              ),

              const SizedBox(height: 24),

              // 🟢 Bouton de publication
              ElevatedButton(
                onPressed: _isPublishing ? null : _createProductWithImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isPublishing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text("Publication...",
                              style: TextStyle(color: Colors.white)),
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