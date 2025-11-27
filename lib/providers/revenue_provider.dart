import 'package:flutter/material.dart';
import 'package:smart_cashier_frontend/services/analytics_service.dart';

class RevenueProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? _revenueStats;
  bool _isLoading = false;
  String _selectedPeriod = 'month';
  String? _errorMessage;

  Map<String, dynamic>? get revenueStats => _revenueStats;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;
  String? get errorMessage => _errorMessage;

  Future<void> loadRevenueStats() async {
    print('DEBUG: Starting loadRevenueStats for period: $_selectedPeriod');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = 'http://127.0.0.1:8000/api/reports/revenue-statistics?period=$_selectedPeriod';
      print('DEBUG: Calling API: $url');

      final result = await _analyticsService.getRevenueStatistics(period: _selectedPeriod);
      print('DEBUG: API Response received: $result');

      _revenueStats = result['data'] ?? result;
      print('DEBUG: Parsed revenueStats: $_revenueStats');

      if (_revenueStats != null && _revenueStats!['total_revenue'] != null) {
        print('DEBUG: Total revenue value: ${_revenueStats!['total_revenue']}');
      } else {
        print('DEBUG: WARNING - total_revenue is null or missing');
        _errorMessage = 'Revenue data is missing or invalid';
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

  void refresh() {
    loadRevenueStats();
  }
}