import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../widgets/receipt_dialog.dart';

class PosPage extends StatefulWidget {
  @override
  _PosPageState createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  late Future<List<Product>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadRecommendations();
  }

  void _loadProducts() {
    _productsFuture = apiService.getProducts();
  }

  void _loadRecommendations() {
    _recommendationsFuture = apiService.getRecommendations(limit: 6);
  }

  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CartBottomSheet(
        apiService: apiService,
        reloadRecommendations: () => setState(() => _loadRecommendations()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Point of Sale'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadProducts();
                _loadRecommendations();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadProducts();
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products available'));
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Products Grid
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Product product = snapshot.data![index];
                        bool isInCart = cartProvider.isInCart(product.id!);
                        int quantity = cartProvider.getQuantity(product.id!);

                        return Card(
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image, size: 50, color: Colors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.green, fontSize: 14),
                                    ),
                                    Text('Stock: ${product.stock}', style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 8),
                                    if (isInCart)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove, size: 20),
                                            onPressed: quantity > 1
                                                ? () => cartProvider.updateQuantity(product.id!, quantity - 1)
                                                : () => cartProvider.removeFromCart(product.id!),
                                          ),
                                          Text('$quantity', style: TextStyle(fontSize: 16)),
                                          IconButton(
                                            icon: Icon(Icons.add, size: 20),
                                            onPressed: () => cartProvider.addToCart(product),
                                          ),
                                        ],
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                                        child: Text('Add to Cart'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(double.infinity, 36),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Recommendations Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended for You',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<List<Product>>(
                          future: _recommendationsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error loading recommendations: ${snapshot.error}'),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('No recommendations available'));
                            } else {
                              return Container(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    Product product = snapshot.data![index];
                                    bool isInCart = cartProvider.isInCart(product.id!);
                                    int quantity = cartProvider.getQuantity(product.id!);

                                    return Container(
                                      width: 160,
                                      margin: EdgeInsets.only(right: 8),
                                      child: Card(
                                        elevation: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                                  ? Image.network(
                                                      product.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[300],
                                                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '\$${product.price.toStringAsFixed(2)}',
                                                    style: TextStyle(color: Colors.green, fontSize: 12),
                                                  ),
                                                  SizedBox(height: 4),
                                                  if (isInCart)
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(Icons.remove, size: 16),
                                                          onPressed: quantity > 1
                                                              ? () => cartProvider.updateQuantity(product.id!, quantity - 1)
                                                              : () => cartProvider.removeFromCart(product.id!),
                                                        ),
                                                        Text('$quantity', style: TextStyle(fontSize: 12)),
                                                        IconButton(
                                                          icon: Icon(Icons.add, size: 16),
                                                          onPressed: () => cartProvider.addToCart(product),
                                                        ),
                                                      ],
                                                    )
                                                  else
                                                    ElevatedButton(
                                                      onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                                                      child: Text('Add', style: TextStyle(fontSize: 12)),
                                                      style: ElevatedButton.styleFrom(
                                                        minimumSize: Size(double.infinity, 30),
                                                        padding: EdgeInsets.symmetric(vertical: 4),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            onPressed: _showCart,
            child: Icon(Icons.shopping_cart),
          ),
          if (cartProvider.totalItems > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '${cartProvider.totalItems}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CartBottomSheet extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback reloadRecommendations;

  CartBottomSheet({required this.apiService, required this.reloadRecommendations});

  @override
  _CartBottomSheetState createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart (${cartProvider.totalItems} items)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: cartProvider.cart.items.isEmpty
                ? Center(child: Text('Cart is empty'))
                : ListView.builder(
                    itemCount: cartProvider.cart.items.length,
                    itemBuilder: (context, index) {
                      CartItem item = cartProvider.cart.items[index];
                      return ListTile(
                        leading: item.product.imageUrl != null
                            ? Image.network(
                                item.product.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.image),
                              )
                            : Icon(Icons.image, size: 50),
                        title: Text(item.product.name),
                        subtitle: Text('\$${item.product.price.toStringAsFixed(2)} x ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: item.quantity > 1
                                  ? () => cartProvider.updateQuantity(item.product.id!, item.quantity - 1)
                                  : () => cartProvider.removeFromCart(item.product.id!),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => cartProvider.addToCart(item.product),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => cartProvider.removeFromCart(item.product.id!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cartProvider.cart.items.isNotEmpty
                            ? () => cartProvider.clearCart()
                            : null,
                        child: Text('Clear Cart'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: cartProvider.cart.items.isNotEmpty
                            ? () => _checkout(context, cartProvider)
                            : null,
                        child: Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context, CartProvider cartProvider) async {
    showDialog(
      context: context,
      builder: (context) => ReceiptDialog(cart: cartProvider.cart),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // Prepare order data
          final items = cartProvider.cart.items.map((item) => {
            'product_id': item.product.id,
            'quantity': item.quantity,
          }).toList();

          // Call checkout API
          final response = await widget.apiService.checkout(items, cartProvider.totalPrice);

          if (response['success'] == true) {
            cartProvider.clearCart();
            Navigator.pop(context); // Close bottom sheet
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment confirmed and order saved!')),
            );
            // Refresh recommendations after purchase
            widget.reloadRecommendations();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save order: ${response['message']}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error during checkout: $e')),
          );
        }
      }
    });
  }
}