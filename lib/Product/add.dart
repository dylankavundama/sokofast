import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
<<<<<<< Updated upstream
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Profil/mes_produits.dart';
import 'package:soko/services/user_service.dart';
import 'package:soko/utils/responsive.dart';
// Importez vos styles si nécessaire
// import 'package:soko/style.dart'; 
=======
import 'package:soko/l10n/app_localizations.dart';
>>>>>>> Stashed changes

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
  bool _isCheckingStatus = true; // 💡 NOUVEAU : Indicateur de vérification du statut vendeur

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
    final wcAuth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    _wcAuthHeaders = {"Authorization": "Basic $wcAuth"};
    final mediaAuth = base64Encode(utf8.encode("$_mediaUsername:$_mediaPassword"));
    _mediaAuthHeaders = {"Authorization": "Basic $mediaAuth"};

    _fetchCategories();
    _checkVendeurStatus(); // 💡 NOUVEAU : Vérifier le statut vendeur
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl$_wcApiPath/products/categories?per_page=100"),
        headers: _wcAuthHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _categories =
            jsonList.map((json) => ProductCategory.fromJson(json)).toList();
      } else {
        final loc = AppLocalizations.of(context);
        throw Exception(
            loc.addCategoryLoadFailed(response.statusCode.toString()));
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _categoryError = loc.addCategoryError;
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<int?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
<<<<<<< Updated upstream
      // Vérifier la taille du fichier avant l'upload (limite: 20 Mo)
      final file = File(_selectedImage!.path);
      final fileSize = await file.length();
      const maxSize = 20 * 1024 * 1024; // 20 Mo en bytes
      
      if (fileSize > maxSize) {
        final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        print("❌ Fichier trop volumineux: $sizeInMB Mo (limite: 20 Mo)");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("L'image est trop volumineuse ($sizeInMB Mo). Veuillez choisir une image de moins de 20 Mo."),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return null;
      }

      print("📷 Tentative d'upload d'image (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} Mo)...");
=======
>>>>>>> Stashed changes
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl$_wpApiPath/media"),
      );

      request.headers.addAll({
        'Content-Disposition': 'attachment; filename="${_selectedImage!.name}"',
        'Content-Type': 'image/jpeg', 
        ..._mediaAuthHeaders,
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
<<<<<<< Updated upstream
        String errorMessage = jsonResponse['message'] ?? 'Erreur inconnue';
        
        // Messages d'erreur plus explicites
        if (errorMessage.contains('upload_max_filesize') || errorMessage.contains('exceeds')) {
          errorMessage = 'L\'image est trop volumineuse. Limite actuelle: 20 Mo. Veuillez réduire la taille de l\'image ou contacter l\'administrateur pour augmenter la limite.';
        } else if (errorMessage.contains('post_max_size')) {
          errorMessage = 'Les données envoyées sont trop volumineuses (limite: 25 Mo). Veuillez réduire la taille de l\'image.';
        }
        
        print("❌ ÉCHEC UPLOAD: $errorMessage");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur upload image: $errorMessage"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
=======
        final loc = AppLocalizations.of(context);
        print("❌ ÉCHEC UPLOAD: ${jsonResponse['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.addImageUploadError(jsonResponse['message'])),
              backgroundColor: Colors.orange,
>>>>>>> Stashed changes
            ),
          );
        }
        return null;
      }
    } catch (e) {
<<<<<<< Updated upstream
      String errorMsg = 'Erreur lors de l\'upload de l\'image';
      if (e.toString().contains('upload_max_filesize') || e.toString().contains('exceeds')) {
        errorMsg = 'L\'image est trop volumineuse. Limite actuelle: 20 Mo. Veuillez réduire la taille de l\'image.';
      }
      print("❌ EXCEPTION UPLOAD: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
=======
>>>>>>> Stashed changes
      return null;
    }
  }

  Future<void> _createProductWithImage() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.addCategoryRequiredWarning),
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
        final loc = AppLocalizations.of(context);
        imageId = await _uploadImage();
        if (_selectedImage != null && imageId == null) {
           // Si l'image a été sélectionnée mais l'upload a échoué, on arrête.
           throw Exception(loc.addImageUploadFailed);
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

      if (imageId != null) {
        productData["images"] = [
          {"id": imageId}
        ];
      }

      final response = await http.post(
        Uri.parse("$_baseUrl$_wcApiPath/products"),
        headers: {..._wcAuthHeaders, "Content-Type": "application/json"},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        final product = jsonDecode(response.body);
        final hasImage = product['images'] != null && product['images'].isNotEmpty;

        final loc = AppLocalizations.of(context);
        if (mounted) {
          // 💡 NOUVEAU : S'assurer que l'email est sauvegardé dans SharedPreferences
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.email != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_email', currentUser.email!);
              await prefs.setString('user_name', currentUser.displayName ?? currentUser.email!.split('@')[0]);
              print("✅ Données utilisateur sauvegardées pour Mes Produits");
            } catch (e) {
              print("⚠️ Erreur sauvegarde utilisateur: $e");
            }
          }
          
          // 💡 NOUVEAU : Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasImage ? loc.addProductCreatedWithImage : loc.addProductCreatedWithoutImage,
              ),
              backgroundColor: hasImage ? Colors.green : Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 💡 NOUVEAU : Naviguer vers la page "Mes Produits" et actualiser
          // On utilise pushReplacement pour remplacer cette page par "Mes Produits"
          // La page "Mes Produits" se chargera automatiquement dans son initState
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyProductsScreen(),
            ),
          );
        }
      } else {
        final loc = AppLocalizations.of(context);
        final error = jsonDecode(response.body);
        throw Exception(loc.addProductCreationError(error['message']));
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.addPublicationError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

<<<<<<< Updated upstream
  // =======================================================
  // 💡 NOUVEAU : Vérifier si l'utilisateur est vendeur
  // =======================================================
  Future<void> _checkVendeurStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });
    
    final isVendeur = await UserService.isVendeur();
    if (!isVendeur) {
      // Si l'utilisateur n'est pas vendeur, rediriger vers le profil
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seuls les vendeurs peuvent ajouter des produits.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  // =======================================================
  // 🧹 NETTOYAGE DU FORMULAIRE
  // =======================================================
=======
>>>>>>> Stashed changes
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

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    // 💡 NOUVEAU : Afficher un loader pendant la vérification
    if (_isCheckingStatus) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Ajouter un produit"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Note: 'primaryYellow' n'étant pas défini, j'utilise une couleur standard.
=======
    final loc = AppLocalizations.of(context);
>>>>>>> Stashed changes
    final Color primaryYellow = Colors.yellow.shade700; 
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(loc.addProductTitle),
      ),
<<<<<<< Updated upstream
      body: Responsive.centerContent(
        context,
        Padding(
          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 📝 Champs de saisie
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nom du produit"),
                  validator: (v) => v?.isEmpty ?? true ? "Nom requis" : null,
                  style: TextStyle(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                  ),
                ),
                SizedBox(height: Responsive.getVerticalPadding(context) * 2),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Prix"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v?.isEmpty ?? true ? "Prix requis" : null,
                  style: TextStyle(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                  ),
                ),
                SizedBox(height: Responsive.getVerticalPadding(context) * 2),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: Responsive.isMobile(context) ? 3 : 5,
                  style: TextStyle(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                  ),
                ),
                SizedBox(height: Responsive.getVerticalPadding(context) * 2.5),
=======
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),

              // 📝 Champs de saisie
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: loc.addNameLabel),
                validator: (v) =>
                    v?.isEmpty ?? true ? loc.addNameRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: loc.addPriceLabel),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v?.isEmpty ?? true ? loc.addPriceRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: loc.addDescriptionLabel),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
>>>>>>> Stashed changes

              // 🏷️ SÉLECTION DE CATÉGORIE
              Text(loc.addCategoryLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          hint: Text(loc.addCategoryHint),
                          value: _selectedCategory,
                          validator: (v) =>
                              v == null ? loc.addCategoryRequired : null,
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
                    ? loc.addPickImage
                    : loc.addChangeImage),
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(width: 10),
                          Text(loc.addPublishing,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(
                        loc.addCreateButton,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
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