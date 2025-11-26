import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000/api';
  final http.Client client;

  AuthService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      print('Register Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final user = User.fromJson(data['user']);
          final token = data['token'];

          // Save token and user data
          await _saveToken(token);
          await _saveUser(user);

          return {
            'success': true,
            'user': user,
            'token': token,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Registration failed',
          };
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': responseData['errors'],
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in register: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final user = User.fromJson(data['user']);
          final token = data['token'];

          // Save token and user data
          await _saveToken(token);
          await _saveUser(user);

          return {
            'success': true,
            'user': user,
            'token': token,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
          };
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Invalid credentials',
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in login: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found',
        };
      }

      final response = await client.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Logout Response: ${response.statusCode} - ${response.body}');

      // Clear local storage regardless of response
      await _clearToken();
      await _clearUser();

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Logged out successfully',
        };
      } else {
        return {
          'success': true, // Consider it successful since we cleared local data
          'message': 'Logged out locally',
        };
      }
    } catch (e) {
      print('Error in logout: $e');
      // Still clear local data
      await _clearToken();
      await _clearUser();
      return {
        'success': true,
        'message': 'Logged out locally due to error: $e',
      };
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}