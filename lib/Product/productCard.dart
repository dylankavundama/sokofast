import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Product/ProductDetailScreen.dart';
import 'package:soko/style.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({super.key, required this.product});

  // Constante pour la majoration de prix
  static const double _PRICE_MARKUP = 1.30;

  // Fonction utilitaire pour augmenter un prix de 30%
  String _addMarkup(dynamic priceString) {
    try {
      if (priceString == null || priceString.toString().isEmpty) {
        return '0.00';
      }
      final double originalPrice = double.tryParse(priceString.toString()) ?? 0.0;
      final double newPrice = originalPrice * _PRICE_MARKUP;
      // Retourne le prix formaté avec deux décimales
      return newPrice.toStringAsFixed(2);
    } catch (e) {
      // En cas d'erreur de parsing, retourne le prix par défaut
      return '0.00';
    }
  }

  // Formater le prix avec séparateurs de milliers
  String _formatPrice(String price) {
    try {
      final double priceValue = double.parse(price);
      if (priceValue >= 1000) {
        return priceValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
      }
      return price;
    } catch (e) {
      return price;
    }
  }

  // Calculer le pourcentage de réduction
  double? _calculateDiscount(String regularPrice, String salePrice) {
    try {
      final double regular = double.parse(regularPrice);
      final double sale = double.parse(salePrice);
      if (regular > sale && regular > 0) {
        return ((regular - sale) / regular) * 100;
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    
    // 1. Calculer le nouveau prix régulier avec majoration
    final String newRegularPrice = _addMarkup(product['regular_price']);

    // 2. Calculer le nouveau prix de solde avec majoration
    final String originalSalePrice = product['sale_price'] ?? '';
    final String newSalePrice = _addMarkup(originalSalePrice);

    final imageUrl = product['images'] != null && product['images'].isNotEmpty
        ? product['images'][0]['src']
        : '';

    final bool hasSale = originalSalePrice.isNotEmpty && 
                        newSalePrice != newRegularPrice &&
                        double.tryParse(newSalePrice) != null &&
                        double.tryParse(newRegularPrice) != null &&
                        double.parse(newSalePrice) < double.parse(newRegularPrice);
    
    final discount = hasSale 
        ? _calculateDiscount(newRegularPrice, newSalePrice)
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 💡 NOUVEAU : Container pour l'image avec badge de réduction
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // 💡 NOUVEAU : Badge de réduction
                if (hasSale && discount != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 💡 NOUVEAU : Contenu amélioré avec contraintes pour éviter les débordements
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du produit
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Prix
                    hasSale
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${_formatPrice(newRegularPrice)} \$',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          decoration: TextDecoration.lineThrough,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PROMO',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Flexible(
                                child: Text(
                                  '${_formatPrice(newSalePrice)} \$',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryYellow,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Flexible(
                            child: Text(
                              '${_formatPrice(newRegularPrice)} \$',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryYellow,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}