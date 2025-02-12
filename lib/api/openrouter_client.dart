// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
import '../utils/api_storage.dart';

// Класс клиента для работы с API OpenRouter
class OpenRouterClient {
  String? apiKey;
  String? baseUrl;
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Title': 'AI Chat Flutter',
  };

  // Конструктор
  OpenRouterClient() {
    _initialize();
  }

  Future<void> _initialize() async {
    apiKey = await ApiStorage.getApiKey();
    baseUrl = await ApiStorage.getBaseUrl() ?? 'https://openrouter.ai/api/v1';
    
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
  }

  // Метод проверки готовности клиента
  Future<bool> isReady() async {
    if (apiKey == null) {
      await _initialize();
    }
    return apiKey != null && apiKey!.isNotEmpty;
  }

  // Метод для обновления клиента после изменения настроек
  static Future<void> resetInstance() async {
    _instance = OpenRouterClient();
    await _instance._initialize();
  }

  // Приватный статический экземпляр
  static OpenRouterClient _instance = OpenRouterClient();

  // Фабричный метод
  factory OpenRouterClient.instance() {
    return _instance;
  }

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    if (!await isReady()) {
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
      ];
    }

    try {
      // Выполнение GET запроса для получения моделей
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': (() {
                      try {
                        return utf8.decode((model['name'] as String).codeUnits);
                      } catch (e) {
                        // Remove invalid UTF-8 characters and try again
                        final cleaned = (model['name'] as String)
                            .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                        return utf8.decode(cleaned.codeUnits);
                      }
                    })(),
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return [
          {'id': 'deepseek-coder', 'name': 'DeepSeek'},
          {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
          {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
      ];
    }
  }

  // Метод отправки сообщения через API
  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    if (!await isReady()) {
      return {'error': 'API key not configured. Please set up your API key in settings.'};
    }

    try {
      // Подготовка данных для отправки
      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': 1000, // Максимальное количество токенов
        'temperature': 0.7, // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса
  Future<String> getBalance() async {
    try {
      // Выполнение GET запроса для получения баланса
      final response = await http.get(
        Uri.parse(baseUrl?.contains('vsegpt.ru') == true
            ? '$baseUrl/balance'
            : '$baseUrl/credits'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (baseUrl?.contains('vsegpt.ru') == true) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return '${credits.toStringAsFixed(2)}₽'; // Расчет доступного баланса
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return '\$${(credits - usage).toStringAsFixed(2)}'; // Расчет доступного баланса
          }
        }
      }
      return baseUrl?.contains('vsegpt.ru') == true
          ? '0.00₽'
          : '\$0.00'; // Возвращение нулевого баланса по умолчанию
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return 'Error'; // Возвращение ошибки в случае исключения
    }
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      if (baseUrl?.contains('vsegpt.ru') == true) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}
