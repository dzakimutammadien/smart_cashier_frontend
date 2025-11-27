import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'product_form_page.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    _productsFuture = apiService.getProducts().then((products) {
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
      return products;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesQuery = product.name.toLowerCase().contains(query) ||
                             (product.description?.toLowerCase().contains(query) ?? false);
        final matchesCategory = _selectedCategory == null || product.categoryId == _selectedCategory!.id;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _createProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProductFormPage()),
    );
    if (result == true) {
      setState(() {
        _loadProducts();
      });
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProductFormPage(product: product)),
    );
    if (result == true) {
      setState(() {
        _loadProducts();
      });
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteProduct(id);
        setState(() {
          _loadProducts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Filter by category',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<Category>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _filterProducts();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
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
                  return Center(child: Text('No products found'));
                } else {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      Product product = _filteredProducts[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(child: CircularProgressIndicator());
                                      },
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
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '\$${product.price}',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  Text('Stock: ${product.stock}'),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 20),
                                        onPressed: () => _editProduct(product),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteProduct(product.id!),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProduct,
        child: Icon(Icons.add),
      ),
    );
  }
}