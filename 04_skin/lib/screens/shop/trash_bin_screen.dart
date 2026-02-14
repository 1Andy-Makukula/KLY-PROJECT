import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_card.dart';

class TrashBinScreen extends StatelessWidget {
  const TrashBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KithLyColors.darkBackground,
      appBar: AppBar(
        title: Text("Ghost Zone", style: AlphaTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: KithLyColors.orange),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Items in the Ghost Zone are permanently deleted after 30 days.",
                      style: AlphaTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildGhostItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          color: Colors.white10,
          child: const Icon(Icons.image_not_supported, color: Colors.white24),
        ),
        title: Text(
          "Deleted Item #${index + 1}",
          style: AlphaTheme.labelLarge.copyWith(
            decoration: TextDecoration.lineThrough,
            color: Colors.white54,
          ),
        ),
        subtitle: Text(
          "Deleted 2 days ago",
          style: AlphaTheme.bodyMedium.copyWith(
            fontSize: 12,
            color: Colors.white38,
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.restore, size: 16),
          label: const Text("Restore"),
          style: ElevatedButton.styleFrom(
            backgroundColor: KithLyColors.emerald.withOpacity(0.2),
            foregroundColor: KithLyColors.emerald,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
