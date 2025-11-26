import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  Cart _cart = Cart();

  Cart get cart => _cart;

  double get totalPrice => _cart.totalPrice;
  int get totalItems => _cart.totalItems;

  void addToCart(Product product, {int quantity = 1}) {
    final cartItem = CartItem(product: product, quantity: quantity);
    _cart.addItem(cartItem);
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeItem(productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    _cart.updateQuantity(productId, quantity);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  bool isInCart(int productId) {
    return _cart.items.any((item) => item.product.id == productId);
  }

  int getQuantity(int productId) {
    final item = _cart.items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(id: -1, name: '', price: 0, stock: 0, categoryId: 0)),
    );
    return item.product.id == -1 ? 0 : item.quantity;
  }
}