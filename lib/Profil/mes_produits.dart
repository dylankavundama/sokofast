import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Product/add.dart';
import 'package:soko/Profil/EditProductScreen.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/style.dart';
<<<<<<< Updated upstream
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/utils/responsive.dart';
=======
>>>>>>> Stashed changes

class ImageViewerScreen extends StatelessWidget {
  final List<dynamic> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black, // Garde noir pour la visualisation d'images
      appBar: AppBar(
        backgroundColor: Colors.black, // Garde noir pour la visualisation d'images
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(
            initialPage: images.isNotEmpty && initialIndex < images.length
                ? initialIndex
                : 0),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index]['src'];
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

const String _consumerKey = 'ck_20c9eaf44a30b5028558551525a1b24201ce8293';
const String _consumerSecret = 'cs_d2f987d16ac480a59f04a5fefdf563a269667ca3';
const String _baseUrl = "https://www.babutik.com/wp-json/wc/v3";

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentUserEmail;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ CHARGER LES DONNÉES UTILISATEUR DEPUIS SHARED_PREFERENCES
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserEmail = prefs.getString('user_email');
      _currentUserName = prefs.getString('user_name');

      if (_currentUserEmail != null) {
        _loadMyProducts();
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          _hasError = true;
          _errorMessage = loc.myProductsNoUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        _hasError = true;
        _errorMessage = loc.myProductsUserError;
        _isLoading = false;
      });
    }
  }

  static Future<void> saveUserData(String email, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
    } catch (e) {
      print("Erreur sauvegarde utilisateur: $e");
    }
  }

  static Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
    } catch (e) {
      print("Erreur déconnexion: $e");
    }
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> _loadMyProducts() async {
    final loc = AppLocalizations.of(context);
    if (_currentUserEmail == null) {
      setState(() {
        _hasError = true;
        _errorMessage = loc.myProductsPleaseLogin;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final auth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    final headers = {
      "Authorization": "Basic $auth",
    };

    try {
      // Charger d'abord depuis le cache local
      await _loadCachedProducts();

      // Puis rafraîchir depuis l'API
      final response = await http.get(
        Uri.parse("$_baseUrl/products?status=publish&per_page=100"),
        headers: headers,
      );

      print("📦 Response status: ${response.statusCode}");
      print("👤 User: $_currentUserEmail");

      if (response.statusCode == 200) {
        final List<dynamic> allProducts = jsonDecode(response.body);

        final userProducts = allProducts.where((product) {
          return _isProductOwnedByUser(product);
        }).toList();

        userProducts
            .sort((a, b) => b['date_created'].compareTo(a['date_created']));

        await _saveProductsToCache(userProducts);

        setState(() {
          _products = userProducts;
          _isLoading = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _hasError = true;
          _errorMessage = error['message'] ?? 'Erreur inconnue';
          _isLoading = false;
        });
      }
    } catch (e) {
      // En cas d'erreur réseau, utiliser le cache
      if (_products.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "Erreur de connexion: $e";
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final loc = AppLocalizations.of(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.myProductsOfflineCache),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      print("❌ Erreur: $e");
    }
  }

  // ✅ VÉRIFIER SI LE PRODUIT APPARTIENT À L'UTILISATEUR
  bool _isProductOwnedByUser(Map<String, dynamic> product) {
    if (_currentUserEmail == null) return false;

    final metaData = product['meta_data'] ?? [];

    for (var meta in metaData) {
      if (meta['key'] == 'vendor_user_id' ||
          meta['key'] == 'user_email' ||
          meta['key'] == '_vendor_email') {
        final value = meta['value'].toString();
        if (value.toLowerCase() == _currentUserEmail!.toLowerCase()) {
          return true;
        }
      }
    }

    final productName = product['name']?.toString().toLowerCase() ?? '';
    final productDesc = product['description']?.toString().toLowerCase() ?? '';
    final userEmailPrefix = _currentUserEmail!.split('@')[0].toLowerCase();

    return productName.contains(userEmailPrefix) ||
        productDesc.contains(userEmailPrefix);
  }

  Future<void> _saveProductsToCache(List<dynamic> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = jsonEncode(products);
      await prefs.setString('cached_products_$_currentUserEmail', productsJson);
    } catch (e) {
      print("Erreur sauvegarde cache: $e");
    }
  }

  Future<void> _loadCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProductsJson =
          prefs.getString('cached_products_$_currentUserEmail');

      if (cachedProductsJson != null) {
        final List<dynamic> cachedProducts = jsonDecode(cachedProductsJson);
        setState(() {
          _products = cachedProducts;
        });
      }
    } catch (e) {
      print("Erreur chargement cache: $e");
    }
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => null,
    );

    final loc = AppLocalizations.of(context);
    if (product == null || !_isProductOwnedByUser(product)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.myProductsCannotDeleteProduct),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.myProductsConfirmDeleteTitle),
          content: Text(loc.myProductsConfirmDeleteQuestion(productName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.myProductsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.myProductsDelete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final auth = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    final headers = {
      "Authorization": "Basic $auth",
    };

    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/products/$productId?force=true"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final loc = AppLocalizations.of(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.myProductsDeletedSuccess(productName)),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Recharger la liste et mettre à jour le cache
        await _loadMyProducts();
      } else {
        final loc = AppLocalizations.of(context);
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${loc.myProductsErrorPrefix} ${error['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final loc = AppLocalizations.of(context);
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.myProductsLogoutText),
          content: Text(loc.myProductsLogoutQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.myProductsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.myProductsLogoutText,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await logoutUser();
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/login'); // Adaptez à votre route de login
      }
    }
  }

  String _formatPrice(String price) {
    try {
      final double amount = double.parse(price);
      return '${amount.toStringAsFixed(2)} \$';
    } catch (e) {
      return '$price \$';
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myProductsTitle),
        centerTitle: true,
        backgroundColor: backdColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyProducts,
            tooltip: loc.myProductsRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddProductScreen()),
              ).then((_) => _loadMyProducts());
            },
            tooltip: loc.myProductsAdd,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'clear_cache') {
                _clearCache();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'clear_cache',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.myProductsClearCacheText),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(loc.myProductsLogoutText, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) => _loadMyProducts());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ✅ VIDER LE CACHE
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loc = AppLocalizations.of(context);
      await prefs.remove('cached_products_$_currentUserEmail');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.myProductsCacheCleared),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadMyProducts();
    } catch (e) {
      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${loc.myProductsErrorPrefix} $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.myProductsLoading),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              loc.myProductsErrorLoading,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMyProducts,
              icon: const Icon(Icons.refresh),
              label: Text(loc.myProductsRetry),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.myProductsNone,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              loc.myProductsNoneDesc,
              style: const TextStyle(color: Colors.grey),
            ),
            if (_currentUserEmail != null)
              Text(
                "${loc.myProductsConnectedAs} $_currentUserEmail",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(loc.myProductsCreateFirst),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyProducts,
      child: Column(
        children: [
          // En-tête utilisateur
          if (_currentUserEmail != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUserName ?? loc.myProductsDefaultUser,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _currentUserEmail!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    loc.myProductsCount(_products.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
            ),
          ),
          Expanded(
            child: Responsive.centerContent(
              context,
              ListView.builder(
                padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                itemCount: _products.length,
              itemBuilder: (context, index) {
                final loc = AppLocalizations.of(context);
                final product = _products[index];
                final String name = product['name'] ?? loc.myProductsNoName;
                final String price = product['regular_price'] ?? '0';
                final String description = product['description'] ?? '';
                final String date = product['date_created'] ?? '';
                final List<dynamic> images = product['images'] ?? [];
                final String? imageUrl =
                    images.isNotEmpty ? images[0]['src'] : null;
                final int productId = product['id'];

                return GestureDetector(
                  onTap: () {
                    // Naviguer vers l'écran de détails du produit
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(images: images),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(loc.myProductsNoImage,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatPrice(price),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.myProductsCreatedOn(_formatDate(date)),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // ➡️ Modifiez le onPressed du bouton "Modifier" :
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        // 💡 Le produit (Map<String, dynamic>) doit être passé au nouvel écran
                                        final bool? result =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditProductScreen(
                                                product:
                                                    product), // 'product' est la Map<String, dynamic>
                                          ),
                                        );

                                        // Si l'édition a réussi et que l'on revient (result est true), rafraîchir la liste
                                        if (result == true) {
                                          // ⚠️ Vous devez appeler ici votre fonction de rechargement des produits
                                          // Exemple : _fetchProducts();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text(loc.myProductsListRefreshed)),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: Text(loc.myProductsEdit),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _deleteProduct(productId, name),
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      label: Text(loc.myProductsDeleteText,
                                          style: const TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
