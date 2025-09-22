import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/style.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  final addressController = TextEditingController();
  String? loggedInUserName;

  @override
  void initState() {
    super.initState();
    _loadCartLocally();
    _loadLoggedInUser();
  }

  @override
  void dispose() {
    addressController.dispose();
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

  Future<Map<String, dynamic>?> sendOrderToDatabase({
    required BuildContext context,
    required String name,
    required String address,
    required String transactionId,
    required List<Map<String, dynamic>> products,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    final url = '$baseUrl/commande.php';

    try {
      for (final product in products) {
        if (!product.containsKey('product') ||
            !product['product'].containsKey('name') ||
            !product['product'].containsKey('price') ||
            !product.containsKey('quantity')) {
          throw Exception(
              'Données de produit mal formatées ou incomplètes dans le panier: ${product.toString()}');
        }

        final double productPrice =
            double.tryParse(product['product']['price'].toString()) ?? 0.0;
        final int productQuantity = (product['quantity'] as num).toInt();

        final double calculatedIndividualProductTotalPrice =
            productPrice * productQuantity;

        print('--- Sending Product Request ---');
        print('URL: $url');
        print('Product Name: ${product['product']['name']}');
        print('Quantity: $productQuantity');
        print(
            'Individual Product Total Price: $calculatedIndividualProductTotalPrice');

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
          }),
        );

        print('--- Response Received for ${product['product']['name']} ---');
        print('HTTP Status Code: ${response.statusCode}');
        print('Raw Response Body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final responseData = jsonDecode(response.body);
            if (responseData['message'] != null &&
                responseData['message'].contains('Commande enregistrée avec succès')) {
              print(
                  'Product "${product['product']['name']}" successfully registered on server.');
            } else {
              throw Exception(
                  'Réponse inattendue du serveur pour "${product['product']['name']}": ${responseData['message'] ?? response.body}');
            }
          } catch (e) {
            throw Exception(
                'Erreur lors de l\'analyse de la réponse JSON pour "${product['product']['name']}". Réponse brute: "${response.body}". Erreur: $e');
          }
        } else {
          String errorMessage =
              'Échec de l\'envoi du produit "${product['product']['name']}". Statut HTTP: ${response.statusCode}.';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            errorMessage += ' Corps de la réponse brut: "${response.body}"';
          }
          throw Exception(errorMessage);
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
        'status': 'en cours'
      };

      await _saveOrderToHistory(orderData);

      setState(() => cartItems.clear());
      await _saveCartLocally();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre commande a été traitée avec succès !"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      return orderData;
    } on http.ClientException catch (e) {
      print('HTTP Client Exception (Network Error): ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur réseau: ${e.message}. Vérifiez votre connexion internet ou l\'URL du serveur.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } on Exception catch (e) {
      print('General Order Processing Exception: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur lors du traitement de la commande: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return null;
  }

  void _showAddressDialog(VoidCallback onConfirm) {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Votre panier est vide")),
      );
      return;
    }

    if (loggedInUserName == null || loggedInUserName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Aucun utilisateur connecté. Veuillez vous connecter.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adresse de livraison'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Votre adresse de livraison',
              hintText: 'Ex: 123 Rue de la Paix, Quartier Les Volcans',
              border: OutlineInputBorder(),
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
                    const SnackBar(
                        content: Text("Veuillez remplir l'adresse de livraison")),
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

  void _orderViaWhatsApp(BuildContext context) async {
    final buffer = StringBuffer();
    double total = 0;

    buffer.writeln("Bonjour soko,\n\nJe souhaite commander :");

    for (var item in cartItems) {
      final product = item['product'];
      final name = product['name'];
      final quantity = item['quantity'];
      final price = double.tryParse(product['price'].toString()) ?? 0;
      final subtotal = price * quantity;
      total += subtotal;

      buffer.writeln(
          "$name\nQuantité: $quantity - ${price.toStringAsFixed(2)} \$ x $quantity = ${subtotal.toStringAsFixed(2)} \$\n");
    }

    buffer.writeln("Nom: $loggedInUserName");
    buffer.writeln("Adresse: ${addressController.text}");
    buffer.writeln("Total: ${total.toStringAsFixed(2)} \$");
    buffer.writeln("\nMerci de me confirmer la disponibilité.");

    final message = buffer.toString();
    const phone = '243973989083';
    final url = Uri.parse(
        'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}');

    try {
      final orderResult = await sendOrderToDatabase(
        context: context,
        name: loggedInUserName!,
        address: addressController.text,
        transactionId: 'whatsapp_${DateTime.now().millisecondsSinceEpoch}',
        products: cartItems,
        totalPrice: total,
        paymentMethod: 'WhatsApp',
      );

      if (orderResult != null) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")),
          );
        }
      } else {
        print('Order to database failed, not launching WhatsApp.');
      }
    } catch (e) {
      print('Error during WhatsApp order process: $e');
    }
  }

  Future<void> _saveOrderToHistory(Map<String, dynamic> order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList('orderHistory') ?? [];
    orders.add(jsonEncode(order));
    await prefs.setStringList('orderHistory', orders);
  }

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? orders = prefs.getStringList('orderHistory');
    if (orders == null) return [];
    return orders
        .map((order) => jsonDecode(order) as Map<String, dynamic>)
        .toList();
  }

  void _showMobileMoneyOptions(BuildContext context) {
    String selectedMethod = '';
    String transactionId = '';

    final paymentMethods = {
      'Mpesa': {
        'number': '0700000000',
        'logo': 'assets/pesa.png',
      },
      'Orange Money': {
        'number': '0890000000',
        'logo': 'assets/ora.png',
      },
      'Airtel Money': {
        'number': '0970000000',
        'logo': 'assets/air.webp',
      },
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double currentCartTotal = cartItems.fold(
              0,
              (sum, item) =>
                  sum +
                  ((double.tryParse(item['product']['price'].toString()) ?? 0) *
                      item['quantity']),
            );

            return AlertDialog(
              title: const Text('Mode de paiement Mobile Money'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Montant à payer: ${currentCartTotal.toStringAsFixed(2)} \$',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ...paymentMethods.entries.map((method) {
                      return ListTile(
                        leading: Image.asset(
                          method.value['logo']!,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, size: 32),
                        ),
                        title: Text(method.key),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text('Numero: ${method.value['number']}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: method.value['number']!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('${method.key} number copied')),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: selectedMethod == method.key
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () => setState(() => selectedMethod = method.key),
                      );
                    }).toList(),
                    if (selectedMethod.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID',
                          hintText: 'Entrez le code de transaction',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => transactionId = value,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (transactionId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Veuillez saisir l'ID de transaction"),
                              ),
                            );
                            return;
                          }

                          double total = cartItems.fold(
                            0,
                            (sum, item) =>
                                sum +
                                ((double.tryParse(item['product']['price']
                                            .toString()) ??
                                        0) *
                                    item['quantity']),
                          );

                          await sendOrderToDatabase(
                            context: context,
                            name: loggedInUserName!,
                            address: addressController.text,
                            transactionId: transactionId,
                            products: cartItems,
                            totalPrice: total,
                            paymentMethod: selectedMethod,
                          );

                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Confirmer la commande',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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
                      }).toList(),
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
                          label: const Text('Mobile Money',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showAddressDialog(
                              () => _showMobileMoneyOptions(context)),
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
