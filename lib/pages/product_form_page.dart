import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/image_picker_service.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  ProductFormPage({this.product});

  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  List<Category> _categories = [];
  Category? _selectedCategory;
  PickedImage? _imageFile;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await apiService.getCategories();
      setState(() {
        _categories = categories;
        if (widget.product != null) {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat.id == widget.product!.categoryId,
            orElse: () => _categories.first,
          );
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _pickImage({ImageSource? source}) async {
    try {
      final pickedImage = await _imagePickerService.pickImage(context, source: source);

      if (pickedImage != null) {
        setState(() {
          _imageFile = pickedImage;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }


  void _showImageSourceDialog() {
    // For web, directly pick image without dialog
    if (kIsWeb) {
      _pickImage();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Product product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        categoryId: _selectedCategory!.id!,
        imageUrl: widget.product?.imageUrl, // Will be updated by server if new image uploaded
      );

      if (widget.product == null) {
        await apiService.createProduct(product, imageFile: _imageFile);
      } else {
        await apiService.updateProduct(widget.product!.id!, product, imageFile: _imageFile);
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
      body: _isLoadingCategories
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? 'Please enter stock' : null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            int currentStock = int.tryParse(_stockController.text) ?? 0;
                            if (currentStock > 0) {
                              _stockController.text = (currentStock - 1).toString();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            int currentStock = int.tryParse(_stockController.text) ?? 0;
                            _stockController.text = (currentStock + 1).toString();
                          },
                        ),
                      ],
                    ),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _imageFile != null
                                ? 'New image selected'
                                : widget.product?.imageUrl != null
                                    ? 'Current image (tap to change)'
                                    : 'No image selected',
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: _showImageSourceDialog,
                        ),
                      ],
                    ),
                    if (_imageFile != null)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: _imagePickerService.buildImagePreview(_imageFile, width: 150, height: 150),
                      )
                    else if (widget.product?.imageUrl != null)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Image.network(
                          widget.product!.imageUrl!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: 150,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            );
                          },
                        ),
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