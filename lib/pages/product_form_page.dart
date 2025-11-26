import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  ProductFormPage({this.product});

  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _categoryIdController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _categoryIdController = TextEditingController(text: widget.product?.categoryId.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryIdController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Product product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        categoryId: int.parse(_categoryIdController.text),
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );

      if (widget.product == null) {
        await apiService.createProduct(product);
      } else {
        await apiService.updateProduct(widget.product!.id!, product);
      }

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Create Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter price' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter stock' : null,
              ),
              TextFormField(
                controller: _categoryIdController,
                decoration: InputDecoration(labelText: 'Category ID'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter category ID' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(widget.product == null ? 'Create' : 'Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}