import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../utils/api_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedProvider = 'OpenRouter';
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    // Загружаем API ключ в зависимости от выбранного провайдера
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    if (_selectedProvider == 'OpenRouter') {
      _apiKeyController.text = await ApiStorage.getApiKey() ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки API',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите провайдера:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProvider,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF333333),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'OpenRouter',
                        child: Text('OpenRouter'),
                      ),
                      DropdownMenuItem(
                        value: 'VSEGPT',
                        child: Text('VSEGPT'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProvider = value!;
                        _loadApiKey();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'API ключ:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFF333333),
                      hintText: 'Введите API ключ',
                      hintStyle: const TextStyle(color: Colors.white38),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureApiKey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  try {
                    // Сохраняем API ключ
                    if (_selectedProvider == 'OpenRouter') {
                      await ApiStorage.saveApiKey(_apiKeyController.text);
                    }
                    
                    // Получаем провайдер чата и реинициализируем его
                    final provider = Provider.of<ChatProvider>(context, listen: false);
                    await provider.reinitialize();
                    
                    // Показываем уведомление об успешном сохранении
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Настройки сохранены',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    // Показываем уведомление об ошибке
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ошибка сохранения настроек: $e',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Сохранить настройки',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
