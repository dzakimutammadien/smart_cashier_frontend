import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_cashier_frontend/services/analytics_service.dart';

class RevenueProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _revenueStats;
  Map<String, dynamic>? _detailedChartData;
  bool _isLoading = false;
  bool _isLoadingDetailed = false;
  String _selectedPeriod = 'month';
  String? _errorMessage;

  Map<String, dynamic>? get revenueStats => _revenueStats;
  Map<String, dynamic>? get detailedChartData => _detailedChartData;
  bool get isLoading => _isLoading;
  bool get isLoadingDetailed => _isLoadingDetailed;
  String get selectedPeriod => _selectedPeriod;
  String? get errorMessage => _errorMessage;

  // Debug getters for easy UI access (values in dollars, not cents)
  double get totalRevenue => (double.tryParse('${_revenueStats?['total_revenue'] ?? 0}') ?? 0) / 100;
  int get totalOrders => int.tryParse('${_revenueStats?['total_orders'] ?? 0}') ?? 0;
  double get averageTransaction => totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

  Future<void> loadRevenueStats() async {
    print('DEBUG: Starting loadRevenueStats for period: $_selectedPeriod');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final url = 'http://127.0.0.1:8000/api/reports/revenue-statistics?period=$_selectedPeriod';

      print('=== API DEBUG ===');
      print('URL: $url');
      print('Headers: $headers');
      print('================');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('=== API DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('================');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('DEBUG: Decoded JSON result: $result');

        _revenueStats = result['data'] ?? result;
        print('DEBUG: Parsed revenueStats: $_revenueStats');

        if (_revenueStats != null && _revenueStats!['total_revenue'] != null) {
          print('DEBUG: Total revenue value: ${_revenueStats!['total_revenue']}');
        } else {
          print('DEBUG: WARNING - total_revenue is null or missing');
          _errorMessage = 'Revenue data is missing or invalid';
        }
      } else {
        throw Exception('Failed to load revenue data: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: ERROR in loadRevenueStats: $e');
      _revenueStats = null;
      _errorMessage = 'Failed to load revenue data: $e';
    } finally {
      _isLoading = false;
      print('DEBUG: Finished loadRevenueStats, notifying listeners');
      notifyListeners();
    }
  }

  void setPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
      loadRevenueStats();
    }
  }

  Future<void> loadDetailedChartData(String period) async {
    print('DEBUG: Starting loadDetailedChartData for period: $period');
    _isLoadingDetailed = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final url = 'http://127.0.0.1:8000/api/reports/revenue-statistics?period=$period&detailed=true';

      print('=== API DEBUG ===');
      print('URL: $url');
      print('Headers: $headers');
      print('================');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('=== API DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('================');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('DEBUG: Decoded JSON result: $result');

        _detailedChartData = result['data'] ?? result;
        print('DEBUG: Parsed detailedChartData: $_detailedChartData');
      } else {
        throw Exception('Failed to load detailed chart data: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: ERROR in loadDetailedChartData: $e');
      _detailedChartData = null;
      _errorMessage = 'Failed to load detailed chart data: $e';
    } finally {
      _isLoadingDetailed = false;
      print('DEBUG: Finished loadDetailedChartData, notifying listeners');
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    print('=== PROVIDER NOTIFY LISTENERS DEBUG ===');
    print('Current revenueStats: $_revenueStats');
    print('Total Revenue: $totalRevenue');
    print('Total Orders: $totalOrders');
    print('Average Transaction: $averageTransaction');
    print('=======================================');
    super.notifyListeners();
  }

  void refresh() {
    loadRevenueStats();
  }
}