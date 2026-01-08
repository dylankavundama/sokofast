import 'package:flutter/material.dart';
import 'package:soko/admin/order.dart';
// ⚠️ Assurez-vous que le chemin vers votre OrdersPage est correct

// ⚠️ Assurez-vous que le chemin vers votre fichier de style est correct
import 'package:soko/style.dart';
import 'package:soko/l10n/app_localizations.dart';

class LoginLivre extends StatefulWidget {
  const LoginLivre({super.key});

  @override
  State<LoginLivre> createState() => _LoginLivreState();
}

class _LoginLivreState extends State<LoginLivre> {
  // 1. Liste des Identifiants autorisés (Les "administrateurs")
  final List<String> _authorizedUsers = ['Chris', 'Jacques', 'Sam'];

  // Contrôleur pour lire le texte saisi dans le champ
  final TextEditingController _nameController = TextEditingController();

  // État pour afficher les messages d'erreur
  String? _errorMessage;

  // 2. Logique de vérification
  void _attemptLogin() {
    final loc = AppLocalizations.of(context);
    final enteredName = _nameController.text.trim();

    // Convertir le Identifiant saisi et les Identifiants autorisés en minuscule pour une vérification insensible à la casse
    if (_authorizedUsers
        .map((n) => n.toLowerCase())
        .contains(enteredName.toLowerCase())) {
      // Succès : Passer à la page des commandes
      setState(() {
        _errorMessage = null;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrdersPage()),
      );
    } else {
      // Échec : Afficher le message d'erreur
      setState(() {
        _errorMessage = loc.adminLoginError;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 3. Interface Utilisateur (UI)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                  'assets/liv.png'),
              const SizedBox(height: 30),

              Builder(
                builder: (context) {
                  final loc = AppLocalizations.of(context);
                  return Column(
                    children: [
                      Text(
                        loc.adminLoginInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 30),

                      // Champ de saisie du Identifiant
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.adminLoginIdLabel,
                          hintText: loc.adminLoginIdHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                          errorText:
                              _errorMessage, // Affichage dynamique du message d'erreur
                        ),
                        onSubmitted: (_) =>
                            _attemptLogin(), // Permet de se connecter en appuyant sur Entrée
                      ),
                      const SizedBox(height: 20),

                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _attemptLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryYellow,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            loc.adminLoginAccess,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
