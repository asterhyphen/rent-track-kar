import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home.dart';
import 'screens/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('app');
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkBase = ThemeData(
      useMaterial3: true,
      fontFamily: 'Avenir',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B894),
        brightness: Brightness.dark,
      ),
    );

    final lightBase = ThemeData(
      useMaterial3: true,
      fontFamily: 'Avenir',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B894),
        brightness: Brightness.light,
      ),
    );

    final box = Hive.box('app');

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: const ['settings']),
      builder: (context, value, child) {
        final settings = AppSettings.fromMap(box.get('settings'));
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: settings.materialThemeMode,
          theme: lightBase.copyWith(
            scaffoldBackgroundColor: const Color(0xFFF4F8FB),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF00A885), width: 1.2),
              ),
            ),
          ),
          darkTheme: darkBase.copyWith(
            scaffoldBackgroundColor: const Color(0xFF090F1B),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF00E0B2), width: 1.2),
              ),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
