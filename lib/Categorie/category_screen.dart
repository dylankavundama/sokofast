import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:soko/style.dart';
import 'dart:convert';
import 'category_item.dart';
import 'products_by_category_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> addActivity(String message) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> activities = prefs.getStringList('activities') ?? [];
  activities.insert(0, message); // ajoute en haut
  if (activities.length > 30) {
    activities = activities.sublist(0, 30); // limite à 30
  }
  await prefs.setStringList('activities', activities);
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.babutik.com/wp-json/wc/v3/products/categories'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('ck_ad48e33210f0327f5126c4bb84d79ba833080d52:cs_2ec17813a81fb24e2ef4029223cc8e45f3764e0a'))}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backdColor,
        title: const Text(
          'Catégories',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: loading())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryItem(
                      category: category,
                      onTap: () {
                        addActivity('Catégorie consultée: ${category['name']}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsByCategoryScreen(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}