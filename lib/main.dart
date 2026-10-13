import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/cycle_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cycle_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  // Set immersive status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => CycleProvider(),
      child: const FitCycleApp(),
    ),
  );
}

class FitCycleApp extends StatelessWidget {
  const FitCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '练啥',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF111827),
          surfaceContainerHighest: Color(0xFF1F2937),
          onPrimary: Colors.white,
          onSurface: Color(0xFFF3F4F6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090D16),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CycleProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF090D16),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (!provider.hasCycle) {
      // 没有任何默认计划，首次启动直接引导用户自定义训练循环
      return const CycleEditorScreen(isInitialSetup: true);
    }

    return const DashboardScreen();
  }
}
