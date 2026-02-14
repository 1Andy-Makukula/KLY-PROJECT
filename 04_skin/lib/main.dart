import 'package:flutter/material.dart';
import 'theme/alpha_theme.dart';
import 'playground.dart';

void main() {
  runApp(const KithLyApp());
}

class KithLyApp extends StatelessWidget {
  const KithLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KithLy Skin',
      theme: AlphaTheme.themeData,
      home: const Playground(),
      debugShowCheckedModeBanner: false,
    );
  }
}
