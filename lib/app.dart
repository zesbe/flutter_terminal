import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/terminal/presentation/pages/terminal_page.dart';
import 'core/themes/terminal_themes.dart';

class FlutterTerminalApp extends ConsumerWidget {
  const FlutterTerminalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTerminalThemes.defaultTheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTerminalThemes.defaultTheme.background,
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppTerminalThemes.defaultTheme.cyan,
          secondary: AppTerminalThemes.defaultTheme.green,
          surface: AppTerminalThemes.defaultTheme.background,
        ),
      ),
      home: const TerminalPage(),
    );
  }
}
