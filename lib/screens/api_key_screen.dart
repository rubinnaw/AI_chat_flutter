import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_storage.dart';
import '../api/openrouter_client.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _error = 'API ключ не может быть пустым';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Сохраняем API ключ
      await ApiStorage.saveApiKey(_apiKeyController.text);

      // Сохраняем флаг первого запуска
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', false);

      if (mounted) {
        // Обновляем клиент OpenRouter с новым API ключом
        await OpenRouterClient.resetInstance();
        
        // Закрываем экран, HomeWrapper обновится автоматически через stream
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка при сохранении API ключа: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Добро пожаловать!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Для использования приложения необходимо ввести API ключ OpenRouter.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Ключ',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveApiKey,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Продолжить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
