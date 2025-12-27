import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Screen/bottonNav.dart';
<<<<<<< Updated upstream
import 'package:soko/utils/responsive.dart';
=======
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/l10n/app_localizations.dart';
>>>>>>> Stashed changes

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Attente de 3 secondes pour l'effet d'écran de démarrage
    await Future.delayed(const Duration(seconds: 3));

<<<<<<< Updated upstream
    // Navigation directe vers l'écran principal sans exiger de compte
    // Les utilisateurs peuvent accéder librement et se connecter plus tard si nécessaire
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BottomNavExample()),
=======
    // Vérifie l'état d'authentification de l'utilisateur avec Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Si un utilisateur est connecté (session persistante), naviguer directement
      // vers l'écran principal sans afficher le dialogue.
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavExample()),
      );
    } else {
      // Si aucun utilisateur n'est connecté, afficher le dialogue de création de compte.
      final bool createAccount = await _showCreateAccountDialog() ?? false;

      if (createAccount) {
        // Rediriger vers la page de connexion
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        // L'utilisateur a refusé, naviguer vers l'écran principal en tant qu'invité
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomNavExample()),
        );
      }
    }
  }

  Future<bool?> _showCreateAccountDialog() async {
    // Affiche un dialogue demandant à l'utilisateur s'il souhaite créer un compte.
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Empêche le dialogue de se fermer en cliquant à l'extérieur
      builder: (_) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.splashCreateAccountTitle),
          content: Text(loc.splashCreateAccountContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.splashNo),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.splashYes),
            ),
          ],
        );
      },
>>>>>>> Stashed changes
    );
  }

  @override
  Widget build(BuildContext context) {
      final loc = AppLocalizations.of(context);
      return Scaffold(
      backgroundColor:   Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Responsive.isMobile(context) ? 300.0 : 200.0),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    'assets/icon.png',
                    height: Responsive.isMobile(context) ? 150.0 : 200.0,
                    width: Responsive.isMobile(context) ? 300.0 : 400.0,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
<<<<<<< Updated upstream
                  'From ',
                  style: GoogleFonts.abel(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 22),
                    color: Colors.black,
                  ),
=======
                  loc.splashFrom,
                  style: GoogleFonts.abel(fontSize: 18, color: Colors.black),
>>>>>>> Stashed changes
                ),
                Text(
                  ' ${loc.splashCompany}',
                  style: GoogleFonts.abel(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 22),
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
