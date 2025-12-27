import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/l10n/app_localizations.dart';

typedef ThemeSelectedCallback = void Function(ThemeMode themeMode);

class ThemeSelectionScreen extends StatefulWidget {
  final ThemeSelectedCallback onThemeSelected;

  const ThemeSelectionScreen({
    super.key,
    required this.onThemeSelected,
  });

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  ThemeMode? _selectedThemeMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
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
    } else {
      // Par défaut, utiliser le thème système
      setState(() {
        _selectedThemeMode = ThemeMode.system;
      });
    }
  }

  Future<void> _confirmSelection() async {
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

    widget.onThemeSelected(_selectedThemeMode!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.themeTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                loc.themeTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                loc.languageSubtitle,
                style: TextStyle(
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
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedThemeMode == null || _saving
                    ? null
                    : _confirmSelection,
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
                        loc.languageContinue,
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

