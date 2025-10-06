import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importez vos autres dépendances (constantes, ProductCategory, etc.)

// ⚠️ NOUVEL ÉCRAN DE MODIFICATION
class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  // L'écran nécessite les données du produit à l'initialisation
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  bool _isUpdating = false;
// Réutilisez vos constantes d'API depuis AddProductScreen
  final String _consumerKey = 'ck_898b353c3d1e748271c6e873948caaf87ec30d1e';
  final String _consumerSecret = 'cs_b2ee223b023699dd8de97b409a23b929963422c2';
  final String _baseUrl = "https://www.easykivu.com/wp/wp-json/wc/v3";

// ➡️ Fonction à placer dans la classe qui gère l'état de la liste des produits
Future<bool> _updateProduct(int productId, Map<String, dynamic> productData) async {
  final auth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
  final headers = {
    "Authorization": "Basic $auth",
    "Content-Type": "application/json",
  };

  try {
    final response = await http.put(
      // Utilisation de PUT avec l'ID du produit
      Uri.parse("$_baseUrl/products/$productId"),
      headers: headers,
      body: jsonEncode(productData),
    );

    print("=== RÉPONSE MISE À JOUR PRODUIT: ${response.statusCode} ===");

    if (response.statusCode == 200) {
      // La réponse de l'API WooCommerce pour une mise à jour réussie est 200 OK
      print("✅ Produit ID $productId mis à jour avec succès!");
      return true;
    } else {
      final error = jsonDecode(response.body);
      print("❌ Échec mise à jour: ${error['message']}");
      throw Exception("Erreur API: ${error['message']}");
    }
  } catch (e) {
    print("❌ EXCEPTION MISE À JOUR: $e");
    return false;
  }
}
  // Récupérer les données initiales
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _priceController = TextEditingController(text: widget.product['regular_price'] ?? '');
    _descriptionController = TextEditingController(text: widget.product['description'] ?? '');
    
    // ⚠️ TODO: Implémenter la logique pour charger la catégorie existante si nécessaire.
    // L'implémentation de la modification d'image est plus complexe et est omise ici.
  }

  // Nettoyer les contrôleurs
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ➡️ Fonction de Mise à Jour (utilise la fonction d'API _updateProduct)
  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final int productId = widget.product['id'];
      
      // Construire le payload de mise à jour (WooCommerce ne nécessite que les champs modifiés)
      final Map<String, dynamic> updateData = {
        "name": _nameController.text,
        "regular_price": _priceController.text,
        "description": _descriptionController.text,
        // ⚠️ TODO: Ajouter la catégorie sélectionnée ici si vous implémentez l'édition de catégorie
        // "categories": [{"id": selectedCategoryId}]
      };

      // ⚠️ ASSUMANT QUE VOUS AVEZ ACCÈS À _updateProduct.
      // Dans une architecture propre, cette logique devrait être dans un service.
      // Pour cet exemple, nous allons simuler l'appel à _updateProduct().
      final success = await _updateProduct(productId, updateData);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Produit mis à jour!"), backgroundColor: Colors.green),
          );
          // Retourner à l'écran précédent (Mes Produits)
          Navigator.of(context).pop(true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Échec de la mise à jour."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier : ${widget.product['name'] ?? 'Produit'}"),),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ➡️ Champ Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom du produit"),
                validator: (v) => v?.isEmpty ?? true ? "Nom requis" : null,
              ),
              const SizedBox(height: 16),
              
              // ➡️ Champ Prix
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v?.isEmpty ?? true ? "Prix requis" : null,
              ),
              const SizedBox(height: 16),
              
              // ➡️ Champ Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              
              // ➡️ Bouton de Sauvegarde
              ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Sauvegarder les modifications",
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