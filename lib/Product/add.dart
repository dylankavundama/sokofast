import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:soko/Profil/mes_produits.dart';

const String _consumerKey = 'ck_898b353c3d1e748271c6e873948caaf87ec30d1e';
const String _consumerSecret = 'cs_b2ee223b023699dd8de97b409a23b929963422c2';
const String _baseUrl = "https://www.easykivu.com/wp/wp-json/wc/v3";

// ⚠️ REMPLACEZ AVEC VOS VRAIES IDENTIFIANTS WORDPRESS
const String _wpUsername = "admin"; // Votre email ou username WordPress
const String _wpPassword =  "igUA 9IIx Vqhg cuXj k1qR ggZ7";

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  // ✅ OBTAIN JWT TOKEN
  Future<bool> _getJWTToken() async {
    try {
      print("🔐 Tentative de connexion JWT...");
      
      final response = await http.post(
        Uri.parse("https://www.easykivu.com/wp/wp-json/jwt-auth/v1/token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _wpUsername,
          'password': _wpPassword,
        }),
      );

      print("🔐 JWT Response Status: ${response.statusCode}");
      print("🔐 JWT Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        print("✅ JWT Token obtenu avec succès");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Erreur JWT: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Exception JWT: $e");
      return false;
    }
  }

  // ✅ UPLOAD IMAGE WITH JWT
  Future<int?> _uploadImageWithJWT() async {
    if (_selectedImage == null) return null;

    // Obtenir le token JWT si pas déjà fait
    if (_jwtToken == null) {
      final success = await _getJWTToken();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Échec authentification WordPress"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    print("🔄 Upload image avec JWT...");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://www.easykivu.com/wp/wp-json/wp/v2/media"),
      );
      
      request.headers['Authorization'] = 'Bearer $_jwtToken';
      
      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      print("=== RÉPONSE UPLOAD IMAGE ===");
      print("📋 Status: ${response.statusCode}");
      
      if (response.statusCode == 201) {
        print("✅ IMAGE UPLOADÉE AVEC SUCCÈS");
        print("🆔 ID Image: ${jsonResponse['id']}");
        print("🔗 URL: ${jsonResponse['source_url']}");
        return jsonResponse['id'];
      } else {
        print("❌ ÉCHEC UPLOAD: ${jsonResponse['message']}");
        print("💡 Code erreur: ${jsonResponse['code']}");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur upload: ${jsonResponse['message']}"),
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

  // ✅ CRÉATION PRODUIT WOOCOMMERCE
  Future<void> _createProductWithImage() async {
    if (!_formKey.currentState!.validate()) return;

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
        
        if (imageId == null) {
          // Si l'upload échoue, créer le produit sans image
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Produit créé sans image - ajoutez-la manuellement"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // 2. Créer le produit
// Dans _createProduct(), modifiez productData :
final Map<String, dynamic> productData = {
  "name": _nameController.text,
  "type": "simple",
  "regular_price": _priceController.text,
  "description": _descriptionController.text,
  "status": "publish",
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
        productData["images"] = [{"id": imageId}];
      }

      final response = await http.post(
        Uri.parse("$_baseUrl/products"),
        headers: headers,
        body: jsonEncode(productData),
      );

      print("=== RÉPONSE PRODUIT ===");
      print("Status: ${response.statusCode}");

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
        throw Exception("Erreur création produit: ${response.body}");
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

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _jwtToken = null;
    });
  }

  // ✅ TEST DE CONNEXION
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter Produit + Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.production_quantity_limits_outlined),
            onPressed: (){

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyProductsScreen()));
            },
            tooltip: "Tester connexion WordPress",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Instructions
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📋 Configuration requise:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text("1. Plugin 'JWT Authentication' activé"),
                      Text("2. Clé JWT dans wp-config.php"),
                      Text("3. Identifiants WordPress corrects"),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom du produit"),
                validator: (v) => v?.isEmpty ?? true ? "Nom requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v?.isEmpty ?? true ? "Prix requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              if (_selectedImage != null)
                Image.file(File(_selectedImage!.path), height: 150),
              
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Choisir une image"),
              ),
              
              const SizedBox(height: 24),
              
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
                        "Créer le produit avec image",
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