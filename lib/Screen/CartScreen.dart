import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // 💡 NOUVEL IMPORT

// Importez vos fichiers de support
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/l10n/app_localizations.dart';
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
  List<dynamic> _cities = [];
  bool _isLoadingCities = false;
  int? _selectedCityId; // 💡 Stocker l'ID de la ville sélectionnée

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
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    setState(() => _isLoadingCities = true);
    try {
      final response =
          await http.get(Uri.parse('${ApiConfig.BASE_URL}/get_villes.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cities = data['data'];
          });
        }
      }
    } catch (e) {
      print('Erreur récupération villes: $e');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  // Méthode pour vider le panier
  Future<void> _clearCart() async {
    setState(() {
      cartItems.clear();
    });
    await _saveCartLocally();
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
    final address = addressController.text;
    final name = loggedInUserName!;
    final clientPhoneNumber = phoneController.text.trim();

    final loc = AppLocalizations.of(context);
    if (!_validatePhoneNumber(clientPhoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cartInvalidPhoneFormat)),
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
          SnackBar(content: Text(loc.cartAddressNotFound)),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.cartTotalZero)));
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
        await sendOrderToDatabase(
            context: context,
            name: name,
            address: address,
            transactionId: referenceId,
            products: cartItems,
            totalPrice: totalAmount,
            paymentMethod: "FlexPay :$clientPhoneNumber",
            status: 'PENDING',
            latitude: latitude,
            longitude: longitude,
            villeId: _selectedCityId ?? 1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cartPaymentInitiated(clientPhoneNumber)),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 7),
          ),
        );
        Navigator.of(context).pop();
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
    String status = 'en cours',
    double? latitude,
    double? longitude,
    required int villeId,
  }) async {
    final url = 'https://sokofast.com/backend/commande.php';
    print('Envoi de la commande à: $url');
    print('Données de la commande:');
    print('- Nom: $name');
    print('- Adresse: $address');
    print('- ID de transaction: $transactionId');
    print('- Nombre de produits: ${products.length}');
    print('- Montant total: $totalPrice');
    print('- Méthode de paiement: $paymentMethod');

    try {
      for (final product in products) {
        final double productPrice =
            double.tryParse(product['product']['price'].toString()) ?? 0.0;
        final int productQuantity = (product['quantity'] as num).toInt();
        final double calculatedIndividualProductBasePrice =
            productPrice * productQuantity;

        final requestBody = {
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
          'ville_id': villeId,
        };

        print('Envoi du produit: ${product['product']['name']}');
        print('Corps de la requête: ${jsonEncode(requestBody)}');

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        print('Réponse du serveur (${response.statusCode}): ${response.body}');

        final loc = AppLocalizations.of(context);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
              '${loc.cartOrderSendFailed(response.statusCode.toString())}\nDétails: ${response.body}');
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

      // Vider le panier après une commande réussie (toujours, après envoi en base de données)
      await _clearCart();

      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.cartOrderSuccess),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

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

  void _orderViaWhatsApp(BuildContext context) async {
    final address = addressController.text;

    const double _SERVICE_FEE_RATE = 0.30;
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
      buffer.write(
          '\n${loc.cartWhatsappProductLine(item['product']['name'], quantity, (price * 1.30).toStringAsFixed(2))}');
    }

    buffer.write('\n${loc.cartWhatsappTotal(total.toStringAsFixed(2))}');
    buffer.write('\n\n${loc.cartWhatsappDelivery(address)}');
    buffer.write('\n\n${loc.cartWhatsappContact(phoneController.text.trim())}');

    if (latitude != null && longitude != null) {
      buffer.write(
          '\n\n${loc.cartWhatsappMapLink('https://maps.google.com/?q=$latitude,$longitude')}');
    } else {
      buffer.write('\n${loc.cartWhatsappGpsUnavailable}');
    }

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
        totalPrice: total,
        paymentMethod: 'WhatsApp',
        status: 'en cours',
        latitude: latitude,
        longitude: longitude,
        villeId:
            1, // Default value, you might want to get this from user selection
      );

      if (orderResult != null) {
        final loc = AppLocalizations.of(context);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
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
    if (cartItems.isEmpty ||
        loggedInUserName == null ||
        loggedInUserName!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CheckoutStepper(
          cities: _cities,
          onConfirm: (villeId, city, quartier, avenue, phone) {
            setState(() {
              _selectedCityId = villeId;
              addressController.text = '$avenue, $quartier, $city';
              phoneController.text = phone;
            });
            Navigator.pop(context); // Fermer le BottomSheet
            onConfirm(); // Exécuter l'action de confirmation
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    double totalAmount = cartItems.fold(
      0.0,
      (double sum, item) {
        final price =
            double.tryParse(item['product']['price'].toString()) ?? 0.0;
        return sum + (price * item['quantity']);
      },
    );

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
        title: Text(loc.cartTitle,
            style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor ??
                    Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.history,
                color: Theme.of(context).appBarTheme.foregroundColor ??
                    Colors.white),
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
              padding: const EdgeInsets.all(16),
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
                            loc.cartAllFeesIncluded,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.cartTotalFinal,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${tottalAmount.toStringAsFixed(2)} \$',
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CheckoutStepper extends StatefulWidget {
  final List<dynamic> cities;
  final Function(
          int cityId, String city, String quartier, String avenue, String phone)
      onConfirm;

  const CheckoutStepper({
    Key? key,
    required this.cities,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _CheckoutStepperState createState() => _CheckoutStepperState();
}

class _CheckoutStepperState extends State<CheckoutStepper> {
  int _currentStep = 0;
  int? _selectedCityId;
  final _quartierController = TextEditingController();
  final _avenueController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _quartierController.dispose();
    _avenueController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validatePhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^243[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: 500, // Hauteur fixe ou dynamique
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            loc.cartStepFinalizing,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_selectedCityId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.cartStepVilleSelectError)),
                    );
                    return;
                  }
                } else if (_currentStep == 1) {
                  if (_quartierController.text.isEmpty ||
                      _avenueController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.cartStepFillAll)),
                    );
                    return;
                  }
                } else if (_currentStep == 2) {
                  if (!_validatePhoneNumber(_phoneController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.cartStepPhoneInvalid)),
                    );
                    return;
                  }
                  // Finaliser
                  final cityName = widget.cities.firstWhere(
                      (c) => c['id'] == _selectedCityId,
                      orElse: () => {'nom': loc.commonUnknown})['nom'];

                  widget.onConfirm(
                    _selectedCityId!,
                    cityName,
                    _quartierController.text,
                    _avenueController.text,
                    _phoneController.text,
                  );
                  return;
                }

                setState(() {
                  if (_currentStep < 2) _currentStep += 1;
                });
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backdColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_currentStep == 2
                            ? loc.cartDialogConfirm
                            : loc.cartStepContinue),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(loc.cartStepCancel),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text(loc.cartStepVilleTitle),
                  content: DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    hint: Text(loc.cartStepVilleHint),
                    items: widget.cities.map<DropdownMenuItem<int>>((city) {
                      return DropdownMenuItem<int>(
                        value: city['id'],
                        child: Text(city['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                      });
                    },
                  ),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text(loc.cartStepAddressTitle),
                  content: Column(
                    children: [
                      TextField(
                        controller: _quartierController,
                        decoration: InputDecoration(
                          labelText: loc.cartStepQuartierLabel,
                          hintText: loc.cartStepQuartierHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _avenueController,
                        decoration: InputDecoration(
                          labelText: loc.cartStepAvenueLabel,
                          hintText: loc.cartStepAvenueHint,
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text(loc.cartStepContactTitle),
                  content: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: loc.cartStepMobileMoneyLabel,
                      hintText: loc.cartStepMobileMoneyHint,
                      helperText: loc.cartStepMobileMoneyHelper,
                    ),
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
