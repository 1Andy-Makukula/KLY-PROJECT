import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';

class FeedFilters extends StatefulWidget {
  const FeedFilters({super.key});

  @override
  State<FeedFilters> createState() => _FeedFiltersState();
}

class _FeedFiltersState extends State<FeedFilters> {
  int _selectedIndex = 0;
  final List<String> _categories = [
    "All",
    "Groceries",
    "Gifts",
    "Student Support",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: KithLyColors.darkBackground.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: isSelected
                    ? const Border(
                        bottom: BorderSide(
                          color: KithLyColors.orange,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Text(
                _categories[index],
                style: isSelected
                    ? AlphaTheme.labelLarge.copyWith(color: KithLyColors.orange)
                    : AlphaTheme.bodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}
