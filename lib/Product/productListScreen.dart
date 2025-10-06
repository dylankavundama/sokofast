import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/Product/productCard.dart';
import 'package:soko/Screen/ProfileScreen.dart';
import 'package:soko/style.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Map<String, List<dynamic>> categorizedProducts = {};
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, List<dynamic>> filteredProducts = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = categorizedProducts;
        _isSearching = false;
      });
      return;
    }

    Map<String, List<dynamic>> results = {};
    categorizedProducts.forEach((category, products) {
      List<dynamic> matchedProducts = products.where((product) {
        String name = product['name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      if (matchedProducts.isNotEmpty) {
        results[category] = matchedProducts;
      }
    });

    setState(() {
      filteredProducts = results;
      _isSearching = true;
    });
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
            // 'https://www.babutik.com/wp-json/wc/v3/products?per_page=100'),
              'https://www.easykivu.com/wp/wp-json/wc/v3/products?per_page=100'),
        // headers: {
        //   'Authorization':
        //       'Basic ${base64Encode(utf8.encode('ck_ad48e33210f0327f5126c4bb84d79ba833080d52:cs_2ec17813a81fb24e2ef4029223cc8e45f3764e0a'))}',
        // },

          headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('ck_898b353c3d1e748271c6e873948caaf87ec30d1e:cs_b2ee223b023699dd8de97b409a23b929963422c2'))}',}
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, List<dynamic>> grouped = {};

        for (var product in data) {
          List categories = product['categories'];
          if (categories.isEmpty) continue;

          for (var cat in categories) {
            String name = cat['name'];
            if (!grouped.containsKey(name)) grouped[name] = [];
            grouped[name]!.add(product);
          }
        }

        setState(() {
          categorizedProducts = grouped;
          filteredProducts = grouped;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: _searchProducts,
              )
            : Image.asset(height: 55, 'assets/icon.png'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: primaryYellow,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  filteredProducts = categorizedProducts;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          // IconButton(
          //   icon: const Icon(
          //     Icons.person,
          //     color: white,
          //   ),
          //   onPressed: () async {
          //     final prefs = await SharedPreferences.getInstance();
          //     await prefs.setBool('isLoggedIn', false);
          //     // ignore: use_build_context_synchronously
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => ProfileScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: isLoading
          ? const loading()
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : RefreshIndicator(
                  onRefresh: fetchProducts,
                  child: ListView(
                    children: filteredProducts.entries.map((entry) {
                      final categoryName = entry.key;
                      final products = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 160,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: ProductCard(product: products[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
