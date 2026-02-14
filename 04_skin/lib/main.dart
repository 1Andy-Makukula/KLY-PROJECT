import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/alpha_theme.dart';
import 'screens/shop/dashboard.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/customer/sender_catalog.dart';

void main() {
  // 1. Set Status Bar to Transparent so Glass flows to the top edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons for dark theme
    ),
  );

  runApp(const KithLyApp());
}

class KithLyApp extends StatelessWidget {
  const KithLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KithLy Project Alpha',
      debugShowCheckedModeBanner: false,

      // 2. Inject the Alpha Theme
      theme: AlphaTheme.themeData, // Using the centralized theme data
      // 3. Routing Table (Role-Based Logic)
      initialRoute: '/shop', // Default to Shop Dashboard
      routes: {
        '/shop': (context) => const ShopDashboard(),
        '/customer': (context) => const CustomerDashboard(),
        '/catalog': (context) => const SenderCatalog(),
      },
    );
  }
}
