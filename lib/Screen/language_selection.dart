import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/l10n/app_localizations.dart';

typedef LanguageSelectedCallback = void Function(Locale locale);

class LanguageSelectionScreen extends StatefulWidget {
  final LanguageSelectedCallback onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Locale? _selectedLocale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentLanguageCode = prefs.getString('language_code');
    if (currentLanguageCode != null) {
      setState(() {
        _selectedLocale = Locale(currentLanguageCode);
      });
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedLocale == null) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', _selectedLocale!.languageCode);

    widget.onLanguageSelected(_selectedLocale!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileChangeLanguage),
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
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedLocale == null || _saving
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


