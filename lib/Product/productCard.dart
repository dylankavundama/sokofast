import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Product/ProductDetailScreen.dart';
import 'package:soko/style.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    final regularPrice = product['regular_price'] ?? '0';
    final salePrice = product['sale_price'] ?? '';
    final imageUrl = product['images'] != null && product['images'].isNotEmpty
        ? product['images'][0]['src']
        : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
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
              child: salePrice.isNotEmpty && salePrice != regularPrice
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$regularPrice \$',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$salePrice \$',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryYellow,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$regularPrice \$',
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
