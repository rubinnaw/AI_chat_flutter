import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Сервис для сбора и анализа статистики использования чата
class AnalyticsService {
  // Единственный экземпляр класса (Singleton)
  static final AnalyticsService _instance = AnalyticsService._internal();
  // Время начала сессии
  final DateTime _startTime;
  // Статистика использования моделей
  final Map<String, Map<String, int>> _modelUsage = {};
  // Данные о сообщениях в текущей сессии
  final List<Map<String, dynamic>> _sessionData = [];

  // Фабричный метод для получения экземпляра
  factory AnalyticsService() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  AnalyticsService._internal() : _startTime = DateTime.now() {
    // Инициализируем загрузку статистики
    Future(() async {
      await _loadStatistics();
    });
  }

  // Получение пути к файлу статистики
  Future<String> get _statisticsFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/analytics_statistics.json';
  }

  // Загрузка статистики из файла
  Future<void> _loadStatistics() async {
    try {
      final file = File(await _statisticsFilePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString);
        
        // Загрузка статистики по моделям
        if (data['model_usage'] != null) {
          final modelUsage = data['model_usage'] as Map<String, dynamic>;
          _modelUsage.clear();
          modelUsage.forEach((key, value) {
            _modelUsage[key] = Map<String, int>.from(value as Map);
          });
        }

        // Загрузка данных сессии
        if (data['session_data'] != null) {
          final sessionData = data['session_data'] as List;
          _sessionData.clear();
          _sessionData.addAll(sessionData.cast<Map<String, dynamic>>());
        }
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  // Сохранение статистики в файл
  Future<void> _saveStatistics() async {
    try {
      final file = File(await _statisticsFilePath);
      final data = {
        'model_usage': _modelUsage,
        'session_data': _sessionData,
        'last_updated': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving statistics: $e');
    }
  }

  // Метод для отслеживания отправленного сообщения
  Future<void> trackMessage({
    required String model, // Используемая модель
    required int messageLength, // Длина сообщения
    required double responseTime, // Время ответа
    required int tokensUsed, // Использовано токенов
  }) async {
    try {
      // Инициализация статистики для модели, если она еще не существует
      _modelUsage[model] ??= {
        'count': 0, // Счетчик сообщений
        'tokens': 0, // Счетчик токенов
      };

      // Обновление счетчиков использования модели
      _modelUsage[model]!['count'] = (_modelUsage[model]!['count'] ?? 0) + 1;
      _modelUsage[model]!['tokens'] =
          (_modelUsage[model]!['tokens'] ?? 0) + tokensUsed;

      // Сохранение детальной информации о сообщении
      _sessionData.add({
        'timestamp': DateTime.now().toIso8601String(),
        'model': model,
        'message_length': messageLength,
        'response_time': responseTime,
        'tokens_used': tokensUsed,
      });

      // Сохраняем статистику после каждого нового сообщения
      await _saveStatistics();
    } catch (e) {
      debugPrint('Error tracking message: $e');
    }
  }

  // Расчет стоимости для каждой модели
  final Map<String, double> _modelPrices = {
    'gpt-3.5-turbo': 0.002, // $0.002 за 1K токенов
    'gpt-4': 0.03, // $0.03 за 1K токенов
    'claude-2': 0.01, // $0.01 за 1K токенов
  };

  // Метод получения стоимости использования модели
  double _calculateModelCost(String model, int tokens) {
    final pricePerToken = _modelPrices[model] ?? 0.002;
    return (tokens / 1000) * pricePerToken;
  }

  // Метод получения общей статистики
  Map<String, dynamic> getStatistics() {
    try {
      final now = DateTime.now();
      final sessionDuration = now.difference(_startTime).inSeconds;

      // Подсчет общего количества сообщений и токенов
      int totalMessages = 0;
      int totalTokens = 0;

      for (final modelStats in _modelUsage.values) {
        totalMessages += modelStats['count'] ?? 0;
        totalTokens += modelStats['tokens'] ?? 0;
      }

      // Расчет средних показателей
      final messagesPerMinute =
          sessionDuration > 0 ? (totalMessages * 60) / sessionDuration : 0.0;

      final tokensPerMessage =
          totalMessages > 0 ? totalTokens / totalMessages : 0.0;

      // Расчет общей стоимости
      double totalCost = 0;
      for (final modelStats in _modelUsage.entries) {
        final tokens = modelStats.value['tokens'] ?? 0;
        totalCost += _calculateModelCost(modelStats.key, tokens);
      }

      return {
        'total_messages': totalMessages, // Общее количество сообщений
        'total_tokens': totalTokens, // Общее количество токенов
        'total_cost': totalCost, // Общая стоимость
        'session_duration': sessionDuration, // Длительность сессии в секундах
        'messages_per_minute': messagesPerMinute, // Сообщений в минуту
        'tokens_per_message': tokensPerMessage, // Среднее количество токенов на сообщение
        'model_usage': _modelUsage, // Статистика использования моделей
        'start_time': _startTime.toIso8601String(), // Время начала сессии
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  // Метод экспорта данных текущей сессии
  List<Map<String, dynamic>> exportSessionData() {
    return List.from(_sessionData);
  }

  // Метод получения расходов по дням
  Map<DateTime, double> getDailyExpenses() {
    final dailyExpenses = <DateTime, double>{};
    
    for (final data in _sessionData) {
      final timestamp = DateTime.parse(data['timestamp']);
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final model = data['model'] as String;
      final tokens = data['tokens_used'] as int;
      
      final cost = _calculateModelCost(model, tokens);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + cost;
    }
    
    return dailyExpenses;
  }

  // Метод получения расходов по моделям
  Map<String, double> getModelExpenses() {
    final modelExpenses = <String, double>{};
    
    for (final entry in _modelUsage.entries) {
      final model = entry.key;
      final tokens = entry.value['tokens'] ?? 0;
      modelExpenses[model] = _calculateModelCost(model, tokens);
    }
    
    return modelExpenses;
  }

  // Метод очистки всех данных
  Future<void> clearData() async {
    _modelUsage.clear();
    _sessionData.clear();
    await _saveStatistics();
  }

  // Метод анализа эффективности использования моделей
  Map<String, double> getModelEfficiency() {
    final efficiency = <String, double>{};

    for (final entry in _modelUsage.entries) {
      final modelId = entry.key;
      final stats = entry.value;
      final messageCount = stats['count'] ?? 0;
      final tokensUsed = stats['tokens'] ?? 0;

      // Рассчитываем эффективность как среднее количество токенов на сообщение
      if (messageCount > 0) {
        efficiency[modelId] = tokensUsed / messageCount;
      }
    }

    return efficiency;
  }

  // Метод получения статистики по времени ответа
  Map<String, dynamic> getResponseTimeStats() {
    if (_sessionData.isEmpty) return {};

    final responseTimes =
        _sessionData.map((data) => data['response_time'] as double).toList();

    responseTimes.sort();
    final count = responseTimes.length;

    return {
      'average':
          responseTimes.reduce((a, b) => a + b) / count, // Среднее время ответа
      'median': count.isOdd
          ? responseTimes[count ~/ 2] // Медиана для нечетного количества
          : (responseTimes[(count - 1) ~/ 2] + responseTimes[count ~/ 2]) /
              2, // Медиана для четного
      'min': responseTimes.first, // Минимальное время ответа
      'max': responseTimes.last, // Максимальное время ответа
    };
  }

  // Метод анализа статистики по длине сообщений
  Map<String, dynamic> getMessageLengthStats() {
    if (_sessionData.isEmpty) return {};

    final lengths =
        _sessionData.map((data) => data['message_length'] as int).toList();

    final count = lengths.length;
    final total = lengths.reduce((a, b) => a + b);

    return {
      'average_length': total / count, // Средняя длина сообщения
      'total_characters': total, // Общее количество символов
      'message_count': count, // Количество сообщений
    };
  }
}
