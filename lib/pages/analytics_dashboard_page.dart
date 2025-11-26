import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_frontend/providers/auth_provider.dart';
import 'package:smart_cashier_frontend/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueStats;
  Map<String, dynamic>? _productAnalytics;
  bool _isLoading = true;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _analyticsService.getDashboardData(),
        _analyticsService.getRevenueStatistics(period: _selectedPeriod),
        _analyticsService.getProductAnalytics(),
      ]);

      setState(() {
        _dashboardData = results[0]['data'];
        _revenueStats = results[1]['data'];
        _productAnalytics = results[2]['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<void> _exportReport(String type) async {
    try {
      await _analyticsService.exportSalesReport(type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.toUpperCase()} report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _exportReport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'daily', child: Text('Export Daily Report')),
              const PopupMenuItem(value: 'weekly', child: Text('Export Weekly Report')),
              const PopupMenuItem(value: 'monthly', child: Text('Export Monthly Report')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsCards(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    _buildTopProductsChart(),
                    const SizedBox(height: 24),
                    _buildPeriodSelector(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsCards() {
    if (_dashboardData == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Today\'s Revenue',
          '\$${(double.tryParse('${_dashboardData!['today']['revenue'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          'Today\'s Orders',
          '${_dashboardData!['today']['orders'] ?? 0}',
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildMetricCard(
          'This Week Revenue',
          '\$${(double.tryParse('${_dashboardData!['this_week']['revenue'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.calendar_view_week,
          Colors.orange,
        ),
        _buildMetricCard(
          'This Week Orders',
          '${_dashboardData!['this_week']['orders'] ?? 0}',
          Icons.calendar_today,
          Colors.purple,
        ),
        _buildMetricCard(
          'This Month Revenue',
          '\$${(double.tryParse('${_dashboardData!['this_month']['revenue'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.calendar_month,
          Colors.teal,
        ),
        _buildMetricCard(
          'This Month Orders',
          '${_dashboardData!['this_month']['orders'] ?? 0}',
          Icons.date_range,
          Colors.indigo,
        ),
        _buildMetricCard(
          'Total Products',
          '${_dashboardData!['inventory']['total_products'] ?? 0}',
          Icons.inventory,
          Colors.brown,
        ),
        _buildMetricCard(
          'Low Stock Items',
          '${_dashboardData!['inventory']['low_stock_products'] ?? 0}',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueStats == null || _revenueStats!['chart_data'] == null) {
      return const SizedBox();
    }

    final chartData = _revenueStats!['chart_data'] as List;
    if (chartData.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${(double.tryParse('${_revenueStats!['total_revenue'] ?? 0}') ?? 0).toStringAsFixed(2)} total',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                            final item = chartData[value.toInt()];
                            return Text(
                              item['date'] ?? item['week']?.toString() ?? value.toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        final item = entry.value;
                        return FlSpot(
                          entry.key.toDouble(),
                          (double.tryParse('${item['revenue'] ?? 0}') ?? 0),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    if (_dashboardData == null || _dashboardData!['top_products'] == null) {
      return const SizedBox();
    }

    final topProducts = _dashboardData!['top_products'] as List;
    if (topProducts.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Selling Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topProducts.isNotEmpty
                      ? (int.tryParse('${topProducts.first['total_sold'] ?? 0}') ?? 0).toDouble() * 1.2
                      : 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < topProducts.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                topProducts[value.toInt()]['product_name'].toString().substring(0, 8),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: topProducts.asMap().entries.map((entry) {
                    final product = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (int.tryParse('${product['total_sold'] ?? 0}') ?? 0).toDouble(),
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...topProducts.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product['product_name'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${product['total_sold']} sold',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Period: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Day')),
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
            if (_revenueStats != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Revenue',
                    '\$${(double.tryParse('${_revenueStats!['total_revenue'] ?? 0}') ?? 0).toStringAsFixed(2)}',
                  ),
                  _buildStatItem(
                    'Total Orders',
                    '${_revenueStats!['total_orders'] ?? 0}',
                  ),
                  _buildStatItem(
                    'Change',
                    '${_revenueStats!['revenue_change_percent'] ?? 0}%',
                    color: (_revenueStats!['revenue_change_percent'] ?? 0) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}