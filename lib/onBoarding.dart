import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/style.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Données adaptées à une application de vente de produits électroniques
  final List<Map<String, String>> onboardingData = const [
    {
      "title": "Bienvenue chez SOKO FAST",
      "description": "Découvrez notre vaste sélection de gadgets, ordinateurs et accessoires high-tech.",
      "image": "assets/a.jpg"
    },
    {
      "title": "Une Technologie à Portée de Main",
      "description": "Naviguez facilement et trouvez les appareils qui correspondent à votre style de vie en quelques clics.",
      "image": "assets/b.jpg"
    },
    {
      "title": "Livraison Rapide et Sécurisée",
      "description": "Recevez vos derniers produits technologiques directement chez vous, rapidement et en toute sécurité.",
      "image": "assets/c.jpg"
    }
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Correction : Utilisation de la même clé 'onboarding_done' que dans le fichier main.dart
    await prefs.setBool('onboarding_done', true); 
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>   LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView pour les images et les textes
          PageView.builder(
            controller: _controller,
            itemCount: onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) => OnboardingContent(
              title: onboardingData[index]["title"]!,
              description: onboardingData[index]["description"]!,
              image: onboardingData[index]["image"]!,
            ),
          ),

          // Contenu de la superposition (bouton et indicateurs)
          SafeArea(
            child: Column(
              children: [
                // Bouton "Sauter"
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        "Sauter",
                        style: TextStyle(
                          color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.all(130.0),
                    child: Image.asset('assets/logo.png', height: 100),
                  ),
                const Spacer(), // Prend l'espace disponible
              
                // Indicateurs de page et boutons de navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    children: [
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingData.length,
                          (index) => buildDot(index, context),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 250,
                        height: 50,
                        child: _currentPage == onboardingData.length - 1
                            ? ElevatedButton(
                                onPressed: _skipOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Commencer",
                                  style: TextStyle(fontSize: 15, color: Colors.white),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Suivant",
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                      ),
                      
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  AnimatedContainer buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryYellow : Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  final String title;
  final String description;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image en arrière-plan qui prend tout l'écran
        Image.asset(
          image,
          fit: BoxFit.cover,
        ),

        // Dégradé pour améliorer le contraste du texte
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black54,
              ],
            ),
          ),
        ),

        // Le texte est positionné en bas de l'écran
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 150), // Espace pour les boutons de navigation en bas
              ],
            ),
          ),
        ),
      ],
    );
  }
}
