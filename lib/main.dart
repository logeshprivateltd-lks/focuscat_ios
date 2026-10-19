// lib/main.dart
// FocusCat v2.0 — Clean entry point.
// All logic lives in viewmodels/, services/, and views/.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/cat_viewmodel.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusCatApp());
}

class FocusCatApp extends StatelessWidget {
  const FocusCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatViewModel(),
      child: MaterialApp(
        title: 'FocusCat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF060809),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4ADE80),
            secondary: Color(0xFF22D3EE),
            surface: Color(0xFF0D1114),
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            fontFamilyFallback: const [
              'Apple Color Emoji',
              'Segoe UI Emoji',
              'Noto Color Emoji',
              'sans-serif',
            ],
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}