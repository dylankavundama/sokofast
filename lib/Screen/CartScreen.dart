import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // 💡 NOUVEL IMPORT
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Auth/loginPage.dart';
// Importez vos fichiers de support
import 'package:soko/OrderHistoryScreen.dart';
<<<<<<< Updated upstream
import 'package:soko/api_config.dart';
import 'package:soko/services.dart';
=======
import 'package:soko/l10n/app_localizations.dart';
>>>>>>> Stashed changes
import 'package:soko/style.dart';
import 'package:soko/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // 💡 NOUVEAUX ÉTATS POUR LA GESTION DES VILLES
  List<Map<String, dynamic>> _villes = [];
  int? _selectedVilleId;
  bool _isLoadingVilles = false;

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
    _loadVilles(); // 💡 Charger la liste des villes
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      // Utiliser displayName, email (sans @domain), ou null comme fallback
      loggedInUserName = user?.displayName ?? 
                        (user?.email != null ? user!.email!.split('@')[0] : null);
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

<<<<<<< Updated upstream
  // ------------------------------------------------------------------
  // LOGIQUE DE GESTION DES VILLES
  // ------------------------------------------------------------------

  // 💡 NOUVELLE FONCTION : Charger la liste des villes depuis l'API
  Future<void> _loadVilles() async {
    setState(() {
      _isLoadingVilles = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_villes.php'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _villes = List<Map<String, dynamic>>.from(data['data']);
            _isLoadingVilles = false;
          });
        } else {
          setState(() {
            _isLoadingVilles = false;
          });
        }
      } else {
        setState(() {
          _isLoadingVilles = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des villes: $e');
      setState(() {
        _isLoadingVilles = false;
      });
    }
  }

  // ------------------------------------------------------------------
  // LOGIQUE DE GÉOLOCALISATION (GPS & Géocodage)
  // ------------------------------------------------------------------

  // 💡 FONCTION DE L'UTILISATEUR MISE À JOUR AVEC VÉRIFICATION DES PERMISSIONS
=======
>>>>>>> Stashed changes
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

  String _generateFlexPayReference() {
    return 'SOKO-${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _validatePhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^243[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _initiateFlexPayTransaction(BuildContext context) async {
    // 💡 Vérification de l'authentification (corrigée pour iPadOS)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour passer une commande'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }
    
    // Recharger le token si nécessaire (pour iPadOS)
    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée. Veuillez vous reconnecter.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
        return;
      }
    } catch (e) {
      print('Erreur lors du rechargement de l\'utilisateur: $e');
      // Continuer avec l'utilisateur actuel si le rechargement échoue
    }
    
    final address = addressController.text;
    // Utiliser displayName, email (sans @domain), ou "Client" comme fallback
    final name = user.displayName ?? 
                 (user.email != null ? user.email!.split('@')[0] : null) ?? 
                 loggedInUserName ?? 
                 'Client';
    final clientPhoneNumber = phoneController.text.trim();

    final loc = AppLocalizations.of(context);
    if (!_validatePhoneNumber(clientPhoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.cartInvalidPhoneFormat)),
      );
      return;
    }

    double? latitude;
    double? longitude;

    if (_currentPosition != null) {
      latitude = _currentPosition!.latitude;
      longitude = _currentPosition!.longitude;
    } else {
      final coords = await _geocodeAddress(address);
      if (coords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.cartAddressNotFound)),
        );
        return;
      }
      latitude = coords['latitude'];
      longitude = coords['longitude'];
    }

    final double baseAmount = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          ((double.tryParse(item['product']['price'].toString()) ?? 0) *
              item['quantity']),
    );

    final double surcharge = baseAmount * 0.30;
    final double totalAmount = baseAmount + surcharge;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.cartTotalZero)));
      return;
    }

    final String referenceId = _generateFlexPayReference();
    final String amountString = totalAmount.toStringAsFixed(0);

    final requestBody = jsonEncode({
      "merchant": _MERCHANT_ID,
      "type": "1",
      "phone": clientPhoneNumber,
      "reference": referenceId,
      "amount": amountString,
      "currency": "USD",
      "callbackUrl": _CALLBACK_URL,
    });
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
<<<<<<< Updated upstream
        // 3. Enregistrer la commande
        // Obtenir le nom avec fallback pour compatibilité iPadOS
        final refreshedUser = FirebaseAuth.instance.currentUser;
        final userName = refreshedUser?.displayName ?? 
                        (refreshedUser?.email != null ? refreshedUser!.email!.split('@')[0] : null) ?? 
                        name;
        
        final orderResult = await sendOrderToDatabase(
=======
        await sendOrderToDatabase(
>>>>>>> Stashed changes
            context: context,
            name: userName,
            address: address,
            transactionId: referenceId,
            products: cartItems,
            totalPrice: totalAmount,
            paymentMethod: "FlexPay :$clientPhoneNumber",
            status: 'PENDING',
<<<<<<< Updated upstream
            latitude: latitude, // ENVOI DES COORDONNÉES DÉTERMINÉES
            longitude: longitude,
            villeId: _selectedVilleId); // 💡 ENVOI DE L'ID DE LA VILLE

        if (orderResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Paiement initié. Veuillez valider la demande sur votre téléphone (numéro : $clientPhoneNumber). Le panier a été vidé."),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 7),
            ),
          );
          Navigator.of(context).pop();
        }
=======
            latitude: latitude,
            longitude: longitude);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cartPaymentInitiated(clientPhoneNumber)),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 7),
          ),
        );
        Navigator.of(context).pop();
>>>>>>> Stashed changes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cartFlexpayFailed(message)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      print('Erreur générale FlexPay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.cartUnexpectedError(e.toString())),
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
<<<<<<< Updated upstream
    String status = 'en cours', // Statut par défaut
    double? latitude, // 💡 PARAMÈTRE MIS À JOUR
    double? longitude, // 💡 PARAMÈTRE MIS À JOUR
    int? villeId, // 💡 NOUVEAU PARAMÈTRE : ID de la ville
=======
    String status = 'en cours',
    double? latitude,
    double? longitude,
>>>>>>> Stashed changes
  }) async {
    final url = '$baseUrl/commande.php';

    try {
      for (final product in products) {
        final double productPrice =
            double.tryParse(product['product']['price'].toString()) ?? 0.0;
        final int productQuantity = (product['quantity'] as num).toInt();
        final double calculatedIndividualProductBasePrice =
            productPrice * productQuantity;

        // 💡 NOUVEAU : Préparer les données à envoyer
        final requestData = {
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
          'ville_id': villeId, // 💡 NOUVEAU : ENVOI DE L'ID DE LA VILLE (peut être null)
        };
        
        // 💡 LOG : Enregistrer les données envoyées pour debug
        print('📤 Envoi commande - Transaction: $transactionId, Produit: ${product['product']['name']}, Ville ID: $villeId');
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
<<<<<<< Updated upstream
          body: jsonEncode(requestData),
=======
          body: jsonEncode({
            'name': name,
            'address': address,
            'transaction_id': transactionId,
            'product_name': product['product']['name'],
            'quantity': productQuantity,
            'payment_method': paymentMethod,
            'total_price': calculatedIndividualProductBasePrice,
            'status': status,
            'latitude': latitude,
            'longitude': longitude,
          }),
>>>>>>> Stashed changes
        );

        final loc = AppLocalizations.of(context);
        if (response.statusCode < 200 || response.statusCode >= 300) {
<<<<<<< Updated upstream
          // 💡 AMÉLIORATION : Récupérer le message d'erreur détaillé du serveur
          String errorMessage = 'Échec de l\'envoi de la commande au serveur: ${response.statusCode}';
          String debugInfo = '';
          
          // 💡 NOUVEAU : Logger la réponse complète pour debug
          print('❌ Réponse serveur (status ${response.statusCode}):');
          print('   Body: ${response.body.isNotEmpty ? response.body : "(vide)"}');
          print('   Headers: ${response.headers}');
          
          try {
            if (response.body.isNotEmpty) {
              final errorData = jsonDecode(response.body);
              if (errorData is Map) {
                if (errorData['message'] != null) {
                  errorMessage = errorData['message'].toString();
                }
                if (errorData['debug'] != null) {
                  if (errorData['debug'] is Map) {
                    debugInfo = '\nDétails techniques: ${jsonEncode(errorData['debug'])}';
                  } else {
                    debugInfo = '\nDétails: ${errorData['debug']}';
                  }
                }
              }
            } else {
              errorMessage += '\nLe serveur n\'a retourné aucune information.';
              debugInfo = '\nVérifiez les logs serveur pour plus de détails.';
            }
          } catch (e) {
            // Si le parsing échoue, utiliser le body brut
            if (response.body.isNotEmpty) {
              errorMessage += '\nRéponse serveur: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
            } else {
              errorMessage += '\nRéponse serveur vide. Erreur de parsing: $e';
            }
          }
          
          final fullErrorMessage = errorMessage + debugInfo;
          print('❌ Erreur commande: $fullErrorMessage');
          throw Exception(fullErrorMessage);
=======
          throw Exception(
              loc.cartOrderSendFailed(response.statusCode.toString()));
>>>>>>> Stashed changes
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
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
      };

      await _saveOrderToHistory(orderData);

<<<<<<< Updated upstream
      // 💡 NOUVEAU : Vider le panier après une commande réussie (tous les statuts)
      setState(() {
        cartItems.clear();
      });
      await _saveCartLocally();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre commande a été enregistrée avec succès ! Le panier a été vidé."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
=======
      if (status != 'PENDING') {

        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cartOrderSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
>>>>>>> Stashed changes

      return orderData;
    } on Exception catch (e) {
      print('Erreur lors de l\'envoi de la commande: $e');
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.cartOrderProcessError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

<<<<<<< Updated upstream
  // Définition de la constante pour le pourcentage, rend le code plus lisible
  static const double _SERVICE_FEE_RATE = 0.30; // 30% de supplément (frais de service/livraison)

=======
>>>>>>> Stashed changes
 void _orderViaWhatsApp(BuildContext context) async {
  // 💡 Vérification de l'authentification (corrigée pour iPadOS)
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous devez être connecté pour passer une commande'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
    return;
  }
  
  // Recharger le token si nécessaire (pour iPadOS)
  try {
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée. Veuillez vous reconnecter.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }
  } catch (e) {
    print('Erreur lors du rechargement de l\'utilisateur: $e');
    // Continuer avec l'utilisateur actuel si le rechargement échoue
  }
  
  final address = addressController.text;

<<<<<<< Updated upstream
  // 1. Calcul du montant total de BASE (prix des produits uniquement)
=======
  const double _SERVICE_FEE_RATE = 0.30;
>>>>>>> Stashed changes
  final double baseAmount = cartItems.fold(
    0.0,
    (sum, item) =>
        sum +
        ((double.tryParse(item['product']['price'].toString()) ?? 0) *
            item['quantity']),
  );

  final double surcharge = baseAmount * _SERVICE_FEE_RATE;
  final double total = baseAmount + surcharge;

  double? latitude;
  double? longitude;

  if (_currentPosition != null) {
    latitude = _currentPosition!.latitude;
    longitude = _currentPosition!.longitude;
  } else {
    final loc = AppLocalizations.of(context);
    final coords = await _geocodeAddress(address);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cartAddressNotFound)),
      );
      return;
    }
    latitude = coords['latitude'];
    longitude = coords['longitude'];
  }

  final loc = AppLocalizations.of(context);
  final buffer = StringBuffer();
  buffer.write(loc.cartWhatsappMessage);
  
  // Détail des produits
  for (var item in cartItems) {
    final price = double.tryParse(item['product']['price'].toString()) ?? 0.0;
    final quantity = item['quantity'];
    buffer.write('\n${loc.cartWhatsappProductLine(item['product']['name'], quantity, (price * 1.30).toStringAsFixed(2))}');
  }
  
  buffer.write('\n${loc.cartWhatsappTotal(total.toStringAsFixed(2))}');
  buffer.write('\n\n${loc.cartWhatsappDelivery(address)}');
  buffer.write('\n\n${loc.cartWhatsappContact(phoneController.text.trim())}');

  if (latitude != null && longitude != null) {
    buffer.write('\n\n${loc.cartWhatsappMapLink('https://maps.google.com/?q=$latitude,$longitude')}');
  } else {
    buffer.write('\n${loc.cartWhatsappGpsUnavailable}');
  }
<<<<<<< Updated upstream
  // --------------------------------------------------------------------
//go00000000000000000
=======

>>>>>>> Stashed changes
  // Assurez-vous que ce numéro est celui de l'administrateur/livreur
  const phone = '243893774961';
  final url = Uri.parse(
      'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(buffer.toString())}');

    try {
      // Obtenir le nom avec fallback pour compatibilité iPadOS
      final userName = user.displayName ?? 
                      (user.email != null ? user.email!.split('@')[0] : null) ?? 
                      loggedInUserName ?? 
                      'Client';
      
      final orderResult = await sendOrderToDatabase(
        context: context,
        name: userName,
        address: address,
      transactionId: 'whatsapp_${DateTime.now().millisecondsSinceEpoch}',
      products: cartItems,
      totalPrice: total,
      paymentMethod: 'WhatsApp',
      status: 'en cours',
<<<<<<< Updated upstream
      latitude: latitude, // ENVOI DES COORDONNÉES DÉTERMINÉES (BDD)
      longitude: longitude, // ENVOI DES COORDONNÉES DÉTERMINÉES (BDD)
      villeId: _selectedVilleId, // 💡 ENVOI DE L'ID DE LA VILLE
    );

    if (orderResult != null) {
      // 💡 Le panier a déjà été vidé dans sendOrderToDatabase
=======
      latitude: latitude,
      longitude: longitude,
    );

    if (orderResult != null) {
      final loc = AppLocalizations.of(context);
>>>>>>> Stashed changes
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Fermer le dialog après l'envoi WhatsApp
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.cartCouldNotOpenWhatsapp)),
        );
      }
    }
  } catch (e) {
    print('Error during WhatsApp order process: $e');
  }
}
  void _showAddressDialog(VoidCallback onConfirm) {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide')),
      );
      return;
    }
    
    // 💡 Vérification de l'authentification (corrigée pour iPadOS)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Rediriger vers la page de connexion
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            'Vous devez vous connecter pour passer une commande. Souhaitez-vous vous connecter maintenant ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Recharger le token si nécessaire (pour iPadOS) - de manière asynchrone sans bloquer
    user.reload().catchError((e) {
      print('Erreur lors du rechargement de l\'utilisateur: $e');
    });
    
    // Mettre à jour le nom de l'utilisateur si nécessaire (avec fallback)
    if (loggedInUserName == null || loggedInUserName!.isEmpty) {
      setState(() {
        loggedInUserName = user.displayName ?? 
                          (user.email != null ? user.email!.split('@')[0] : null) ?? 
                          'Client';
      });
    }

    final loc = AppLocalizations.of(context);
    final String locationStatus = _isLocating
        ? loc.cartGpsSearching
        : (_currentPosition != null
            ? loc.cartGpsAcquired(_currentPosition!.latitude.toStringAsFixed(4), _currentPosition!.longitude.toStringAsFixed(4))
            : loc.cartGpsUnavailableText);

    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture accidentelle
      builder: (context) {
<<<<<<< Updated upstream
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 100,
                vertical: Responsive.isMobile(context) ? 24 : 50,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: Responsive.isMobile(context) ? double.infinity : 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec titre et bouton fermer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backdColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Adresse de livraison',
                              style: GoogleFonts.abel(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                    // 💡 NOUVEAU : Sélecteur de ville (OBLIGATOIRE)
                    if (_isLoadingVilles)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_villes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Aucune ville disponible',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedVilleId,
                        decoration: const InputDecoration(
                          labelText: 'Ville de livraison *',
                          hintText: 'Sélectionnez votre ville',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: _villes.map((ville) {
                          return DropdownMenuItem<int>(
                            value: ville['id'] as int,
                            child: Text(ville['nom'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedVilleId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une ville';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 20),

                    // 💡 Affichage du statut GPS
                    Text(
                      locationStatus,
                      style: TextStyle(
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (_currentPosition == null && !_isLocating)
                      TextButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer la localisation GPS'),
                      ),
                    const SizedBox(height: 20),

                    // Champ Adresse
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Votre adresse complète *',
                        hintText: 'Ex: 123 Rue de la Paix, Quartier...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    // Champ Téléphone
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Numéro Mobile Money *',
                        hintText: '243812345678',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                    // Actions en bas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                  onPressed: () async {
                    // Validation : ville, adresse et téléphone sont obligatoires
                    if (_selectedVilleId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Veuillez sélectionner une ville de livraison."),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    if (addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Veuillez remplir votre adresse complète."),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    if (phoneController.text.isEmpty ||
                        !_validatePhoneNumber(phoneController.text.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Numéro de téléphone invalide (format: 243xxxxxxxxx)."),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    // Fermer le dialogue d'abord
                    Navigator.of(context).pop();
                    
                    // Attendre un court instant pour s'assurer que le dialogue est fermé
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    // Appeler le callback
                    try {
                      onConfirm();
                    } catch (e) {
                      print('Erreur lors de l\'exécution du callback: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors du traitement: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: backdColor,
                            ),
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
=======
        return AlertDialog(
          title: Text(loc.cartDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      label: Text(loc.cartRetryGpsLocation)),
                const SizedBox(height: 30),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: loc.cartAddressLabel,
                    hintText: loc.cartAddressHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: loc.cartPhoneLabel,
                    hintText: loc.cartPhoneHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cartDialogCancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentPosition == null &&
                    addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.cartNeedAddressOrGps)),
                  );
                } else if (phoneController.text.isEmpty ||
                    !_validatePhoneNumber(phoneController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.cartInvalidPhone)),
                  );
                } else {
                  Navigator.of(context).pop();
                  onConfirm();
                }
              },
              child: Text(loc.cartDialogConfirm),
            ),
          ],
>>>>>>> Stashed changes
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    // 1. Calculer le montant de base (Sous-total)
=======
    final loc = AppLocalizations.of(context);
    double totalAmount = cartItems.fold(
      0.0,
      (double sum, item) {
        final price =
            double.tryParse(item['product']['price'].toString()) ?? 0.0;
        return sum + (price * item['quantity']);
      },
    );

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white,), onPressed: (){
          Navigator.pop(context);
        },),
        title: const Text('Mon Panier', style: TextStyle(color: Colors.white)),
=======
        title: Text(loc.cartTitle, style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white)),
>>>>>>> Stashed changes
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
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
                ? Center(child: Text(loc.cartEmpty))
                : ListView(
                    children: [
                      ...cartItems.map((item) {
                        final product = item['product'];
                        final quantity = item['quantity'];
                        final price =
                            double.tryParse(product['price'].toString()) ?? 0;

                        final imageSize = Responsive.isMobile(context) ? 50.0 : 70.0;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Responsive.getHorizontalPadding(context),
                            vertical: Responsive.getVerticalPadding(context) * 0.5,
                          ),
                          leading: product['images'] != null &&
                                  product['images'].isNotEmpty
                              ? Image.network(
                                  product['images'][0]['src'],
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image, size: imageSize),
                          title: Text(
                            product['name'],
                            maxLines: 2,
                            style: GoogleFonts.abel(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 14, tablet: 16),
                            ),
                          ),
                          subtitle: Text(
                            '${(price * quantity * 1.30).toStringAsFixed(2)} \$ x $quantity ',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => cartItems.remove(item));
                              _saveCartLocally();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.cartDeleted)),
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
              padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
<<<<<<< Updated upstream
                            'Tout frais inclus',
                            style: TextStyle(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                              color: Colors.red,
                            ),
=======
                            loc.cartAllFeesIncluded,
                            style: const TextStyle(fontSize: 16, color: Colors.red),
>>>>>>> Stashed changes
                          ),
                        
                        ],
                      ),

                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
<<<<<<< Updated upstream
                          Text('Total Final:',
                              style: TextStyle(
                                  fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 20),
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${tottalAmount.toStringAsFixed(2)}+ \$', // Montant avec les 30%
                              style: TextStyle(
                                  fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 20),
                                  fontWeight: FontWeight.bold)),
=======
                          Text(loc.cartTotalFinal,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              '${tottalAmount.toStringAsFixed(2)}+ \$',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
>>>>>>> Stashed changes
                        ],
                      ),
                    ],
                  ),
<<<<<<< Updated upstream
                  SizedBox(height: Responsive.getVerticalPadding(context) * 2),
                  Responsive.isMobile(context)
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.telegram,
                                    size: 19, color: Colors.white),
                                label: const Text('WhatsApp',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.getVerticalPadding(context) * 1.75,
                                  ),
                                ),
                                onPressed: () => _showAddressDialog(
                                    () => _orderViaWhatsApp(context)),
                              ),
                            ),
                            SizedBox(height: Responsive.getVerticalPadding(context)),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.mobile_friendly,
                                    color: Colors.white),
                                label: const Text('Mobile Money',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.getVerticalPadding(context) * 1.75,
                                  ),
                                ),
                                onPressed: () => _showAddressDialog(
                                    () => _initiateFlexPayTransaction(context)),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.telegram,
                                    size: 19, color: Colors.white),
                                label: const Text('WhatsApp',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.getVerticalPadding(context) * 1.75,
                                  ),
                                ),
                                onPressed: () => _showAddressDialog(
                                    () => _orderViaWhatsApp(context)),
                              ),
                            ),
                            SizedBox(width: Responsive.getHorizontalPadding(context) * 0.625),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.mobile_friendly,
                                    color: Colors.white),
                                label: const Text('Mobile Money',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.getVerticalPadding(context) * 1.75,
                                  ),
                                ),
                                onPressed: () => _showAddressDialog(
                                    () => _initiateFlexPayTransaction(context)),
                              ),
                            ),
                          ],
                        ),
=======
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.telegram,
                              size: 19, color: Colors.white),
                          label: Text(loc.cartWhatsapp,
                              style: const TextStyle(color: Colors.white)),
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
                          label: Text(loc.cartMobileMoney,
                              style: const TextStyle(color: Colors.white)),
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
>>>>>>> Stashed changes
                ],
              ),
            ),
        ],
      ),
    );
  }
}
