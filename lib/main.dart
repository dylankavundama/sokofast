import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Screen/splashScreen.dart';
import 'package:soko/onBoarding.dart';
import 'package:soko/style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Vérifie si l’onboarding a déjà été vu
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool seenOnboarding = prefs.getBool('onboarding_done') ?? false;

  runApp(MyApp(showOnboarding: !seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'soko',
      theme: ThemeData(
        primarySwatch: customYellowSwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: backdColor),
        ),
      ),
      // Si l’onboarding n’a pas encore été vu, on l’affiche en premier
      home: showOnboarding ? const OnboardingScreen() : const SplashScreen(),
    );
  }
}
