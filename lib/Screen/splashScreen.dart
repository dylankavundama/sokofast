import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Screen/bottonNav.dart';
import 'package:soko/Auth/loginPage.dart';

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
      builder: (_) => AlertDialog(
        title: const Text("Créer un compte"),
        content: const Text("Souhaitez-vous créer un compte pour passer des commandes ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor:   Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 300),
            child: Column(
              children: [
                // const Center(
                //   child: Text(
                //     'BIENVENU SUR soko',
                //     style: TextStyle(
                //         fontSize: 18,
                //         color: Colors.white,
                //         fontWeight: FontWeight.bold),
                //   ),
                // ),
                Center(
                  child: Image.asset(height: 150,width: 300, 'assets/icon.png'),
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
                  'From ',
                  style: GoogleFonts.abel(fontSize: 18, color: Colors.black),
                ),
                Text(
                  'Next Byte Technology',
                  style: GoogleFonts.abel(
                    fontSize: 18,
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
