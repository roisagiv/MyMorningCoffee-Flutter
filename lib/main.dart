import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'ui/features/story_list/view_models/story_list_view_model.dart';
import 'ui/features/story_list/views/story_list_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final StoryListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StoryListViewModel(dio: Dio());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Custom Hacker News color scheme (Light)
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6600),
      primary: const Color(0xFFFF6600),
      surface: const Color(0xFFF6F6EF),
      onSurface: const Color(0xFF1A1A1A),
    );

    // Custom Hacker News color scheme (Dark)
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6600),
      brightness: Brightness.dark,
      primary: const Color(0xFFFF6600),
      surface: const Color(0xFF121212),
    );

    return MaterialApp(
      title: 'Hacker News Reader',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: StoryListView(viewModel: _viewModel),
    );
  }
}
