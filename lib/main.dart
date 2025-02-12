import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/chat_provider.dart';
import 'screens/api_key_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/expenses_graph_screen.dart';
import 'utils/api_storage.dart';

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;
  const ErrorBoundaryWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          debugPrint('Error in ErrorBoundaryWidget: $error');
          debugPrint('Stack trace: $stackTrace');
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    // Проверяем наличие API ключа и устанавливаем флаг первого запуска
    final prefs = await SharedPreferences.getInstance();
    final apiKey = await ApiStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Warning: API key is not set');
      await prefs.setBool('is_first_launch', true);
    }
    
    final baseUrl = await ApiStorage.getBaseUrl();
    debugPrint('App initialized with:');
    debugPrint('BASE_URL: $baseUrl');
    debugPrint('API Key present: ${apiKey != null && apiKey.isNotEmpty}');

    runApp(const ErrorBoundaryWidget(child: MyApp()));
  } catch (e, stackTrace) {
    debugPrint('Error starting app: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Основной виджет приложения
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const SettingsScreen(),
    const StatisticsScreen(),
    const ExpensesGraphScreen(),
  ];

  Future<bool> _checkFirstLaunch() async {
    final apiKey = await ApiStorage.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_first_launch') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        try {
          return ChatProvider();
        } catch (e, stackTrace) {
          debugPrint('Error creating ChatProvider: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      },
      child: MaterialApp(
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollBehavior(),
            child: child!,
          );
        },
        home: HomeWrapper(key: ValueKey(DateTime.now().toString())),
        title: 'AI Chat',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF262626),
            foregroundColor: Colors.white,
          ),
          dialogTheme: const DialogTheme(
            backgroundColor: Color(0xFF333333),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
            contentTextStyle: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Roboto',
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  StreamSubscription? _apiKeySubscription;
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const ChatScreen(),
    const SettingsScreen(),
    const StatisticsScreen(),
    const ExpensesGraphScreen(),
  ];

  Future<bool> _checkFirstLaunch() async {
    final apiKey = await ApiStorage.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_first_launch') ?? true;
  }

  @override
  void initState() {
    super.initState();
    _apiKeySubscription = ApiStorage.apiKeyStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _apiKeySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFirstLaunch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final isFirstLaunch = snapshot.data ?? true;
        return isFirstLaunch 
          ? const ApiKeyScreen() 
          : _buildMainScaffold();
      },
    );
  }

  Widget _buildMainScaffold() {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        backgroundColor: const Color(0xFF262626),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat, color: Colors.white),
            label: 'Чат',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: Colors.white),
            label: 'Настройки',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics, color: Colors.white),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart, color: Colors.white),
            label: 'Расходы',
          ),
        ],
      ),
    );
  }
}
