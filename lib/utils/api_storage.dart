import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';


class ApiStorage {
  static final _apiKeyController = StreamController<String?>.broadcast();
  static Stream<String?> get apiKeyStream => _apiKeyController.stream;

  static const String _fileName = 'api_config.json';
  
  static Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  static Future<Map<String, dynamic>> getConfig() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return {
          'openrouter_base_url': 'https://openrouter.ai/api/v1',
          'openrouter_api_key': '',
        };
      }
      
      final contents = await file.readAsString();
      return json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading API config: $e');
      return {
        'openrouter_base_url': 'https://openrouter.ai/api/v1',
        'openrouter_api_key': '',
      };
    }
  }

  static Future<void> saveConfig(Map<String, dynamic> config) async {
    try {
      final file = File(await _filePath);
      await file.writeAsString(json.encode(config));
      debugPrint('API config saved successfully');
    } catch (e) {
      debugPrint('Error saving API config: $e');
      rethrow;
    }
  }

  static Future<String?> getApiKey() async {
    final config = await getConfig();
    return config['openrouter_api_key'] as String?;
  }

  static Future<String?> getBaseUrl() async {
    final config = await getConfig();
    return config['openrouter_base_url'] as String?;
  }

  static Future<void> saveApiKey(String apiKey) async {
    final config = await getConfig();
    config['openrouter_api_key'] = apiKey;
    await saveConfig(config);
    _apiKeyController.add(apiKey);
  }
}
