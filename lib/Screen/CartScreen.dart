import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Importez vos fichiers de support
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/style.dart'; 
// Importez le fichier de configuration
 


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Contrôleurs de formulaire
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  
  // États locaux
  List<Map<String, dynamic>> cartItems = [];
  String? loggedInUserName;

  // Récupération des constantes FlexPay
  final String _FLEXPAY_GATEWAY_URL = ApiConfig.FLEXPAY_GATEWAY_URL;
  final String _MERCHANT_ID = ApiConfig.MERCHANT_ID;
  final String _BEARER_TOKEN = ApiConfig.BEARER_TOKEN;
  final String _CALLBACK_URL = '${ApiConfig.BASE_URL}/flexpay/callback'; 


  @override
  void initState() {
    super.initState();
    _loadCartLocally();
    _loadLoggedInUser();
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // LOGIQUE DE GESTION DE L'ÉTAT LOCAL ET UTILISATEUR
  // ------------------------------------------------------------------

  Future<void> _loadLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      loggedInUserName = user?.displayName;
    });
  }

  Future<void> _loadCartLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? encodedItems = prefs.getStringList('cartItems');
    if (encodedItems != null) {
      setState(() {
        cartItems = encodedItems
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _saveCartLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedItems =
        cartItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cartItems', encodedItems);
  }
  
  Future<void> _saveOrderToHistory(Map<String, dynamic> order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList('orderHistory') ?? [];
    orders.add(jsonEncode(order));
    await prefs.setStringList('orderHistory', orders);
  }

  // ------------------------------------------------------------------
  // LOGIQUE DE COMMANDE ET FLEXPAY
  // ------------------------------------------------------------------
  
  String _generateFlexPayReference() {
    // Génère une référence unique basée sur l'heure, sécurisée pour la BD
    return 'SOKO-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Fonction pour valider le format du numéro de téléphone (simple)
  bool _validatePhoneNumber(String phone) {
    // Exemple de validation simple : doit commencer par 243 et contenir 12 chiffres
    final RegExp phoneRegex = RegExp(r'^243[0-9]{9}$'); 
    return phoneRegex.hasMatch(phone);
  }


  Future<void> _initiateFlexPayTransaction(BuildContext context) async {
    final address = addressController.text;
    final name = loggedInUserName!;
    final clientPhoneNumber = phoneController.text.trim(); // Numéro dynamique

    if (!_validatePhoneNumber(clientPhoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format de numéro de téléphone invalide (Ex: 243812345678).')),
        );
        return;
    }

    final totalAmount = cartItems.fold(
      0.0,
      (sum, item) => sum + ((double.tryParse(item['product']['price'].toString()) ?? 0) * item['quantity']),
    );

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le montant total est nul ou négatif.')));
      return;
    }
    
    final String referenceId = _generateFlexPayReference();
    final String amountString = totalAmount.toStringAsFixed(0); 
    
    // 1. Préparation du corps de la requête FlexPay (Mobile Money)
    final requestBody = jsonEncode({
      "merchant": _MERCHANT_ID,
      "type": "1", // 1 pour Mobile Money
      "phone": clientPhoneNumber, 
      "reference": referenceId,
      "amount": amountString,
      "currency": "CDF", // Assurez-vous que c'est la bonne devise
      "callbackUrl": _CALLBACK_URL,
    });

    try {
      // 2. Envoi de la requête à la passerelle FlexPay
      final response = await http.post(
        Uri.parse(_FLEXPAY_GATEWAY_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_BEARER_TOKEN',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      final responseData = jsonDecode(response.body);
      final String code = responseData['code']?.toString() ?? '1';
      final String message = responseData['message'] ?? 'Erreur inconnue de la passerelle.';

      if (code == '0') {
        
        // 3. Enregistrer la commande comme PENDING dans la base de données
        await sendOrderToDatabase(
          context: context,
          name: name,
          address: address,
          transactionId: referenceId, 
          products: cartItems,
          totalPrice: totalAmount,
          paymentMethod: "FlexPay :$clientPhoneNumber",
          status: 'PENDING' // Le panier ne sera pas vidé tant que le statut est PENDING
        );
        
        // 4. Informer l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Paiement initié. Veuillez valider la demande sur votre téléphone (numéro : $clientPhoneNumber)."),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 7),
          ),
        );
        Navigator.of(context).pop(); 

      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'initiation du paiement FlexPay: $message"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } on http.ClientException catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau lors de l\'initialisation de FlexPay: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      print('Erreur générale FlexPay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }


  Future<Map<String, dynamic>?> sendOrderToDatabase({
    required BuildContext context,
    required String name,
    required String address,
    required String transactionId,
    required List<Map<String, dynamic>> products,
    required double totalPrice,
    required String paymentMethod,
    String status = 'en cours', // Statut par défaut
  }) async {
    // Cette variable doit pointer vers le script PHP qui insère les données dans votre BD
    // final url = '${ApiConfig.BASE_URL}/commande.php'; 
    final url = 'http://192.168.1.64/soko/commande.php';

    try {
      for (final product in products) {
        // ... (Logique de vérification du produit - inchangée) ...
        final double productPrice =
            double.tryParse(product['product']['price'].toString()) ?? 0.0;
        final int productQuantity = (product['quantity'] as num).toInt();
        final double calculatedIndividualProductTotalPrice =
            productPrice * productQuantity;

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'address': address,
            'transaction_id': transactionId,
            'product_name': product['product']['name'],
            'quantity': productQuantity,
            'payment_method': paymentMethod,
            'total_price': calculatedIndividualProductTotalPrice,
            'status': status, 
          }),
        );
        
        if (response.statusCode < 200 || response.statusCode >= 300) {
           throw Exception('Échec de l\'envoi de la commande au serveur: ${response.statusCode}');
        }
      }

      final orderData = {
        'id': transactionId,
        'date': DateTime.now().toIso8601String(),
        'customerName': name,
        'address': address,
        'products': products,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'status': status
      };

      await _saveOrderToHistory(orderData);

      // Vider le panier uniquement si le paiement est immédiat (pas PENDING)
      if (status != 'PENDING') {
        setState(() => cartItems.clear());
        await _saveCartLocally();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Votre commande a été traitée avec succès !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } 

      return orderData;
    } on Exception catch (e) {
      print('Erreur lors de l\'envoi de la commande: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible de traiter la commande. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _orderViaWhatsApp(BuildContext context) async {
    // Construire le message WhatsApp
    final buffer = StringBuffer();
    double total = 0;
    // NOTE : Ajoutez ici la logique pour construire le message avec les détails du panier
    
    // Simuler le numéro de contact WhatsApp
    const phone = '243973989083'; 
    final url = Uri.parse(
        'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(buffer.toString())}');

    try {
      final orderResult = await sendOrderToDatabase(
        context: context,
        name: loggedInUserName!,
        address: addressController.text,
        transactionId: 'whatsapp_${DateTime.now().millisecondsSinceEpoch}',
        products: cartItems,
        totalPrice: total,
        paymentMethod: 'WhatsApp',
        status: 'en cours', // Paiement immédiat (non asynchrone)
      );

      if (orderResult != null) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")),
          );
        }
      }
    } catch (e) {
      print('Error during WhatsApp order process: $e');
    }
  }


  // ------------------------------------------------------------------
  // MISE À JOUR DE LA BOÎTE DE DIALOGUE (COLLECTE DYNAMIQUE)
  // ------------------------------------------------------------------
  void _showAddressDialog(VoidCallback onConfirm) {
    if (cartItems.isEmpty || loggedInUserName == null || loggedInUserName!.isEmpty) return;

    // Initialisation pour s'assurer que les champs sont vides à l'ouverture
    phoneController.text = ''; 
    addressController.text = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adresse et Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Votre adresse de livraison',
                    hintText: 'Ex: 123 Rue de la Paix',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                // Champ pour le numéro de téléphone Mobile Money
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money (Ex: 243812345678)',
                    hintText: '243xxxxxxxxx',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez remplir l'adresse de livraison")),
                  );
                } else if (phoneController.text.isEmpty || !_validatePhoneNumber(phoneController.text.trim())) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Numéro de téléphone FlexPay manquant ou invalide (243xxxxxxxx).")),
                  );
                } 
                else {
                  Navigator.of(context).pop();
                  onConfirm();
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double totalAmount = cartItems.fold(
      0.0,
      (double sum, item) {
        final price = double.tryParse(item['product']['price'].toString()) ?? 0.0;
        return sum + (price * item['quantity']);
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backdColor,
        title: const Text('Mon Panier', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Votre panier est vide'))
                : ListView(
                    children: [
                      ...cartItems.map((item) {
                        final product = item['product'];
                        final quantity = item['quantity'];
                        final price =
                            double.tryParse(product['price'].toString()) ?? 0;

                        return ListTile(
                          leading: product['images'] != null &&
                                  product['images'].isNotEmpty
                              ? Image.network(
                                  product['images'][0]['src'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image),
                          title: Text(product['name'],maxLines: 2,style: GoogleFonts.abel(),),
                          subtitle: Text(
                              '${price.toStringAsFixed(2)} \$ x $quantity = ${(price * quantity).toStringAsFixed(2)} \$',
                              ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => cartItems.remove(item));
                              _saveCartLocally();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Produit supprimé du panier')),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${totalAmount.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.telegram, size: 19, color: Colors.white),
                          label: const Text('WhatsApp',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showAddressDialog(
                              () => _orderViaWhatsApp(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.phone_android, color: Colors.white),
                          label: const Text('Mobile Money (FlexPay)',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          // Utilisation de la nouvelle fonction FlexPay
                          onPressed: () => _showAddressDialog(
                              () => _initiateFlexPayTransaction(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}