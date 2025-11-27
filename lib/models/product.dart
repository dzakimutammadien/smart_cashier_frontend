// HAPUS BARIS INI:
// import 'dart:io';

class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int categoryId;
  final String? imageUrl;
  final Map<String, dynamic>? category;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
    this.category,
  });

  // HAPUS METHOD INI:
  // static String _getImageBaseUrl() {
  //   if (Platform.isAndroid) {
  //     return 'http://10.0.2.2:8000/storage/';
  //   }
  //   return 'http://localhost:8000/storage/';
  // }

  factory Product.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'] ?? json['image_url'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('storage/')) {
        imageUrl = imageUrl.replaceFirst('storage/', '');
      }
      // UNTUK WEB, SELALU PAKAI localhost
      imageUrl = 'http://localhost:8000/storage/$imageUrl';
    }

    print('🖼️ DEBUG Product.fromJson:');
    print('   - ID: ${json['id']}');
    print('   - Name: ${json['name']}');
    print('   - Raw image: ${json['image']}');
    print('   - URL: $imageUrl');

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: int.parse(json['stock'].toString()),
      categoryId: int.parse(json['category_id'].toString()),
      imageUrl: imageUrl,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    String? relativeImageUrl = imageUrl;
    
    if (relativeImageUrl != null && relativeImageUrl.startsWith('http://localhost:8000/storage/')) {
      relativeImageUrl = relativeImageUrl.replaceFirst('http://localhost:8000/storage/', '');
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'image': relativeImageUrl,
    };
  }
}