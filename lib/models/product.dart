import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.isActive,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final String imageUrl;
  final double price;
  final int stock;
  final bool isActive;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Product.fromMap(snapshot.id, snapshot.data() ?? const {});
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      category:
          data['categoryName'] as String? ?? data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: data['price'] is num ? (data['price'] as num).toDouble() : 0,
      stock: data['stock'] is num ? (data['stock'] as num).toInt() : 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
