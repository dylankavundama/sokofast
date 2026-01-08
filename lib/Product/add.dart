import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:soko/l10n/app_localizations.dart';

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
        final loc = AppLocalizations.of(context);
        print("❌ ÉCHEC UPLOAD: ${jsonResponse['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.addImageUploadError(jsonResponse['message'])),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
    } catch (e) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasImage ? loc.addProductCreatedWithImage : loc.addProductCreatedWithoutImage,
              ),
              backgroundColor: hasImage ? Colors.green : Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _resetForm();
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
    final loc = AppLocalizations.of(context);
    final Color primaryYellow = Colors.yellow.shade700; 
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(loc.addProductTitle),
      ),
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
    );
  }
}