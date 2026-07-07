import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';

class TunnelMateApp extends StatelessWidget {
  const TunnelMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tianzhan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
