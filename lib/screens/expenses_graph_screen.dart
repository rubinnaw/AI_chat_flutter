import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';

class ExpensesGraphScreen extends StatefulWidget {
  const ExpensesGraphScreen({super.key});

  @override
  State<ExpensesGraphScreen> createState() => _ExpensesGraphScreenState();
}

class _ExpensesGraphScreenState extends State<ExpensesGraphScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  String _selectedPeriod = 'week';

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment<String>(
            value: 'week',
            label: Text('Неделя'),
          ),
          ButtonSegment<String>(
            value: 'month',
            label: Text('Месяц'),
          ),
          ButtonSegment<String>(
            value: 'year',
            label: Text('Год'),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedPeriod = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return const Color(0xFF262626);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesChart() {
    final statistics = _analyticsService.getStatistics();
    final modelUsage = statistics['model_usage'] as Map<String, Map<String, int>>? ?? {};
    
    // Расчет стоимости для каждой модели (примерные цены)
    final modelPrices = {
      'gpt-3.5-turbo': 0.002, // $0.002 за 1K токенов
      'gpt-4': 0.03, // $0.03 за 1K токенов
      'claude-2': 0.01, // $0.01 за 1K токенов
    };

    double totalCost = 0;
    final modelCosts = <String, double>{};

    modelUsage.forEach((model, stats) {
      final tokens = stats['tokens'] ?? 0;
      final pricePerToken = modelPrices[model] ?? 0.002;
      final cost = (tokens / 1000) * pricePerToken;
      modelCosts[model] = cost;
      totalCost += cost;
    });

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF262626),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Общие расходы',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: const Color(0xFF262626),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Расходы по моделям',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: modelCosts.isEmpty
                            ? const Center(
                                child: Text(
                                  'Нет данных о расходах',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: modelCosts.entries.map((entry) {
                                    final color = Colors.primaries[
                                        modelCosts.keys.toList().indexOf(entry.key) %
                                            Colors.primaries.length];
                                    return PieChartSectionData(
                                      color: color,
                                      value: entry.value,
                                      title:
                                          '${entry.key}\n\$${entry.value.toStringAsFixed(2)}',
                                      radius: 100,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 0,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расходы'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildPeriodSelector(),
          _buildExpensesChart(),
        ],
      ),
    );
  }
}
