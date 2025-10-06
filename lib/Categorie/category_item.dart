import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soko/style.dart';
 

class CategoryItem extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;

  const CategoryItem({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'category-${category['id']}',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  child: category['image'] != null 
                      ? CachedNetworkImage(
                          imageUrl: category['image']['src'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Center(
                            child: loading(),
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.category, size: 50),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  category['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}