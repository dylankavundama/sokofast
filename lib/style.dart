import 'package:flutter/material.dart';

// ignore: camel_case_types
class loading extends StatelessWidget {
  const loading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator())),
    );
  }
}

// Jaune/orangé principal du logo
const Color primaryYellow = Color(0xFFF2B316);

// Blanc utilisé pour la lettre "b"
const Color white = Color(0xFFFFFFFF);

// Noir de fond
const Color black = Color(0xFF000000);
const Color backdColor = primaryYellow;

Map<int, Color> primaryYellowShades = {
  50: Color(0xFFFFF8E1),
  100: Color(0xFFFFECB3),
  200: Color(0xFFFFE082),
  300: Color(0xFFFFD54F),
  400: Color(0xFFFFCA28),
  500: primaryYellow,
  600: Color(0xFFEDB30C),
  700: Color(0xFFE6A700),
  800: Color(0xFFD99900),
  900: Color(0xFFCC8B00),
};

MaterialColor customYellowSwatch =
    MaterialColor(primaryYellow.value, primaryYellowShades);
 

// class CartManager with ChangeNotifier {
//   final List<Map<String, dynamic>> _items = [];

//   List<Map<String, dynamic>> get items => _items;
  
//   void addItem(Map<String, dynamic> product, int quantity) {
//     // Vérifie si le produit existe déjà
//     final index = _items.indexWhere((item) => item['product']['id'] == product['id']);
    
//     if (index >= 0) {
//       _items[index]['quantity'] += quantity;
//     } else {
//       _items.add({
//         'product': product,
//         'quantity': quantity,
//       });
//     }
//     notifyListeners();
//   }
  
//   void removeItem(int index) {
//     _items.removeAt(index);
//     notifyListeners();
//   }
  
//   void updateQuantity(int index, int newQuantity) {
//     if (newQuantity > 0) {
//       _items[index]['quantity'] = newQuantity;
//       notifyListeners();
//     }
//   }
  
//   void clearCart() {
//     _items.clear();
//     notifyListeners();
//   }
  
//   double get totalAmount {
//     return _items.fold(0, (sum, item) {
//       final price = double.parse(item['product']['price']);
//       return sum + (price * item['quantity']);
//     });
//   }
// }