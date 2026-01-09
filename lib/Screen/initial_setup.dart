import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/main.dart';

class InitialSetupScreen extends StatefulWidget {
  final Function(Locale locale, ThemeMode themeMode) onComplete;

  const InitialSetupScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int _currentStep = 0; // 0 = langue, 1 = thème
  Locale? _selectedLocale;
  ThemeMode? _selectedThemeMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger la langue actuelle si elle existe
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      setState(() {
        _selectedLocale = Locale(languageCode);
      });
    }
    
    // Charger le thème actuel si il existe
    final String? themeModeString = prefs.getString('theme_mode');
    if (themeModeString != null) {
      setState(() {
        switch (themeModeString) {
          case 'light':
            _selectedThemeMode = ThemeMode.light;
            break;
          case 'dark':
            _selectedThemeMode = ThemeMode.dark;
            break;
          case 'system':
            _selectedThemeMode = ThemeMode.system;
            break;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_currentStep == 0) {
      // Étape langue
      if (_selectedLocale == null) return;
      setState(() => _saving = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', _selectedLocale!.languageCode);
      
      setState(() {
        _saving = false;
        _currentStep = 1; // Passer à l'étape thème
      });
      
      // Mettre à jour la locale pour que les textes suivants soient traduits
      // On le fait après setState pour éviter les problèmes de contexte
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MyApp.of(context)?.setLocale(_selectedLocale!);
      });
    } else {
      // Étape thème - finaliser
      if (_selectedThemeMode == null) return;
      setState(() => _saving = true);
      
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;
      switch (_selectedThemeMode!) {
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
      
      // Appeler le callback de complétion
      widget.onComplete(_selectedLocale!, _selectedThemeMode!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicateur de progression
              Row(
                children: [
                  _buildProgressIndicator(0, loc.languageTitle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1 ? Theme.of(context).primaryColor : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildProgressIndicator(1, loc.themeTitle),
                ],
              ),
              const SizedBox(height: 40),
              
              // Contenu selon l'étape
              Expanded(
                child: _currentStep == 0 ? _buildLanguageStep(loc) : _buildThemeStep(loc),
              ),
              
              // Bouton de navigation
              ElevatedButton(
                onPressed: (_currentStep == 0 && _selectedLocale == null) ||
                        (_currentStep == 1 && _selectedThemeMode == null) ||
                        _saving
                    ? null
                    : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _currentStep == 0 ? loc.languageContinue : loc.languageContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive || isCompleted
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageStep(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.languageTitle,
          style: GoogleFonts.actor(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          loc.languageSubtitle,
          style: GoogleFonts.abel(
            fontSize: 16,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _LanguageTile(
          label: loc.languageFrench,
          locale: const Locale('fr'),
          isSelected: _selectedLocale?.languageCode == 'fr',
          onTap: () => setState(() {
            _selectedLocale = const Locale('fr');
          }),
        ),
        const SizedBox(height: 16),
        _LanguageTile(
          label: loc.languageEnglish,
          locale: const Locale('en'),
          isSelected: _selectedLocale?.languageCode == 'en',
          onTap: () => setState(() {
            _selectedLocale = const Locale('en');
          }),
        ),
      ],
    );
  }

  Widget _buildThemeStep(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.themeTitle,
          style: GoogleFonts.actor(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          loc.languageSubtitle,
          style: GoogleFonts.abel(
            fontSize: 16,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _ThemeTile(
          label: loc.themeLight,
          themeMode: ThemeMode.light,
          icon: Icons.light_mode,
          isSelected: _selectedThemeMode == ThemeMode.light,
          onTap: () => setState(() {
            _selectedThemeMode = ThemeMode.light;
          }),
        ),
        const SizedBox(height: 16),
        _ThemeTile(
          label: loc.themeDark,
          themeMode: ThemeMode.dark,
          icon: Icons.dark_mode,
          isSelected: _selectedThemeMode == ThemeMode.dark,
          onTap: () => setState(() {
            _selectedThemeMode = ThemeMode.dark;
          }),
        ),
        const SizedBox(height: 16),
        _ThemeTile(
          label: loc.themeSystem,
          themeMode: ThemeMode.system,
          icon: Icons.brightness_auto,
          isSelected: _selectedThemeMode == ThemeMode.system,
          onTap: () => setState(() {
            _selectedThemeMode = ThemeMode.system;
          }),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final ThemeMode themeMode;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.themeMode,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

