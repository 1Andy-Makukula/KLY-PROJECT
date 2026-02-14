import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';

class FeaturedShops extends StatelessWidget {
  const FeaturedShops({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://via.placeholder.com/100",
                        ), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Shop ${index + 1}",
                  style: AlphaTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Groceries",
                  style: AlphaTheme.bodyMedium.copyWith(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
