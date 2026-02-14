import 'package:flutter/material.dart';
import 'theme/alpha_theme.dart';
import 'widgets/alpha_buttons.dart'; // Import the new tools

class Playground extends StatelessWidget {
  const Playground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test 1: The Back Button
              Row(
                children: [
                  const AlphaBackButton(), // <--- Try clicking this!
                  const SizedBox(width: 20),
                  Text("Go Back", style: AlphaTheme.heading),
                ],
              ),

              const Spacer(),

              // Test 2: The Primary Button
              AlphaPrimaryButton(
                text: "CONFIRM GIFT",
                icon: const Icon(Icons.card_giftcard, color: Colors.white),
                onPressed: () {},
              ),

              const SizedBox(height: 20),

              // Test 3: The Secondary Button
              AlphaGlassButton(text: "CANCEL ORDER", onPressed: () {}),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
