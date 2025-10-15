import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/api_config.dart';
import 'package:soko/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // 💡 NOUVEL IMPORT

// Importez vos fichiers de support
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/style.dart';

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

  // 💡 NOUVEL ÉTAT POUR LA GÉOLOCALISATION
  Position? _currentPosition;
  bool _isLocating = false;

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
    _getCurrentLocation(); // 💡 Déclenche la recherche de la position au démarrage
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // LOGIQUE DE GESTION DE L'ÉTAT LOCAL ET UTILISATEUR (INCHANGÉE)
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
  // LOGIQUE DE GÉOLOCALISATION (GPS & Géocodage)
  // ------------------------------------------------------------------

  // 💡 FONCTION DE L'UTILISATEUR MISE À JOUR AVEC VÉRIFICATION DES PERMISSIONS
  void _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Le service GPS est désactivé
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Permissions refusées
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        // Optionnel : Tentative de pré-remplir l'adresse à partir des coordonnées (nécessiterait Reverse Geocoding)
      });
    } catch (e) {
      print("Erreur de géolocalisation: $e");
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  // Fonction de fallback : conversion d'adresse textuelle en coordonnées
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Erreur de géocodage: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // LOGIQUE DE COMMANDE ET FLEXPAY (MISE À JOUR)
  // ------------------------------------------------------------------

  String _generateFlexPayReference() {
    return 'SOKO-${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _validatePhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^243[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _initiateFlexPayTransaction(BuildContext context) async {
    final address = addressController.text;
    final name = loggedInUserName!;
    final clientPhoneNumber = phoneController.text.trim();

    if (!_validatePhoneNumber(clientPhoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Format de numéro de téléphone invalide (Ex: 243812345678).')),
      );
      return;
    }

    // 💡 LOGIQUE DE PRIORITÉ DE LOCALISATION (Inchangée)
    double? latitude;
    double? longitude;

    if (_currentPosition != null) {
      // Priorité 1: Position GPS en direct
      latitude = _currentPosition!.latitude;
      longitude = _currentPosition!.longitude;
    } else {
      // Priorité 2: Fallback au géocodage de l'adresse
      final coords = await _geocodeAddress(address);
      if (coords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Adresse de livraison introuvable. Veuillez activer le GPS ou affiner l\'adresse.')),
        );
        return;
      }
      latitude = coords['latitude'];
      longitude = coords['longitude'];
    }

    // --- 💡 CORRECTION : CALCUL DU MONTANT TOTAL AVEC 30% SUPPLÉMENTAIRE ---
    // 1. Calcul du montant total des produits (Base)
    final double baseAmount = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          ((double.tryParse(item['product']['price'].toString()) ?? 0) *
              item['quantity']),
    );

    // 2. Calcul du supplément (30% de la base)
    final double surcharge = baseAmount * 0.30; // 30%

    // 3. Montant final à facturer
    final double totalAmount = baseAmount + surcharge;
    // ------------------------------------------------------------------------

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le montant total est nul ou négatif.')));
      return;
    }

    final String referenceId = _generateFlexPayReference();
    // Utilisation du montant final avec 30% pour la passerelle FlexPay
    final String amountString = totalAmount.toStringAsFixed(0);

    // 1. Préparation du corps de la requête FlexPay
    final requestBody = jsonEncode({
      "merchant": _MERCHANT_ID,
      "type": "1", // Mobile Money
      "phone": clientPhoneNumber,
      "reference": referenceId,
      // Le montant inclut maintenant les 30%
      "amount": amountString,
      "currency": "USD",
      "callbackUrl": _CALLBACK_URL,
    });

    // ... (Le reste de la fonction reste inchangé) ...
    // Le code de traitement de la réponse et l'appel à sendOrderToDatabase
    // utilisent le nouveau `totalAmount` calculé.
    // ...
    try {
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
      final String message =
          responseData['message'] ?? 'Erreur inconnue de la passerelle.';

      if (code == '0') {
        // 3. Enregistrer la commande
        await sendOrderToDatabase(
            context: context,
            name: name,
            address: address,
            transactionId: referenceId,
            products: cartItems,
            // Utilise le montant total avec 30%
            totalPrice: totalAmount,
            paymentMethod: "FlexPay :$clientPhoneNumber",
            status: 'PENDING',
            latitude: latitude, // ENVOI DES COORDONNÉES DÉTERMINÉES
            longitude: longitude);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Paiement initié. Veuillez valider la demande sur votre téléphone (numéro : $clientPhoneNumber)."),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 7),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Échec de l'initiation du paiement FlexPay: $message"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
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
    required double
        totalPrice, // Montant TOTAL avec 30% pour l'enregistrement local
    required String paymentMethod,
    String status = 'en cours', // Statut par défaut
    double? latitude, // 💡 PARAMÈTRE MIS À JOUR
    double? longitude, // 💡 PARAMÈTRE MIS À JOUR
  }) async {
    final url = '$baseUrl/commande.php';

    try {
      for (final product in products) {
        final double productPrice =
            double.tryParse(product['product']['price'].toString()) ?? 0.0;
        final int productQuantity = (product['quantity'] as num).toInt();

        // 💡 CORRECTION: Calculer le prix de BASE de la ligne de produit SANS les 30%
        final double calculatedIndividualProductBasePrice =
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
            // 💡 ENVOI du prix de BASE au serveur pour cette ligne
            'total_price': calculatedIndividualProductBasePrice,
            'status': status,
            'latitude': latitude, // 💡 ENVOI
            'longitude': longitude, // 💡 ENVOI
          }),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
              'Échec de l\'envoi de la commande au serveur: ${response.statusCode}');
        }
      }

      // Le `orderData` local stocke le `totalPrice` avec les 30% pour l'affichage dans l'historique
      final orderData = {
        'id': transactionId,
        'date': DateTime.now().toIso8601String(),
        'customerName': name,
        'address': address,
        'products': products,
        'totalPrice':
            totalPrice, // C'est ici que le total avec 30% est conservé
        'paymentMethod': paymentMethod,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
      };

      await _saveOrderToHistory(orderData);

      // Vider le panier uniquement si le paiement est immédiat (pas PENDING)
      if (status != 'PENDING') {
        // Supposons que `setState` et `_saveCartLocally` sont disponibles dans la classe d'état
        // setState(() => cartItems.clear());
        // await _saveCartLocally();

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
          content: Text(
              'Erreur: Impossible de traiter la commande. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  // Définition de la constante pour le pourcentage, rend le code plus lisible
  double _SERVICE_FEE_RATE = 0.30; // 30% de supplément (frais de service/livraison)

 void _orderViaWhatsApp(BuildContext context) async {
  final address = addressController.text;

  // 1. Calcul du montant total de BASE (prix des produits uniquement)
  const double _SERVICE_FEE_RATE = 0.30; // Réutilisation de la constante
  final double baseAmount = cartItems.fold(
    0.0,
    (sum, item) =>
        sum +
        ((double.tryParse(item['product']['price'].toString()) ?? 0) *
            item['quantity']),
  );

  // 2. Calcul du supplément (30% de la base)
  final double surcharge = baseAmount * _SERVICE_FEE_RATE;

  // 3. Montant final à facturer au client
  final double total = baseAmount + surcharge;

  // 💡 LOGIQUE DE PRIORITÉ DE LOCALISATION (Inchangée)
  double? latitude;
  double? longitude;

  if (_currentPosition != null) {
    // Priorité 1: Position GPS en direct
    latitude = _currentPosition!.latitude;
    longitude = _currentPosition!.longitude;
  } else {
    // Priorité 2: Fallback au géocodage de l'adresse
    final coords = await _geocodeAddress(address);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Adresse de livraison introuvable. Veuillez activer le GPS ou affiner l\'adresse.')),
      );
      return;
    }
    latitude = coords['latitude'];
    longitude = coords['longitude'];
  }

  // Construction du message WhatsApp
  final buffer = StringBuffer();
  buffer.write('Bonjour, je souhaite passer une commande :');
  
  // Détail des produits
  for (var item in cartItems) {
    final price = double.tryParse(item['product']['price'].toString()) ?? 0.0;
    final quantity = item['quantity'];
    buffer.write(
        '\n- ${item['product']['name']}  : $quantity pièce(s) dont ${(price * 1.30).toStringAsFixed(2)} \$ la pièce'); // Prix avec 30%
  }
  
  buffer.write('\n\nSous-total (produits) : ${baseAmount.toStringAsFixed(2)} \$');
  buffer.write('\nFrais de service (30%) : ${surcharge.toStringAsFixed(2)} \$');
  buffer.write('\nTotal final à payer : ${total.toStringAsFixed(2)} \$'); // Total incluant les 30%

  buffer.write('\n\nAdresse de livraison : $address');
  buffer.write('\nMon contact: ${phoneController.text.trim()}');

  // 🚀 AJOUT DES COORDONNÉES GPS AU MESSAGE WHATSAPP
  if (latitude != null && longitude != null) {
    buffer.write('\nCoordonnées GPS: $latitude, $longitude');
    // Facultatif : Ajout d'un lien Google Maps pour un accès facile
    buffer.write('\nLien Carte: https://maps.google.com/?q=$latitude,$longitude');
  } else {
    buffer.write('\nCoordonnées GPS: Non disponibles (adresse texte utilisée)');
  }
  // --------------------------------------------------------------------

  // Assurez-vous que ce numéro est celui de l'administrateur/livreur
  const phone = '243992959898';
  final url = Uri.parse(
      'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(buffer.toString())}');

  try {
    final orderResult = await sendOrderToDatabase(
      context: context,
      name: loggedInUserName!,
      address: address,
      transactionId: 'whatsapp_${DateTime.now().millisecondsSinceEpoch}',
      products: cartItems,
      // ENVOI du total final (avec 30%) pour l'enregistrement local
      totalPrice: total,
      paymentMethod: 'WhatsApp',
      status: 'en cours',
      latitude: latitude, // ENVOI DES COORDONNÉES DÉTERMINÉES (BDD)
      longitude: longitude, // ENVOI DES COORDONNÉES DÉTERMINÉES (BDD)
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
  // MISE À JOUR DE LA BOÎTE DE DIALOGUE
  // ------------------------------------------------------------------
  void _showAddressDialog(VoidCallback onConfirm) {
    if (cartItems.isEmpty ||
        loggedInUserName == null ||
        loggedInUserName!.isEmpty) return;

    // Mise à jour de l'état pour les coordonnées
    final String locationStatus = _isLocating
        ? 'Recherche de la position GPS...'
        : (_currentPosition != null
            ? 'Position GPS acquise : ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
            : 'Position GPS indisponible. Veuillez saisir l\'adresse.');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adresse et Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💡 Affichage du statut GPS
                Text(locationStatus,
                    style: TextStyle(
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold)),
                if (_currentPosition == null && !_isLocating)
                  TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer la localisation GPS')),
                const SizedBox(height: 30),

                // Champ Adresse
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Votre adresse de livraison (si pas de GPS)',
                    hintText: 'Ex: 123 Rue de la Paix',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                // Champ Téléphone
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
                // Validation : adresse ou GPS doit être disponible
                if (_currentPosition == null &&
                    addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Veuillez remplir l'adresse ou activer le GPS.")),
                  );
                } else if (phoneController.text.isEmpty ||
                    !_validatePhoneNumber(phoneController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Numéro de téléphone FlexPay manquant ou invalide (243xxxxxxxx).")),
                  );
                } else {
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
// Si vous voulez aussi afficher le prix unitaire ajusté (13.00 $ x 1 = 13.00 $)

  @override
  Widget build(BuildContext context) {
    double totalAmount = cartItems.fold(
      0.0,
      (double sum, item) {
        final price =
            double.tryParse(item['product']['price'].toString()) ?? 0.0;
        return sum + (price * item['quantity']);
      },
    );
// 1. Calculer le montant de base (Sous-total)
    final double baseAmount = cartItems.fold(
      0.0,
      (double sum, item) {
        final price =
            double.tryParse(item['product']['price'].toString()) ?? 0.0;
        return sum + (price * item['quantity']);
      },
    );

// 2. Calculer le supplément (30% de la base)
    final double surcharge = baseAmount * 0.30; // 30%

// 3. Montant final (Total)
    final double tottalAmount = baseAmount + surcharge;
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
                          title: Text(
                            product['name'],
                            maxLines: 2,
                            style: GoogleFonts.abel(),
                          ),
                          subtitle: Text(
                            // Calcule le prix unitaire ajusté: price * 1.30
                            // Multiplie par la quantité pour obtenir le nouveau sous-total.
                            '${(price * quantity * 1.30).toStringAsFixed(2)} \$ x $quantity ',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => cartItems.remove(item));
                              _saveCartLocally();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Produit supprimé du panier')),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Ligne du Sous-total
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     const Text('Sous-total:',
                      //         style: TextStyle(fontSize: 16)),
                      //     Text('${baseAmount.toStringAsFixed(2)} \$',
                      //         style: const TextStyle(fontSize: 16)),
                      //   ],
                      // ),

                      // 2. Ligne des Frais de service (30%)
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     const Text('Frais de livraison & service:',
                      //         style:
                      //             TextStyle(fontSize: 16, color: Colors.red)),
                      //     Text('+ ${surcharge.toStringAsFixed(2)} \$',
                      //         style: const TextStyle(
                      //             fontSize: 16, color: Colors.red)),
                      //   ],
                      // ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Tout frais inclus',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        
                        ],
                      ),

                      const Divider(), // Séparateur visuel

                      // 3. Ligne du Total final (en gras, comme demandé initialement)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Final:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              '${tottalAmount.toStringAsFixed(2)}+ \$', // Montant avec les 30%
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.telegram,
                              size: 19, color: Colors.white),
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
                          icon: const Icon(Icons.mobile_friendly,
                              color: Colors.white),
                          label: const Text('Mobile Money',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
