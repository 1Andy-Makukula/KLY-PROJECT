/// =============================================================================
/// KithLy Global Protocol - APPLICATION ENTRY POINT
/// main.dart - MultiProvider + MaterialApp Setup
/// =============================================================================
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/alpha_theme.dart';
import 'state_machine/dashboard_provider.dart';
import 'state_machine/product_provider.dart';
import 'state_machine/gift_provider.dart';
import 'screens/shop_portal/shop_portal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KithLyApp());
}

/// Root application widget
class KithLyApp extends StatelessWidget {
  const KithLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => GiftProvider()),
      ],
      child: MaterialApp(
        title: 'KithLy Protocol',
        debugShowCheckedModeBanner: false,
        theme: AlphaTheme.themeData,
        home: const ShopPortal(
          shopId: 'shop-1',
          shopName: 'Shoprite Manda Hill',
        ),
      ),
    );
  }
}
