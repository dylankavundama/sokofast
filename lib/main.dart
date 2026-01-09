import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Screen/initial_setup.dart';
import 'package:soko/Screen/language_selection.dart';
import 'package:soko/Screen/splashScreen.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/onBoarding.dart';
import 'package:soko/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();

  // Onboarding
  final bool seenOnboarding = prefs.getBool('onboarding_done') ?? false;

  // Langue
  final String? languageCode = prefs.getString('language_code');
  final bool hasLanguage = languageCode != null;
  final Locale? initialLocale =
      languageCode != null ? Locale(languageCode) : null;

  // Thème
  final String? themeModeString = prefs.getString('theme_mode');
  final bool hasTheme = themeModeString != null;
  ThemeMode initialThemeMode = ThemeMode.system;
  if (themeModeString != null) {
    switch (themeModeString) {
      case 'light':
        initialThemeMode = ThemeMode.light;
        break;
      case 'dark':
        initialThemeMode = ThemeMode.dark;
        break;
      case 'system':
        initialThemeMode = ThemeMode.system;
        break;
    }
  }

  // Vérifier si la configuration initiale est complète
  final bool needsInitialSetup = !hasLanguage || !hasTheme;

  runApp(
    MyApp(
      showOnboarding: !seenOnboarding,
      initialLocale: initialLocale,
      hasLanguageSelected: hasLanguage,
      initialThemeMode: initialThemeMode,
      needsInitialSetup: needsInitialSetup,
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  final Locale? initialLocale;
  final bool hasLanguageSelected;
  final ThemeMode initialThemeMode;
  final bool needsInitialSetup;

  // Permet d'accéder à l'état pour changer la langue depuis n'importe quel écran.
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  const MyApp({
    super.key,
    required this.showOnboarding,
    required this.initialLocale,
    required this.hasLanguageSelected,
    required this.initialThemeMode,
    required this.needsInitialSetup,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  late bool _hasLanguageSelected;
  late ThemeMode _themeMode;
  late bool _needsInitialSetup;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _hasLanguageSelected = widget.hasLanguageSelected;
    _themeMode = widget.initialThemeMode;
    _needsInitialSetup = widget.needsInitialSetup;
  }

  void _onInitialSetupComplete(Locale locale, ThemeMode themeMode) {
    setState(() {
      _locale = locale;
      _themeMode = themeMode;
      _hasLanguageSelected = true;
      _needsInitialSetup = false;
    });
  }

  void _onLanguageSelected(Locale locale) {
    setState(() {
      _locale = locale;
      _hasLanguageSelected = true;
    });
  }

  // Appelé depuis d'autres écrans (profil) pour changer la langue à chaud.
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
      _hasLanguageSelected = true;
    });
  }

  // Appelé depuis d'autres écrans (profil) pour changer le thème à chaud.
  void setThemeMode(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    // Sauvegarder la préférence
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await prefs.setString('theme_mode', themeModeString);
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_needsInitialSetup) {
      home = InitialSetupScreen(
        onComplete: _onInitialSetupComplete,
      );
    } else if (!_hasLanguageSelected) {
      home = LanguageSelectionScreen(onLanguageSelected: _onLanguageSelected);
    } else if (widget.showOnboarding) {
      home = const OnboardingScreen();
    } else {
      home = const SplashScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soko Fast',
      theme: ThemeData(
        primarySwatch: customYellowSwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: backdColor),
          backgroundColor: backdColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: customYellowSwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: backdColor),
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 2,
        ),
        dividerColor: Colors.grey[800],
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
      ),
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

