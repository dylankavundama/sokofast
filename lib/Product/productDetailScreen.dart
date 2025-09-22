import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/Screen/CartScreen.dart';
import 'package:soko/Widget/fullImage.dart';
import 'package:soko/comment.dart';
import 'package:soko/order.dart';
import 'package:soko/style.dart';
import 'package:http/http.dart' as http;

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<Map<String, dynamic>> cartItems = [];
  late TextEditingController nameController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    addressController = TextEditingController();
    _loadCartLocally();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
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

  void _addToCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? true;

    if (!isLoggedIn) {
      // Rediriger vers l'écran de connexion/inscription
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour ajouter au panier.')),
      );
      return;
    }

    // Si connecté, ajouter au panier
    setState(() {
      cartItems.add({
        'product': widget.product,
        'quantity': _quantity,
      });
    });

    await _saveCartLocally();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ajouté au panier',
          style: TextStyle(color: primaryYellow),
        ),
      ),
    );
  }

  Future<void> sendOrderToAdmin({
    required String name,
    required String address,
    required String transactionId,
    required int quantity,
    required String productName,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    const url = 'https://soko.com/json/commande.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'address': address,
          'transaction_id': transactionId,
          'product_name': productName,
          'quantity': quantity,
          'payment_method': paymentMethod,
          'total_price': totalPrice,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Commande enregistrée avec succès') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Commande passée",
                    style: TextStyle(color: Colors.white))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send order')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void showOrderDialog(BuildContext context) {
    final product = widget.product;
    final price = double.tryParse(product['price']?.toString() ?? '') ?? 0.0;
    final total = price * _quantity;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Commande complète'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Votre adresse',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Produit: ${product['name']}\nQuantité: $_quantity\nTotal: ${total.toStringAsFixed(2)} \$',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez le mode de paiement :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Veuillez remplir le nom et l'adresse")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _sendOrderViaWhatsApp(
                      name: nameController.text,
                      address: addressController.text,
                      quantity: _quantity,
                      product: product,
                      total: total,
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone_android, color: Colors.white),
                  label: const Text(
                    'Mobile Money',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showMobileMoneyOptions(context, total);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendOrderViaWhatsApp({
    required String name,
    required String address,
    required int quantity,
    required dynamic product,
    required double total,
  }) async {
    final message = """
Bonjour, je m'appelle $name.

Je voudrais commander :
${product['name']}
Quantité: $quantity
Prix: ${product['price']} \$

Total: ${total.toStringAsFixed(2)} \$

Address: $address
""";

    const phone = '243973989083';
    final url = Uri.parse(
      'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        // Sauvegarde de la commande avant l'envoi
        await _saveOrderToHistory(
          products: [
            {
              'id': product['id'],
              'name': product['name'],
              'price': double.parse(product['price'].toString()),
              'quantity': quantity,
            }
          ],
          total: total,
          address: address,
          paymentMethod: 'WhatsApp',
        );

        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  int _getTotalCartItems() {
    return cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  Future<void> _saveOrderToHistory({
    required List<Map<String, dynamic>> products,
    required double total,
    required String address,
    required String paymentMethod,
  }) async {
    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      products: products,
      total: total,
      address: address,
      paymentMethod: paymentMethod,
      status: 'En préparation', // Statut par défaut
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList('orders') ?? [];
    orders.add(jsonEncode(newOrder.toJson()));
    await prefs.setStringList('orders', orders);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(''),
    )
        // Text("Commande enregistrée dans l'historique")),
        );
  }

  final commentController = TextEditingController();

  void _showMobileMoneyOptions(BuildContext context, double totalPrice) {
    final name = nameController.text.trim();
    final address = addressController.text.trim();

    // ✅ Vérification AVANT d'ouvrir la boîte de dialogue
    if (nameController.text.isEmpty || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir le nom et l'adresse")),
      );
      return showOrderDialog(context);
    }

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
            return AlertDialog(
              title: const Text('Mode de paiement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...paymentMethods.entries.map((method) {
                      return ListTile(
                        leading: Image.asset(
                          method.value['logo']!,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.payment, size: 32),
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
                                Clipboard.setData(ClipboardData(
                                    text: method.value['number']!));
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
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        onTap: () =>
                            setState(() => selectedMethod = method.key),
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
                                content:
                                    Text("Veuillez saisir l'ID de transaction"),
                              ),
                            );
                            return;
                          }

                          await _saveOrderToHistory(
                            products: [
                              {
                                'id': widget.product['id'],
                                'name': widget.product['name'],
                                'price': double.parse(
                                    widget.product['price'].toString()),
                                'quantity': _quantity,
                              }
                            ],
                            total: totalPrice,
                            address: address,
                            paymentMethod: selectedMethod,
                          );

                          sendOrderToAdmin(
                            name: name,
                            address: address,
                            transactionId: transactionId,
                            quantity: _quantity,
                            productName: widget.product['name'],
                            totalPrice: totalPrice,
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
    final product = widget.product;
    final price = double.tryParse(product['price']?.toString() ?? '') ?? 0.0;
    final total = price * _quantity;
    final images = product['images'] as List? ?? [];

    return Scaffold(
// Ajoutez cette méthode dans votre classe _ProductDetailScreenState

// Et remplacez votre floatingActionButton par ceci :
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            backgroundColor: backdColor,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen()),
            ),
          ),
          if (cartItems.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _getTotalCartItems().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: backdColor,
            // title: Text(
            //   'soko',
            //   style: GoogleFonts.abel(
            //     fontSize: 18,
            //     color: Colors.white,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),

            expandedHeight: MediaQuery.of(context).size.height * 0.5,

            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final image = images[index]['src'];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImagePage(imageUrl: image),
                            ),
                          ),
                          child: Hero(
                            tag: 'product-image-${product['id']}-$index',
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 300,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.error)),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: DefaultTabController(
              length: 2, // Deux onglets : Description et Commentaires
              child: Column(
                children: [
                  // Section d'information sur le produit
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'No name',
                          style: GoogleFonts.actor(
                            fontSize: 22,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${price.toStringAsFixed(2)} \$',
                          style: GoogleFonts.actor(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Ajouter au panier'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: _addToCart),
                      ],
                    ),
                  ),

                  // TabBar
                  const TabBar(
                    tabs: [
                      Tab(text: 'Description'),
                      Tab(text: 'Commentaires'),
                    ],
                    indicatorColor: backdColor,
                    labelColor: backdColor,
                    unselectedLabelColor: Colors.grey,
                  ),

                  // Contenu des onglets
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.5, // Hauteur ajustable
                    child: TabBarView(
                      children: [
                        // Onglet Description
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              product['description'] != null &&
                                      product['description']
                                          .toString()
                                          .isNotEmpty
                                  ? Html(data: product['description'])
                                  : Text(
                                      'No description available',
                                      style: GoogleFonts.abel(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                              const SizedBox(height: 24),

                              // Sélecteur de quantité
                              Row(
                                children: [
                                  const Text('Quantité:',
                                      style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                  ),
                                  Text('$_quantity',
                                      style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        setState(() => _quantity++),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Total: ${total.toStringAsFixed(2)} \$',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
//
                              // Boutons d'action
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      label: const Text(
                                        'Panier',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: backdColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      onPressed: _addToCart,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Onglet Commentaires
                        CommentSection(
                          productId: widget.product['id'],
                          //  compactMode: true, // Mode compact pour l'intégration dans le TabBar
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
