import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  final http.Client client;
  final AuthService authService;

  ApiService({http.Client? client, AuthService? authService})
      : client = client ?? http.Client(),
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

  Future<Product> createProduct(Product product) async {
    try {
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
    } catch (e) {
      print('Error in createProduct: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(int id, Product product) async {
    try {
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
}