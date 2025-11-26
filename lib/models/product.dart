class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int categoryId;
  final String? imageUrl;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      categoryId: json['category_id'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'image_url': imageUrl,
    };
  }
}