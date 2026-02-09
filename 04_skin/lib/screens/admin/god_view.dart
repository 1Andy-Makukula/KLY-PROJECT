/// =============================================================================
/// KithLy Global Protocol - GOD VIEW (Phase IV-Extension)
/// god_view.dart - Admin "God Mode" Dashboard
/// =============================================================================
/// 
/// Admin dashboard with:
/// - Approval Queue for pending shops
/// - Flight Map showing active riders
library;

import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import 'approval_queue.dart';
import 'flight_map.dart';

/// God Mode Admin Dashboard
class GodView extends StatefulWidget {
  const GodView({super.key});
  
  @override
  State<GodView> createState() => _GodViewState();
}

class _GodViewState extends State<GodView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AlphaTheme.accentBlue.withOpacity(0.3),
                    AlphaTheme.accentGreen.withOpacity(0.3),
                  ],
                ),
                borderRadius: AlphaTheme.chipRadius,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOD MODE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 10,
                    color: AlphaTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AlphaTheme.backgroundCard,
              borderRadius: AlphaTheme.buttonRadius,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AlphaTheme.accentGradient,
                borderRadius: AlphaTheme.buttonRadius,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AlphaTheme.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.approval, size: 18),
                      SizedBox(width: 8),
                      Text('Approvals'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight, size: 18),
                      SizedBox(width: 8),
                      Text('Flight Map'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ApprovalQueue(),
          FlightMap(),
        ],
      ),
    );
  }
}
