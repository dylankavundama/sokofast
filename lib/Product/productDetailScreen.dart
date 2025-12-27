import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/Product/productCard.dart';
import 'package:soko/Screen/CartScreen.dart';
import 'package:soko/Widget/fullImage.dart';
import 'package:soko/comment.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/order.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart';
<<<<<<< Updated upstream
import 'package:soko/utils/responsive.dart';
=======
>>>>>>> Stashed changes

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<Map<String, dynamic>> cartItems = [];
  late TextEditingController nameController;
  late TextEditingController addressController;
  
  // 💡 NOUVEAU : États pour les produits récemment ajoutés
  List<dynamic> _recentProducts = [];
  bool _isLoadingRecentProducts = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    addressController = TextEditingController();
    _loadCartLocally();
    _fetchRecentProducts(); // Charger les produits récents
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // 💡 NOUVEAU : Fonction pour récupérer les produits récemment ajoutés
  Future<void> _fetchRecentProducts() async {
    setState(() {
      _isLoadingRecentProducts = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.babutik.com/wp-json/wc/v3/products?per_page=8&orderby=date&order=desc'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('ck_20c9eaf44a30b5028558551525a1b24201ce8293:cs_d2f987d16ac480a59f04a5fefdf563a269667ca3'))}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Exclure le produit actuel de la liste
        final filteredProducts = data.where((product) => 
          product['id'] != widget.product['id']
        ).take(6).toList(); // Limiter à 6 produits
        
        setState(() {
          _recentProducts = filteredProducts;
          _isLoadingRecentProducts = false;
        });
      } else {
        setState(() {
          _isLoadingRecentProducts = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des produits récents: $e');
      setState(() {
        _isLoadingRecentProducts = false;
      });
    }
  }

  // NOUVELLE FONCTION: Calculer le prix avec une majoration de 30%
  double _calculatePriceWithMarkup(dynamic priceValue) {
    // Tente d'analyser la valeur comme un double, sinon utilise 0.0
    final double originalPrice = double.tryParse(priceValue?.toString() ?? '') ?? 0.0;
    // Ajoute 30%
    return originalPrice * 1.30;
  }
  
  // Reste des méthodes inchangées...
  
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
    final loc = AppLocalizations.of(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      // Rediriger vers l'écran de connexion/inscription
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.productLoginRequired)),
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
      SnackBar(
        content: Text(
          loc.productAddedToCart,
          style: const TextStyle(color: primaryYellow),
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

      final loc = AppLocalizations.of(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Commande enregistrée avec succès') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(loc.productOrderPlaced,
                    style: const TextStyle(color: Colors.white))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.productOrderFailed)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.productNetworkError)),
        );
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.productNetworkError}: ${e.toString()}')),
      );
    }
  }

  void showOrderDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final product = widget.product;
    // Utiliser le prix majoré pour le dialogue
    final price = _calculatePriceWithMarkup(product['price']); 
    final total = price * _quantity;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.productOrderComplete),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.productYourName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: loc.productYourAddress,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.productOrderSummary(product['name'], _quantity, total.toStringAsFixed(2)),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.productChoosePayment,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text(
                    loc.cartWhatsapp,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< Updated upstream
                        const SnackBar(
                            content:
                                Text("Veuillez remplir le nom et l'adresse"),
                            duration: Duration(seconds: 3),
                        ),
=======
                        SnackBar(
                            content: Text(loc.productFillNameAddress)),
>>>>>>> Stashed changes
                      );
                      return;
                    }
                    // Fermer le dialogue d'abord
                    Navigator.pop(context);
                    // Attendre un court instant pour s'assurer que le dialogue est fermé
                    await Future.delayed(const Duration(milliseconds: 100));
                    // Appeler la fonction
                    try {
                      _sendOrderViaWhatsApp(
                        name: nameController.text,
                        address: addressController.text,
                        quantity: _quantity,
                        product: product,
                        total: total, // Utilise le total majoré
                      );
                    } catch (e) {
                      print('Erreur lors de l\'envoi WhatsApp: $e');
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
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone_android, color: Colors.white),
                  label: Text(
                    loc.cartMobileMoney,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    // Fermer le dialogue d'abord
                    Navigator.pop(context);
                    // Attendre un court instant pour s'assurer que le dialogue est fermé
                    await Future.delayed(const Duration(milliseconds: 100));
                    // Appeler la fonction
                    try {
                      _showMobileMoneyOptions(context, total); // Utilise le total majoré
                    } catch (e) {
                      print('Erreur lors de l\'affichage Mobile Money: $e');
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
    // Utiliser le prix majoré pour le message WhatsApp
    final priceWithMarkup = _calculatePriceWithMarkup(product['price']);
    
    final loc = AppLocalizations.of(context);
    final message = loc.productWhatsappMessage(
      name,
      product['name'],
      quantity,
      priceWithMarkup.toStringAsFixed(2),
      total.toStringAsFixed(2),
      address,
    );

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
              // IMPORTANT: Enregistrer le prix majoré dans l'historique
              'price': priceWithMarkup, 
              'quantity': quantity,
            }
          ],
          total: total,
          address: address,
          paymentMethod: 'WhatsApp',
        );

        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.productCouldNotOpenWhatsapp)),
        );
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.productNetworkError}: ${e.toString()}')),
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
      status: 'Pending', // Statut par défaut
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList('orders') ?? [];
    orders.add(jsonEncode(newOrder.toJson()));
    await prefs.setStringList('orders', orders);

    // Supprimé le SnackBar vide/inutile ici
  }

  final commentController = TextEditingController();

  void _showMobileMoneyOptions(BuildContext context, double totalPrice) {
    final loc = AppLocalizations.of(context);
    final name = nameController.text.trim();
    final address = addressController.text.trim();

    // Vérification: Si nom/adresse sont vides, on affiche le premier dialogue
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cartNeedAddressOrGps)),
      );
      // On ne fait rien de plus, l'utilisateur devra ré-appeler la fonction depuis le dialogue
      return; 
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
            final loc = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(loc.productPaymentMethod),
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
                              child: Text(loc.productPaymentNumber(method.value['number']!)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: method.value['number']!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(loc.productNumberCopied(method.key))),
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
                    }),
                    if (selectedMethod.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: loc.productTransactionId,
                          hintText: loc.productTransactionIdHint,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => transactionId = value,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (transactionId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.productEnterTransactionId),
                              ), 
                            );
                            return;
                          }
                          
                          // Utiliser le prix majoré pour l'enregistrement
                          final priceWithMarkup = _calculatePriceWithMarkup(widget.product['price']);

                          await _saveOrderToHistory(
                            products: [
                              {
                                'id': widget.product['id'],
                                'name': widget.product['name'],
                                'price': priceWithMarkup, // Prix majoré
                                'quantity': _quantity,
                              }
                            ],
                            total: totalPrice, // Total majoré passé en argument
                            address: address,
                            paymentMethod: selectedMethod,
                          );

                          sendOrderToAdmin(
                            name: name,
                            address: address,
                            transactionId: transactionId,
                            quantity: _quantity,
                            productName: widget.product['name'],
                            totalPrice: totalPrice, // Total majoré passé en argument
                            paymentMethod: selectedMethod,
                          );

                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          loc.productConfirmOrder,
                          style: const TextStyle(color: Colors.white),
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
    final loc = AppLocalizations.of(context);
    final product = widget.product;
    // Utiliser le prix majoré pour l'affichage
    final price = _calculatePriceWithMarkup(product['price']); 
    final total = price * _quantity;
    final images = product['images'] as List? ?? [];

    return Scaffold(
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
<<<<<<< Updated upstream
                    padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                    child: Responsive.centerContent(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'No name',
                            style: GoogleFonts.actor(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 22, tablet: 26, desktop: 30),
                              color: Colors.black,
=======
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'No name',
                          style: GoogleFonts.actor(
                            fontSize: 22,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Affichage du prix majoré
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
                            label: Text(loc.productAddToCart),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
>>>>>>> Stashed changes
                            ),
                          ),
                          SizedBox(height: Responsive.getVerticalPadding(context) * 0.5),
                          // Affichage du prix majoré
                          Text(
                            '${price.toStringAsFixed(2)} \$', 
                            style: GoogleFonts.actor(
                              fontSize: Responsive.getAdaptiveFontSize(context, mobile: 20, tablet: 24),
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: Responsive.getVerticalPadding(context) * 0.5),
                          OutlinedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Ajouter au panier'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(
                                  double.infinity,
                                  Responsive.getVerticalPadding(context) * 6.25,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.getVerticalPadding(context) * 2,
                                ),
                              ),
                              onPressed: _addToCart),
                        ],
                      ),
                    ),
                  ),

                  // TabBar
                  TabBar(
                    tabs: [
                      Tab(text: loc.productDescriptionTab),
                      Tab(text: loc.productCommentsTab),
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
<<<<<<< Updated upstream
                          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                          child: Responsive.centerContent(
                            context,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 22),
                                    fontWeight: FontWeight.bold,
                                  ),
=======
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.productDescription,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
>>>>>>> Stashed changes
                                ),
                                SizedBox(height: Responsive.getVerticalPadding(context)),
                              product['description'] != null &&
                                      product['description']
                                          .toString()
                                          .isNotEmpty
                                  ? Html(data: product['description'])
                                  : Text(
                                      loc.productNoDescription,
                                      style: GoogleFonts.abel(
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                              const SizedBox(height: 24),

                              // Sélecteur de quantité
                              Row(
                                children: [
                                  Text(
                                      loc.productQuantity,
                                      style: const TextStyle(fontSize: 16)),
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
                                  // Affichage du total basé sur le prix majoré
                                  Text(
                                    '${loc.productTotal} ${total.toStringAsFixed(2)} \$',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Boutons d'action
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      label: Text(
                                        loc.productToCart,
                                        style: const TextStyle(color: Colors.white),
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
                              const SizedBox(height: 32),
                              
                              // 💡 NOUVEAU : Section produits récemment ajoutés
                              if (_recentProducts.isNotEmpty || _isLoadingRecentProducts) ...[
                                const Divider(height: 32),
                                const Text(
                                  'Produits récemment ajoutés',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _isLoadingRecentProducts
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: Responsive.getGridColumnCount(context),
                                          crossAxisSpacing: Responsive.getGridSpacing(context),
                                          mainAxisSpacing: Responsive.getGridSpacing(context) * 1.33,
                                          childAspectRatio: Responsive.getProductAspectRatio(context),
                                        ),
                                        itemCount: _recentProducts.length,
                                        itemBuilder: (context, index) {
                                          final product = _recentProducts[index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProductDetailScreen(
                                                    product: product,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ProductCard(product: product),
                                          );
                                        },
                                      ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                          ),
                        ),

                        // Onglet Commentaires
                        CommentSection(
                          productId: widget.product['id'],
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