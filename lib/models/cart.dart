import 'cart_item.dart';

class Cart {
  final List<CartItem> items;

  Cart({List<CartItem>? items}) : items = items ?? [];

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }

  void addItem(CartItem newItem) {
    final existingIndex = items.indexWhere((item) => item.product.id == newItem.product.id);
    if (existingIndex != -1) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + newItem.quantity,
      );
    } else {
      items.add(newItem);
    }
  }

  void removeItem(int productId) {
    items.removeWhere((item) => item.product.id == productId);
  }

  void updateQuantity(int productId, int quantity) {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
    }
  }

  void clear() {
    items.clear();
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
    );
  }
}