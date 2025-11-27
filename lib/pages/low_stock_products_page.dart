import 'package:flutter/material.dart';
import 'package:smart_cashier_frontend/services/analytics_service.dart';

class LowStockProductsPage extends StatefulWidget {
  const LowStockProductsPage({super.key});

  @override
  State<LowStockProductsPage> createState() => _LowStockProductsPageState();
}

class _LowStockProductsPageState extends State<LowStockProductsPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  List<Map<String, dynamic>> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _analyticsService.getLowStockProducts();
      setState(() {
        _lowStockProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading low stock products: $e')),
        );
      }
    }
  }

  Future<void> _exportLowStockProducts() async {
    try {
      await _analyticsService.exportLowStockProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Low stock products exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting low stock products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportLowStockProducts,
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLowStockProducts,
              child: _lowStockProducts.isEmpty
                  ? const Center(
                      child: Text('No low stock products found'),
                    )
                  : ListView.builder(
                      itemCount: _lowStockProducts.length,
                      itemBuilder: (context, index) {
                        final product = _lowStockProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(product['name'] ?? 'Unknown Product'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock: ${product['stock'] ?? 0}'),
                                Text('Price: \$${product['price'] ?? 0}'),
                                Text('Category: ${product['category'] ?? 'N/A'}'),
                              ],
                            ),
                            leading: const Icon(Icons.warning, color: Colors.red),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}