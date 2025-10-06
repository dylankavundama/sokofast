import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soko/Product/add.dart';
import 'package:soko/Profil/mes_produits.dart';
import 'package:soko/admin/order.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:soko/Auth/loginPage.dart';
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/Screen/CartScreen.dart';
import 'package:soko/style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // L'objet utilisateur de Firebase, qui est la source unique de vérité pour l'authentification.
  User? _user;
  String _username = "Chargement...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser(); // Charger le nom de l'utilisateur connecté
    // 1. On charge l'utilisateur actuel au démarrage.
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _loadUserData();
    } else {
      // Si l'utilisateur n'est pas connecté, on termine le chargement et on le gère.
      setState(() {
        _isLoading = false;
      });
      // La navigation est gérée par l'écouteur, mais cette vérification initiale est plus rapide.
    }

    _setupAuthStateListener();
  }

  // Écoute les changements d'état d'authentification de Firebase
  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      _user = user;
      _isLoading = false;

      if (_user != null) {
        // L'utilisateur est connecté, on charge ses données
        _loadUserData();
      } else {
        // 2. Si l'utilisateur est déconnecté, on le redirige explicitement.
        // pushAndRemoveUntil empêche le retour en arrière.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  // Charge les données du profil depuis Firestore
  Future<void> _loadUserData() async {
    if (_user == null) {
      setState(() {
        _username = 'Utilisateur'; // Nom par défaut
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _username = userDoc.get('username') ?? 'Utilisateur';
        });
      } else {
        // Si le document Firestore n'existe pas, on utilise le displayName de Firebase Auth
        setState(() {
          _username = _user!.displayName ?? 'Utilisateur';
        });
      }
    } catch (e) {
      print("Erreur de chargement des données utilisateur : $e");
      setState(() {
        _username = 'Erreur';
      });
    }
  }

  // Met à jour le nom de l'utilisateur dans Firebase et Firestore
  Future<void> _changeName() async {
    if (_user == null) return;
    TextEditingController controller = TextEditingController(text: _username);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le nom'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            child: const Text('Enregistrer'),
            onPressed: () async {
              try {
                // Met à jour le nom d'utilisateur dans Firebase Auth
                await _user!.updateDisplayName(controller.text);
                // Met à jour le nom d'utilisateur dans Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .set(
                        {'username': controller.text}, SetOptions(merge: true));
                setState(() {
                  _username = controller.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Nom d\'utilisateur mis à jour avec succès!')),
                );
              } catch (e) {
                print("Erreur de mise à jour du nom : $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Erreur: Impossible de mettre à jour le nom. $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Déconnecte l'utilisateur de Firebase
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // La navigation est gérée par l'écouteur, mais une redirection manuelle est plus fiable
    // pour garantir l'absence de retour.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _panier() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const CartScreen()));
  }

  Future<void> _historique() async {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
  }

  // Utilise launchUrl pour des raisons de modernité
  Future<void> _launchUrl(Uri url, String errorMessage) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  void _showCustomerServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Client'),
        content: const Text(
            'Comment souhaitez-vous contacter notre service client ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(
                Uri(
                    scheme: 'mailto',
                    path: 'support@soko.com',
                    queryParameters: {'subject': 'Demande de support'}),
                'Impossible d\'ouvrir l\'application email',
              );
            },
            child: const Text('Envoyer un email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(
                Uri(scheme: 'tel', path: '+1234567890'),
                'Impossible de passer un appel',
              );
            },
            child: const Text('Passer un appel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final whatsappUrl =
                  "https://wa.me/+1234567890?text=${Uri.encodeFull('Bonjour, j\'ai besoin d\'aide concernant...')}";
              _launchUrl(
                Uri.parse(whatsappUrl),
                'Impossible d\'ouvrir WhatsApp',
              );
            },
            child: const Text('Envoyer un WhatsApp'),
          ),
        ],
      ),
    );
  }

  String? loggedInUserName;
  Future<void> _loadLoggedInUser() async {
    // Obtenez l'utilisateur actuellement connecté via Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    // Mettez à jour l'état de l'interface utilisateur
    setState(() {
      // Le nom de l'utilisateur est accessible via la propriété displayName
      loggedInUserName = user?.displayName;
    });

    // Optionnel : Enregistrer le nom localement pour d'autres usages
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // if (loggedInUserName != null) {
    //   await prefs.setString('username', loggedInUserName!);
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si l'utilisateur n'est pas connecté, cela affichera un container vide.
    // La navigation vers la page de connexion se fait via l'écouteur d'état.
    if (_user == null) {
      return Scaffold(body: Container());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backdColor,
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person, size: 33),
              title: Text(loggedInUserName ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('Utilisateur'),
            ),
            //   if (loggedInUserName != null)

            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Mes Produits'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyProductsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Mes Commandes'),
              onTap: _historique,
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Mon Panier'),
              onTap: _panier,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Service Client'),
              onTap: _showCustomerServiceDialog,
            ),

            const ListTile(
              leading: Icon(Icons.share),
              title: Text('Partager l\'application'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.group_add),
              title: Text('Inviter des amis'),
            ),
            //      const Divider(),
            ListTile(
              leading: Icon(Icons.motorcycle),
              title: const Text('Livreur'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => OrdersPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: backdColor),
              title: const Text('Se déconnecter'),
              onTap: _logout,
            ),

            //const Divider(),
            Center(
              child: Image.asset('assets/icon.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                  fit: BoxFit.cover),
            )
          ],
        ),
      ),
    );
  }
}
