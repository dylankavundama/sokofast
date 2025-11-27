import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soko/livreur/order.dart';
import 'package:soko/services/user_service.dart';
// ⚠️ Assurez-vous que le chemin vers votre fichier de style est correct
import 'package:soko/style.dart';

class LoginLivre extends StatefulWidget {
  const LoginLivre({super.key});

  @override
  State<LoginLivre> createState() => _LoginLivreState();
}

class _LoginLivreState extends State<LoginLivre> {
  // Contrôleur pour lire le texte saisi dans le champ
  final TextEditingController _nameController = TextEditingController();

  // État pour afficher les messages d'erreur
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 💡 NOUVEAU : Vérification automatique et redirection immédiate
    // Plus besoin de formulaire, tout est géré automatiquement via l'email
    _checkLivreurAndNavigate();
  }

  // 💡 NOUVEAU : Vérifier si l'utilisateur connecté est livreur via son email
  Future<void> _checkLivreurAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // Si l'utilisateur n'est pas connecté, afficher un message
      if (mounted) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter avec votre compte Firebase d\'abord.';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 💡 Vérifier via l'email de l'utilisateur connecté
      final isLivreur = await UserService.isLivreurByEmail(user.email!);
      
      if (isLivreur && mounted) {
        // Si l'utilisateur est livreur, naviguer directement vers la page des commandes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersPage()),
        );
      } else if (mounted) {
        // Si l'utilisateur n'est pas livreur, afficher un message
        setState(() {
          _errorMessage = 'Vous n\'êtes pas autorisé à accéder à cette section. Seuls les livreurs peuvent accéder.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la vérification: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Plus besoin de _nameController, mais on le garde pour éviter les erreurs
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

              Text(
                'Vérification de votre statut de livreur...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),

              // 💡 NOUVEAU : Afficher l'email de l'utilisateur connecté
              if (FirebaseAuth.instance.currentUser != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.person, size: 48, color: backdColor),
                        const SizedBox(height: 8),
                        Text(
                          FirebaseAuth.instance.currentUser!.email ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 💡 NOUVEAU : Indicateur de chargement automatique
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              
              // 💡 NOUVEAU : Message informatif
              if (!_isLoading && _errorMessage == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vérification automatique en cours...',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
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
