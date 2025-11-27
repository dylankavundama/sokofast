import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Screen/bottonNav.dart';
import 'package:soko/utils/responsive.dart';

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

    // Navigation directe vers l'écran principal sans exiger de compte
    // Les utilisateurs peuvent accéder librement et se connecter plus tard si nécessaire
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BottomNavExample()),
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
                  'From ',
                  style: GoogleFonts.abel(
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 22),
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Next Byte Technology',
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
