import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Product/ProductDetailScreen.dart';
import 'package:soko/style.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({super.key, required this.product});

  // Fonction utilitaire pour augmenter un prix de 25%
  String _addTwentyFivePercent(dynamic priceString) {
    try {
      if (priceString == null || priceString.toString().isEmpty) {
        return '0.00';
      }
      final double originalPrice = double.tryParse(priceString.toString()) ?? 0.0;
      final double newPrice = originalPrice * 1.30;
      // Retourne le prix formaté avec deux décimales
      return newPrice.toStringAsFixed(2);
    } catch (e) {
      // En cas d'erreur de parsing, retourne le prix par défaut
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    
    // 1. Calculer le nouveau prix régulier avec +25%
    final String newRegularPrice = _addTwentyFivePercent(product['regular_price']);

    // 2. Calculer le nouveau prix de solde avec +25%
    final String originalSalePrice = product['sale_price'] ?? '';
    final String newSalePrice = _addTwentyFivePercent(originalSalePrice);

    final imageUrl = product['images'] != null && product['images'].isNotEmpty
        ? product['images'][0]['src']
        : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // NOTE : Le détail de produit recevra l'objet produit original, 
            // mais l'affichage ici sera modifié. Si l'écran de détail 
            // doit aussi avoir le prix majoré, vous devrez modifier 
            // la façon dont les données sont passées ou traitées sur 
            // cet écran.
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              color: white,
              child: imageUrl.isNotEmpty
                  ? Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        height: 160,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 60),
                      ),
                    )
                  : const Center(child: Icon(Icons.image, size: 60)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.actor(
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              // Utiliser newSalePrice et newRegularPrice pour la comparaison et l'affichage
              child: originalSalePrice.isNotEmpty && newSalePrice != newRegularPrice
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$newRegularPrice \$', // Prix régulier majoré
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$newSalePrice \$', // Prix de solde majoré
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryYellow,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$newRegularPrice \$', // Prix unique majoré
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryYellow,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}