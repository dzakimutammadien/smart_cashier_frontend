import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'auth_service.dart';
import 'image_picker_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  final http.Client client;
  final Dio dio;
  final AuthService authService;

  ApiService({http.Client? client, Dio? dio, AuthService? authService})
      : client = client ?? http.Client(),
        dio = dio ?? Dio(),
        authService = authService ?? AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await authService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(Uri.parse('$baseUrl/products'), headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Decode sebagai Map karena response dari Laravel adalah JSON object
        Map<String, dynamic> responseData = json.decode(response.body);

        // Cek jika response success dan data ada
        if (responseData['success'] == true) {
          // Akses array products dari properti 'data'
          List<dynamic> data = responseData['data'];

          // Convert setiap item di array menjadi object Product
          List<Product> products = data.map((item) => Product.fromJson(item)).toList();

          print('Successfully loaded ${products.length} products');
          return products;
        } else {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(Uri.parse('$baseUrl/categories'), headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          List<Category> categories = data.map((item) => Category.fromJson(item)).toList();

          print('Successfully loaded ${categories.length} categories');
          return categories;
        } else {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getCategories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<Product> createProduct(Product product, {PickedImage? imageFile}) async {
    // Validation
    if (product.name.trim().isEmpty) {
      throw Exception('Product name cannot be empty');
    }
    if (product.price <= 0) {
      throw Exception('Product price must be greater than 0');
    }
    if (product.stock < 0) {
      throw Exception('Product stock cannot be negative');
    }
    if (product.categoryId <= 0) {
      throw Exception('Valid category must be selected');
    }

    try {
      final token = await authService.getToken();

      if (imageFile != null) {
        // Use multipart upload
        MultipartFile multipartFile;
        if (imageFile.isWeb && imageFile.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            imageFile.bytes!,
            filename: imageFile.fileName ?? 'image.jpg',
          );
        } else if (!imageFile.isWeb && imageFile.file != null) {
          multipartFile = await MultipartFile.fromFile(
            imageFile.file.path,
            filename: imageFile.fileName ?? 'image.jpg',
          );
        } else {
          throw Exception('Invalid image data');
        }

        FormData formData = FormData.fromMap({
          'name': product.name,
          'description': product.description,
          'price': product.price.toString(),
          'stock': product.stock.toString(),
          'category_id': product.categoryId.toString(),
          'image': multipartFile,
        });

        dio.options.headers['Authorization'] = 'Bearer $token';

        final response = await dio.post('$baseUrl/products', data: formData);

        print('Create Product Response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 201) {
          Map<String, dynamic> responseData = response.data;

          if (responseData['success'] == true) {
            return Product.fromJson(responseData['data']);
          } else {
            throw Exception('API Error: ${responseData['message']}');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Please login again');
        } else {
          throw Exception('Failed to create product: ${response.statusCode}');
        }
      } else {
        // Use JSON
        final headers = await _getHeaders();
        final response = await client.post(
          Uri.parse('$baseUrl/products'),
          headers: headers,
          body: json.encode(product.toJson()),
        );

        print('Create Product Response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 201) {
          Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            return Product.fromJson(responseData['data']);
          } else {
            throw Exception('API Error: ${responseData['message']}');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Please login again');
        } else {
          throw Exception('Failed to create product: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in createProduct: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(int id, Product product, {PickedImage? imageFile}) async {
    // Validation
    if (product.name.trim().isEmpty) {
      throw Exception('Product name cannot be empty');
    }
    if (product.price <= 0) {
      throw Exception('Product price must be greater than 0');
    }
    if (product.stock < 0) {
      throw Exception('Product stock cannot be negative');
    }
    if (product.categoryId <= 0) {
      throw Exception('Valid category must be selected');
    }

    try {
      final token = await authService.getToken();

      if (imageFile != null) {
        // Use multipart upload
        MultipartFile multipartFile;
        if (imageFile.isWeb && imageFile.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            imageFile.bytes!,
            filename: imageFile.fileName ?? 'image.jpg',
          );
        } else if (!imageFile.isWeb && imageFile.file != null) {
          multipartFile = await MultipartFile.fromFile(
            imageFile.file.path,
            filename: imageFile.fileName ?? 'image.jpg',
          );
        } else {
          throw Exception('Invalid image data');
        }

        FormData formData = FormData.fromMap({
          'name': product.name,
          'description': product.description,
          'price': product.price.toString(),
          'stock': product.stock.toString(),
          'category_id': product.categoryId.toString(),
          'image': multipartFile,
          '_method': 'PUT', // For Laravel PUT via POST
        });

        dio.options.headers['Authorization'] = 'Bearer $token';

        final response = await dio.post('$baseUrl/products/$id', data: formData);

        print('Update Product Response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = response.data;

          if (responseData['success'] == true) {
            return Product.fromJson(responseData['data']);
          } else {
            throw Exception('API Error: ${responseData['message']}');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Please login again');
        } else {
          throw Exception('Failed to update product: ${response.statusCode}');
        }
      } else {
        // Use JSON
        final headers = await _getHeaders();
        final response = await client.put(
          Uri.parse('$baseUrl/products/$id'),
          headers: headers,
          body: json.encode(product.toJson()),
        );

        print('Update Product Response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            return Product.fromJson(responseData['data']);
          } else {
            throw Exception('API Error: ${responseData['message']}');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Please login again');
        } else {
          throw Exception('Failed to update product: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in updateProduct: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.delete(Uri.parse('$baseUrl/products/$id'), headers: headers);

      print('Delete Product Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] != true) {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteProduct: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/recommendations/popular?limit=$limit'),
        headers: headers,
      );

      print('Popular Products Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        } else {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load popular products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPopularProducts: $e');
      throw Exception('Failed to load popular products: $e');
    }
  }

  Future<List<Product>> getPersonalizedRecommendations({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/recommendations/personalized?limit=$limit'),
        headers: headers,
      );

      print('Personalized Recommendations Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        } else {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load personalized recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPersonalizedRecommendations: $e');
      throw Exception('Failed to load personalized recommendations: $e');
    }
  }

  Future<List<Product>> getRecommendations({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/recommendations?limit=$limit'),
        headers: headers,
      );

      print('Recommendations Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        } else {
          throw Exception('API Error: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRecommendations: $e');
      throw Exception('Failed to load recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> checkout(List<Map<String, dynamic>> items, double total) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'items': items,
        'total': total,
      });

      final response = await client.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: body,
      );

      print('Checkout Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception('Checkout failed: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error in checkout: $e');
      throw Exception('Failed to checkout: $e');
    }
  }
}