import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    final headers = await _getHeaders();
    final url = '$baseUrl/reports/dashboard';

    print('=== DASHBOARD SERVICE DEBUG ===');
    print('URL: $url');
    print('Headers: $headers');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('================================');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print('Decoded dashboard data: $decoded');
      return decoded;
    } else {
      throw Exception('Failed to load dashboard data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getDailySales({String? date}) async {
    final headers = await _getHeaders();
    final queryParams = date != null ? '?date=$date' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/reports/daily-sales$queryParams'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load daily sales');
    }
  }

  Future<Map<String, dynamic>> getWeeklySales({String? startDate, String? endDate}) async {
    final headers = await _getHeaders();
    final queryParams = [];
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response = await http.get(
      Uri.parse('$baseUrl/reports/weekly-sales$queryString'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weekly sales');
    }
  }

  Future<Map<String, dynamic>> getMonthlySales({int? month, int? year}) async {
    final headers = await _getHeaders();
    final queryParams = [];
    if (month != null) queryParams.add('month=$month');
    if (year != null) queryParams.add('year=$year');
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response = await http.get(
      Uri.parse('$baseUrl/reports/monthly-sales$queryString'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load monthly sales');
    }
  }

  Future<Map<String, dynamic>> getProductAnalytics({int limit = 20}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/product-analytics?limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product analytics');
    }
  }

  Future<Map<String, dynamic>> getRevenueStatistics({String period = 'month'}) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/reports/revenue-statistics?period=$period';

    print('=== REVENUE STATS SERVICE DEBUG ===');
    print('URL: $url');
    print('Period: $period');
    print('Headers: $headers');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('====================================');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print('Decoded revenue statistics: $decoded');
      return decoded;
    } else {
      throw Exception('Failed to load revenue statistics: ${response.statusCode}');
    }
  }

  Future<void> exportSalesReport(String type, {String? date, String? startDate, String? endDate, int? month, int? year}) async {
    final headers = await _getHeaders();
    final queryParams = ['type=$type'];
    if (date != null) queryParams.add('date=$date');
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    if (month != null) queryParams.add('month=$month');
    if (year != null) queryParams.add('year=$year');

    final queryString = queryParams.join('&');
    final url = '$baseUrl/reports/export/sales?$queryString';

    // For PDF export, we'll open the URL in browser
    // In a real app, you might want to download and save the file
    // For now, we'll just make the request
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export sales report');
    }
  }

  Future<void> exportProductAnalytics() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/export/product-analytics'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export product analytics');
    }
  }

  Future<void> exportOrders({String? startDate, String? endDate}) async {
    final headers = await _getHeaders();
    final queryParams = [];
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response = await http.get(
      Uri.parse('$baseUrl/reports/export/orders$queryString'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export orders');
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/low-stock-products'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else {
      throw Exception('Failed to load low stock products');
    }
  }

  Future<void> exportLowStockProducts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/export/low-stock-products'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export low stock products');
    }
  }
}