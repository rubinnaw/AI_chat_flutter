import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color(0xFF262626),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelUsageCard(Map<String, Map<String, int>> modelUsage) {
    return Card(
      color: const Color(0xFF262626),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'Использование моделей',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...modelUsage.entries.map((entry) {
              final modelName = entry.key;
              final stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Сообщений: ${stats['count']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Токенов: ${stats['tokens']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTimeCard(Map<String, dynamic> responseTimeStats) {
    return Card(
      color: const Color(0xFF262626),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timer, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'Время ответа (сек)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeMetric('Среднее', responseTimeStats['average']?.toStringAsFixed(2) ?? '0'),
                _buildTimeMetric('Медиана', responseTimeStats['median']?.toStringAsFixed(2) ?? '0'),
                _buildTimeMetric('Мин', responseTimeStats['min']?.toStringAsFixed(2) ?? '0'),
                _buildTimeMetric('Макс', responseTimeStats['max']?.toStringAsFixed(2) ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statistics = _analyticsService.getStatistics();
    final responseTimeStats = _analyticsService.getResponseTimeStats();
    final messageLengthStats = _analyticsService.getMessageLengthStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Всего сообщений',
                  '${statistics['total_messages']}',
                  Icons.message,
                ),
                _buildStatCard(
                  'Всего токенов',
                  '${statistics['total_tokens']}',
                  Icons.token,
                ),
                _buildStatCard(
                  'Сообщений в минуту',
                  '${statistics['messages_per_minute']?.toStringAsFixed(1)}',
                  Icons.speed,
                ),
                _buildStatCard(
                  'Токенов на сообщение',
                  '${statistics['tokens_per_message']?.toStringAsFixed(1)}',
                  Icons.analytics,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModelUsageCard(statistics['model_usage'] ?? {}),
            const SizedBox(height: 16),
            _buildResponseTimeCard(responseTimeStats),
          ],
        ),
      ),
    );
  }
}
