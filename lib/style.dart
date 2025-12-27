import 'package:flutter/material.dart';

// ignore: camel_case_types
class loading extends StatelessWidget {
  const loading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator())),
    );
  }
}

// Jaune/orangé principal du logo
const Color primaryYellow = Color(0xFFF2B316);

// Blanc utilisé pour la lettre "b"
const Color white = Color(0xFFFFFFFF);

// Noir de fond
const Color black = Color(0xFF000000);
const Color backdColor = primaryYellow;

Map<int, Color> primaryYellowShades = {
  50: Color(0xFFFFF8E1),
  100: Color(0xFFFFECB3),
  200: Color(0xFFFFE082),
  300: Color(0xFFFFD54F),
  400: Color(0xFFFFCA28),
  500: primaryYellow,
  600: Color(0xFFEDB30C),
  700: Color(0xFFE6A700),
  800: Color(0xFFD99900),
  900: Color(0xFFCC8B00),
};

MaterialColor customYellowSwatch =
    MaterialColor(primaryYellow.value, primaryYellowShades);