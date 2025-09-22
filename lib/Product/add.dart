import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// IMPORTANT: Remplacez ces valeurs par vos propres clés API et l'URL de votre site.
// AVERTISSEMENT: Ne laissez JAMAIS de clés API en clair dans une application en production.
// Utilisez des variables d'environnement ou un service de configuration sécurisé.
const String _consumerKey = 'ck_ad48e33210f0327f5126c4bb84d79ba833080d52';
const String _consumerSecret = 'cs_2ec17813a81fb24e2ef4029223cc8e45f3764e0a';
const String _baseUrl = 'https://www.babutik.com/wp-json/wc/v3';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Map<String, dynamic>? _selectedCategory;
  List<dynamic> _apiCategories = [];
  bool _isCategoriesLoading = true;
  bool _isPublishing = false;
  
  XFile? _selectedImage;

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

  // Fonction pour récupérer les catégories depuis l'API WooCommerce
  Future<void> _fetchCategories() async {
    try {
      final auth = utf8.encode('$_consumerKey:$_consumerSecret');
      final headers = {
        'Authorization': 'Basic ${base64Encode(auth)}',
      };
      
      final response = await http.get(
        Uri.parse('$_baseUrl/products/categories?per_page=100'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _apiCategories = data;
          _isCategoriesLoading = false;
        });
      } else {
        setState(() {
          _isCategoriesLoading = false;
        });
        if (mounted) {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de chargement des catégories: ${errorData['message']}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau lors du chargement des catégories : ${e.toString()}')),
        );
      }
    }
  }

  // Fonction pour choisir une seule image depuis la galerie
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Fonction pour télécharger l'image vers l'API WordPress Media
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return null;
    }
    final auth = utf8.encode('$_consumerKey:$_consumerSecret');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(auth)}',
    };
    
    final bytes = await _selectedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final mediaData = {
      'title': _selectedImage!.name,
      'status': 'publish',
      'media_file': base64Image,
    };

    try {
      final response = await http.post(
        Uri.parse('https://www.babutik.com/wp-json/wp/v2/media'),
        headers: headers,
        body: jsonEncode(mediaData),
      );
      
      if (response.statusCode == 201) {
        final imageData = json.decode(response.body);
        return imageData['source_url'];
      } else {
        // Afficher la réponse exacte du serveur pour le débogage
        print('Erreur serveur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        
        final errorData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de téléchargement d\'image : ${errorData['message']}')),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau lors du téléchargement : ${e.toString()}')),
        );
      }
      return null;
    }
  }

  // Fonction pour insérer le produit via l'API
  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une image.')),
        );
      }
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final String? imageUrl = await _uploadImage();
    if (imageUrl == null) {
      setState(() { _isPublishing = false; });
      return;
    }
    
    final productData = {
      'name': _nameController.text,
      'type': 'simple',
      'regular_price': _priceController.text,
      'description': _descriptionController.text,
      'categories': [
        if (_selectedCategory != null) {'id': _selectedCategory!['id']}
      ],
      'images': [{'src': imageUrl}],
      'status': 'publish',
    };

    final auth = utf8.encode('$_consumerKey:$_consumerSecret');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(auth)}',
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: headers,
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit créé avec succès !')),
          );
        }
        _formKey.currentState!.reset();
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedImage = null;
        });
      } else {
        if (mounted) {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${errorData['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le prix';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              if (_isCategoriesLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: _apiCategories.map((category) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: category,
                      child: Text(category['name'] as String),
                    );
                  }).toList(),
                  onChanged: (Map<String, dynamic>? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner une catégorie';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              if (_selectedImage != null)
                Center(
                  child: Stack(
                    children: [
                      Image.file(
                        File(_selectedImage!.path),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Choisir une image'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isPublishing ? null : _createProduct,
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajouter le produit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
