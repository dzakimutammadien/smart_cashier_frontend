import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_frontend/providers/revenue_provider.dart';
import 'package:smart_cashier_frontend/services/analytics_service.dart';
import 'package:smart_cashier_frontend/services/export_service.dart';
import 'package:smart_cashier_frontend/pages/low_stock_products_page.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ExportService _exportService = ExportService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RevenueProvider>(context, listen: false).loadRevenueStats();
    });
  }

  Future<void> _loadData() async {
    print('DEBUG: Starting _loadData');
    setState(() => _isLoading = true);
    try {
      final result = await _analyticsService.getDashboardData();
      print('DEBUG: Dashboard API Response: $result');

      setState(() {
        _dashboardData = result['data'] ?? result;
        print('DEBUG: Parsed dashboardData: $_dashboardData');
        if (_dashboardData != null && _dashboardData!['today'] != null) {
          print('DEBUG: Today revenue: ${_dashboardData!['today']['revenue']}');
        }
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: ERROR in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadData();
                Provider.of<RevenueProvider>(context, listen: false).refresh();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsCards(),
                    const SizedBox(height: 24),
                    Consumer<RevenueProvider>(
                      builder: (context, revenueProvider, child) {
                        return Column(
                          children: [
                            _buildRevenueChart(revenueProvider),
                            const SizedBox(height: 24),
                            _buildPeriodSelector(revenueProvider),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTopProductsChart(),
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
          'Today\'s Avg Transaction',
          '\$${(double.tryParse('${_dashboardData!['today']['average_transaction_value'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.cyan,
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
          'This Week Avg Transaction',
          '\$${(double.tryParse('${_dashboardData!['this_week']['average_transaction_value'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.amber,
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
          'This Month Avg Transaction',
          '\$${(double.tryParse('${_dashboardData!['this_month']['average_transaction_value'] ?? 0}') ?? 0).toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.lightGreen,
        ),
        _buildMetricCard(
          'Total Products',
          '${_dashboardData!['inventory']['total_products'] ?? 0}',
          Icons.inventory,
          Colors.brown,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LowStockProductsPage()),
            );
          },
          child: _buildMetricCard(
            'Low Stock Alerts',
            '${_dashboardData!['inventory']['low_stock_products'] ?? 0}',
            Icons.warning,
            Colors.red,
          ),
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

  Widget _buildRevenueChart(RevenueProvider revenueProvider) {
    if (revenueProvider.isLoading) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final revenueStats = revenueProvider.revenueStats;
    if (revenueStats == null || revenueStats['chart_data'] == null) {
      return const SizedBox();
    }

    final chartData = revenueStats['chart_data'] as List;
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
                  '\$${(double.tryParse('${revenueStats['total_revenue'] ?? 0}') ?? 0).toStringAsFixed(2)} total',
                  style: const TextStyle(
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
                        color: Colors.blue.withValues(alpha: 0.1),
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

  Widget _buildPeriodSelector(RevenueProvider revenueProvider) {
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton('Day', 'day', revenueProvider),
                _buildPeriodButton('Week', 'week', revenueProvider),
                _buildPeriodButton('Month', 'month', revenueProvider),
                _buildPeriodButton('Year', 'year', revenueProvider),
              ],
            ),
            const SizedBox(height: 16),
            if (revenueProvider.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        revenueProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () => revenueProvider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportService.exportPDF(context),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportService.exportExcel(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (revenueProvider.revenueStats != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Revenue',
                    '\$${(double.tryParse('${revenueProvider.revenueStats!['total_revenue'] ?? 0}') ?? 0).toStringAsFixed(2)}',
                  ),
                  _buildStatItem(
                    'Total Orders',
                    '${revenueProvider.revenueStats!['total_orders'] ?? 0}',
                  ),
                  _buildStatItem(
                    'Change',
                    '${revenueProvider.revenueStats!['revenue_change_percent'] ?? 0}%',
                    color: (revenueProvider.revenueStats!['revenue_change_percent'] ?? 0) >= 0
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

  Widget _buildPeriodButton(String label, String period, RevenueProvider revenueProvider) {
    final isSelected = revenueProvider.selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => revenueProvider.setPeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
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