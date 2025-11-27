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

  String _formatCurrency(double amount) {
    // Convert from cents to dollars and format with $ and 2 decimals
    return '\$${(amount / 100).toStringAsFixed(2)}';
  }

  double _calculateAverageTransaction(double revenue, int orders) {
    if (orders == 0) return 0.0;
    // Calculate average and convert from cents to dollars
    return (revenue / orders) / 100;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RevenueProvider>(context, listen: false).loadRevenueStats();
    });
  }

  Future<void> _loadData() async {
    // Debug logs for development - comment out for production
    // print('DEBUG: Starting _loadData');
    setState(() => _isLoading = true);
    try {
      // print('=== DASHBOARD API DEBUG ===');
      // print('Calling getDashboardData...');

      final result = await _analyticsService.getDashboardData();
      // print('DEBUG: Dashboard API Response: $result');

      setState(() {
        _dashboardData = result['data'] ?? result;
        // print('DEBUG: Parsed dashboardData: $_dashboardData');
        // if (_dashboardData != null) {
        //   print('DEBUG: Today data: ${_dashboardData!['today']}');
        //   print('DEBUG: This week data: ${_dashboardData!['this_week']}');
        //   print('DEBUG: This month data: ${_dashboardData!['this_month']}');
        //   if (_dashboardData!['today'] != null) {
        //     print('DEBUG: Today revenue: ${_dashboardData!['today']['revenue']}');
        //     print('DEBUG: Today orders: ${_dashboardData!['today']['orders']}');
        //   }
        // }
        _isLoading = false;
      });
    } catch (e) {
      // Keep error logging for production debugging
      print('ERROR in _loadData: $e');
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
                        // Debug logs for development - comment out for production
                        print('=== UI CONSUMER BUILD DEBUG ===');
                        print('RevenueProvider instance: $revenueProvider');
                        print('Revenue stats: ${revenueProvider.revenueStats}');
                        print('Total Revenue: ${revenueProvider.totalRevenue}');
                        print('Total Orders: ${revenueProvider.totalOrders}');
                        print('Average Transaction: ${revenueProvider.averageTransaction}');
                        print('Is Loading: ${revenueProvider.isLoading}');
                        print('================================');

                        return Column(
                          children: [
                            // Debug text to verify data access - comment out for production
                            // Container(
                            //   padding: const EdgeInsets.all(8),
                            //   color: Colors.yellow.shade100,
                            //   child: Text(
                            //     'DEBUG: Total Revenue: ${_formatCurrency(revenueProvider.totalRevenue * 100)}, Orders: ${revenueProvider.totalOrders}, Avg: ${_formatCurrency(revenueProvider.averageTransaction * 100)}',
                            //     style: const TextStyle(fontSize: 12),
                            //   ),
                            // ),
                            const SizedBox(height: 16),
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
          _formatCurrency((double.tryParse('${_dashboardData!['today']['revenue'] ?? 0}') ?? 0)),
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
          (() {
            double revenue = double.tryParse('${_dashboardData!['today']['revenue'] ?? 0}') ?? 0;
            int orders = _dashboardData!['today']['orders'] ?? 0;
            double avg = _calculateAverageTransaction(revenue, orders);
            return _formatCurrency(avg * 100); // Convert back to cents for formatting
          })(),
          Icons.trending_up,
          Colors.cyan,
          onTap: () => _showDetailedChart(context, 'day'),
        ),
        _buildMetricCard(
          'This Week Revenue',
          _formatCurrency((double.tryParse('${_dashboardData!['this_week']['revenue'] ?? 0}') ?? 0)),
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
          (() {
            double revenue = double.tryParse('${_dashboardData!['this_week']['revenue'] ?? 0}') ?? 0;
            int orders = _dashboardData!['this_week']['orders'] ?? 0;
            double avg = _calculateAverageTransaction(revenue, orders);
            return _formatCurrency(avg * 100); // Convert back to cents for formatting
          })(),
          Icons.trending_up,
          Colors.amber,
          onTap: () => _showDetailedChart(context, 'week'),
        ),
        _buildMetricCard(
          'This Month Revenue',
          _formatCurrency((double.tryParse('${_dashboardData!['this_month']['revenue'] ?? 0}') ?? 0)),
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
          (() {
            double revenue = double.tryParse('${_dashboardData!['this_month']['revenue'] ?? 0}') ?? 0;
            int orders = _dashboardData!['this_month']['orders'] ?? 0;
            double avg = _calculateAverageTransaction(revenue, orders);
            return _formatCurrency(avg * 100); // Convert back to cents for formatting
          })(),
          Icons.trending_up,
          Colors.lightGreen,
          onTap: () => _showDetailedChart(context, 'month'),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    Widget card = Card(
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  Widget _buildRevenueChart(RevenueProvider revenueProvider) {
    // Debug logs for development - comment out for production
    print('=== BUILD REVENUE CHART DEBUG ===');
    print('Is Loading: ${revenueProvider.isLoading}');
    print('Revenue Stats: ${revenueProvider.revenueStats}');
    print('Revenue Stats == null: ${revenueProvider.revenueStats == null}');
    print('Total Revenue: ${revenueProvider.totalRevenue}');
    print('==================================');

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
    final hasRevenueData = revenueProvider.totalRevenue > 0;

    // Only show "No data available" if we're not loading and have no revenue data
    if (!revenueProvider.isLoading && !hasRevenueData) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No revenue data available')),
        ),
      );
    }

    // If we have revenue data or are still loading, show the chart area
    // (revenueStats might be null during loading, but we have data via getters)

    final chartData = revenueStats?['chart_data'] as List?;
    if (chartData == null || chartData.isEmpty) {
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
                    '${_formatCurrency(revenueProvider.totalRevenue)} total',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No chart data available',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Chart data will appear when transactions are recorded',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  '${_formatCurrency(revenueProvider.totalRevenue)} total',
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
                              '${item['date'] ?? item['week']?.toString() ?? value.toString()}',
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
                          (double.tryParse('${item['revenue'] ?? 0}') ?? 0) / 100, // Convert cents to dollars
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
            if (revenueProvider.totalRevenue > 0) ...[
              const SizedBox(height: 16),
              // Debug container for development - comment out for production
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   color: Colors.blue.shade100,
              //   child: Text(
              //     'DEBUG: Raw revenue stats: ${revenueProvider.revenueStats}',
              //     style: const TextStyle(fontSize: 10),
              //   ),
              // ),
              // const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Revenue',
                    _formatCurrency(revenueProvider.totalRevenue),
                  ),
                  _buildStatItem(
                    'Total Orders',
                    '${revenueProvider.totalOrders}',
                  ),
                  _buildStatItem(
                    'Average Transaction',
                    _formatCurrency(revenueProvider.averageTransaction),
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

  void _showDetailedChart(BuildContext context, String period) {
    final revenueProvider = Provider.of<RevenueProvider>(context, listen: false);
    revenueProvider.loadDetailedChartData(period);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Detailed Revenue Chart - ${period.toUpperCase()}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<RevenueProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingDetailed) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = provider.detailedChartData;
                    if (data == null || data['chart_data'] == null) {
                      return const Center(child: Text('No data available'));
                    }

                    final chartData = data['chart_data'] as List;
                    if (chartData.isEmpty) {
                      return const Center(child: Text('No chart data'));
                    }

                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 300,
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
                                        (double.tryParse('${item['revenue'] ?? 0}') ?? 0) / 100, // Convert cents to dollars
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
                          const SizedBox(height: 16),
                          Text(
                            'Revenue Trends for ${period.toUpperCase()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Revenue: ${_formatCurrency((double.tryParse('${data['total_revenue'] ?? 0}') ?? 0))}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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