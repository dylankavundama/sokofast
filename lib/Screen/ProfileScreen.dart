import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> Stashed changes
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/Profil/mes_produits.dart';
import 'package:soko/Screen/CartScreen.dart';
<<<<<<< Updated upstream
// import 'package:soko/livreur/login_livreur.dart'; // 💡 Plus nécessaire, redirection directe
import 'package:soko/livreur/order.dart';
import 'package:soko/services/user_service.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soko/Profil/delete_account_screen.dart';
import 'package:soko/utils/responsive.dart';
=======
import 'package:soko/Screen/language_selection.dart';
import 'package:soko/Screen/theme_selection.dart';
import 'package:soko/admin/login_livreur.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/main.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart';
>>>>>>> Stashed changes

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
  String? _userStatut; // 💡 NOUVEAU : Statut de l'utilisateur (client/vendeur)
  bool _isVendeur = false; // 💡 NOUVEAU : Indicateur si l'utilisateur est vendeur
  bool _isLivreur = false; // 💡 NOUVEAU : Indicateur si l'utilisateur est livreur
  bool _isLoadingStatus = true; // 💡 NOUVEAU : Indicateur de chargement des statuts

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser(); // Charger le nom de l'utilisateur connecté
    // 1. On charge l'utilisateur actuel au démarrage.
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      // 💡 NOUVEAU : Vérifications IMMÉDIATES et PARALLÈLES des statuts
      // On les lance immédiatement sans attendre pour une exécution instantanée
      Future.wait([
        _loadUserStatut(),
        _checkLivreurStatus(),
      ]).then((_) {
        // Succès - les méthodes ont déjà mis à jour _isLoadingStatus
      }).catchError((e) {
        print("❌ Erreur lors des vérifications initiales: $e");
        if (mounted) {
          setState(() {
            _isLoadingStatus = false;
          });
        }
      });
      _loadUserData();
    } else {
      // Si l'utilisateur n'est pas connecté, on termine le chargement et on le gère.
      setState(() {
        _isLoading = false;
        _isLoadingStatus = false; // Pas besoin de charger les statuts si pas connecté
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
      
      // Réinitialiser le chargement des statuts
      if (mounted) {
        setState(() {
          _isLoadingStatus = user != null; // Charger les statuts seulement si connecté
        });
      }

      if (_user != null) {
        // L'utilisateur est connecté, on charge ses données
        // 💡 NOUVEAU : Vérifications IMMÉDIATES et PARALLÈLES des statuts
        Future.wait([
          _loadUserStatut(),
          _checkLivreurStatus(),
        ]).then((_) {
          // Succès - les méthodes ont déjà mis à jour _isLoadingStatus
        }).catchError((e) {
          print("❌ Erreur lors des vérifications dans l'écouteur: $e");
          if (mounted) {
            setState(() {
              _isLoadingStatus = false;
            });
          }
        });
        _loadUserData();
      } else {
        // 💡 MODIFIÉ : Ne plus rediriger automatiquement, permettre l'accès en mode invité
        // L'utilisateur peut rester sur la page de profil en mode invité
        if (mounted) {
          setState(() {
            _isLoadingStatus = false;
            _username = 'Invité';
            loggedInUserName = null;
            _isVendeur = false;
            _isLivreur = false;
          });
        }
      }
    });
  }
  
  // 💡 NOUVEAU : Méthode pour rafraîchir les statuts manuellement
  Future<void> refreshStatus() async {
    if (_user != null && _user!.email != null) {
      print("🔄 Rafraîchissement des statuts...");
      
      // Marquer le début du rafraîchissement
      if (mounted) {
        setState(() {
          _isLoadingStatus = true;
        });
      }
      
      // Rafraîchir les statuts
      await Future.wait([
        _loadUserStatut(),
        _checkLivreurStatus(),
      ]);
      
      // Marquer la fin du rafraîchissement
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statuts rafraîchis - Vendeur: $_isVendeur, Livreur: $_isLivreur'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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

      // 💡 Les vérifications sont déjà appelées dans initState et _setupAuthStateListener
      // On ne les appelle pas ici pour éviter les doublons et garantir une exécution immédiate
    } catch (e) {
      print("Erreur de chargement des données utilisateur : $e");
      if (mounted) {
        setState(() {
          _username = 'Erreur';
          _isLoadingStatus = false; // Arrêter le chargement même en cas d'erreur
        });
      }
    }
  }

  // 💡 NOUVEAU : Charger le statut de l'utilisateur via l'email
  Future<void> _loadUserStatut() async {
    try {
      // 💡 Vérifier que l'utilisateur est disponible
      final user = _user ?? FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print("❌ Email ou utilisateur null");
        if (mounted) {
          setState(() {
            _userStatut = 'client';
            _isVendeur = false;
            _isLoadingStatus = false;
          });
        }
        return;
      }
      
      print("🔍 Vérification IMMÉDIATE du statut pour l'email: ${user.email}");
      // 💡 Vérifier le statut via l'email de l'utilisateur connecté
      final userData = await UserService.getUserByEmail(user.email!);
      print("📦 Données reçues: $userData");
      
      if (userData != null) {
        final statut = userData['statut']?.toString().toLowerCase() ?? 'client';
        print("📊 Statut brut: ${userData['statut']}, Statut normalisé: $statut");
        
        if (mounted) {
          setState(() {
            _userStatut = statut;
            _isVendeur = statut == 'vendeur';
            _isLoadingStatus = false; // Marquer comme terminé
          });
        }
        print("✅ Statut vérifié via email: ${user.email} -> $_userStatut (isVendeur: $_isVendeur)");
      } else {
        print("⚠️ Utilisateur non trouvé dans la base de données");
        // Si l'utilisateur n'existe pas dans la base, l'enregistrer
        await UserService.registerUserAfterLogin(user);
        if (mounted) {
          setState(() {
            _userStatut = 'client';
            _isVendeur = false;
            _isLoadingStatus = false;
          });
        }
        print("⚠️ Utilisateur enregistré comme client");
      }
    } catch (e, stackTrace) {
      print("❌ Erreur de chargement du statut : $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _userStatut = 'client';
          _isVendeur = false;
          _isLoadingStatus = false;
        });
      }
    }
  }

  // 💡 NOUVEAU : Vérifier si l'utilisateur est livreur via l'email
  Future<void> _checkLivreurStatus() async {
    try {
      // 💡 Vérifier que l'utilisateur est disponible
      final user = _user ?? FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print("❌ Email ou utilisateur null pour vérification livreur");
        if (mounted) {
          setState(() {
            _isLivreur = false;
            _isLoadingStatus = false;
          });
        }
        return;
      }
      
      print("🔍 Vérification IMMÉDIATE livreur pour l'email: ${user.email}");
      // 💡 Vérifier si l'utilisateur est livreur via son email
      final isLivreur = await UserService.isLivreurByEmail(user.email!);
      if (mounted) {
        setState(() {
          _isLivreur = isLivreur;
          _isLoadingStatus = false; // Marquer comme terminé
        });
      }
      print("✅ Vérification livreur via email: ${user.email} -> $_isLivreur");
    } catch (e, stackTrace) {
      print("❌ Erreur de vérification livreur : $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _isLivreur = false;
          _isLoadingStatus = false;
        });
      }
    }
  }

  // Met à jour le nom de l'utilisateur dans Firebase et Firestore
  Future<void> _changeName() async {
    if (_user == null) return;
    final loc = AppLocalizations.of(context);
    TextEditingController controller = TextEditingController(text: _username);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.profileChangeName),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.myProductsCancel)),
          ElevatedButton(
            child: Text(loc.profileSave),
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
                  SnackBar(
                      content: Text(loc.profileNameUpdated)),
                );
              } catch (e) {
                print("Erreur de mise à jour du nom : $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(loc.profileNameUpdateError(e.toString()))),
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
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.profileSupportTitle),
        content: Text(loc.profileSupportContent),
        actions: [
<<<<<<< Updated upstream
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     _launchUrl(
          //       Uri(
          //           scheme: 'mailto',
          //           path: 'support@soko.com',
          //           queryParameters: {'subject': 'Demande de support'}),
          //       'Impossible d\'ouvrir l\'application email',
          //     );
          //   },
          //   child: const Text('Envoyer un email'),
          // ),
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     _launchUrl(
          //       Uri(scheme: 'tel', path: '+1234567890'),
          //       'Impossible de passer un appel',
          //     );
          //   },
          //   child: const Text('Passer un appel'),
          // ),
=======
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
            child: Text(loc.profileSendEmail),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(
                Uri(scheme: 'tel', path: '+1234567890'),
                'Impossible de passer un appel',
              );
            },
            child: Text(loc.profileMakeCall),
          ),
>>>>>>> Stashed changes
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final whatsappUrl =
                  "https://wa.me/+243992959898?text=${Uri.encodeFull('Bonjour, j\'ai besoin d\'aide concernant...')}";
              _launchUrl(
                Uri.parse(whatsappUrl),
                'Impossible d\'ouvrir WhatsApp',
              );
            },
<<<<<<< Updated upstream
            child: const Text('Contactez-nous via WhatsApp'),
=======
            child: Text(loc.profileSendWhatsapp),
>>>>>>> Stashed changes
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

  // Obtenir le nom de la langue actuelle
  String _getCurrentLanguageName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return _getLanguageDisplayName(locale);
  }

  // Obtenir le nom d'affichage de la langue
  String _getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  // Obtenir le nom du thème actuel
  Future<String> _getCurrentThemeName(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeModeString = prefs.getString('theme_mode');
    final loc = AppLocalizations.of(context);
    
    if (themeModeString == null) {
      return loc.themeSystem;
    }
    
    switch (themeModeString) {
      case 'light':
        return loc.themeLight;
      case 'dark':
        return loc.themeDark;
      case 'system':
      default:
        return loc.themeSystem;
    }
  }

  // Obtenir le nom d'affichage du thème
  String _getThemeDisplayName(ThemeMode themeMode, AppLocalizations loc) {
    switch (themeMode) {
      case ThemeMode.light:
        return loc.themeLight;
      case ThemeMode.dark:
        return loc.themeDark;
      case ThemeMode.system:
        return loc.themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    // 💡 Afficher le chargement tant que les données utilisateur ne sont pas chargées
    // OU tant que les statuts ne sont pas vérifiés
    if (_isLoading || _isLoadingStatus) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: backdColor,
          centerTitle: true,
          title: const Text(
            'Mon Profil',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Chargement de vos informations...'),
            ],
          ),
=======
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
>>>>>>> Stashed changes
        ),
      );
    }

    // 💡 MODIFIÉ : Afficher une interface invité si l'utilisateur n'est pas connecté
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: backdColor,
          centerTitle: true,
          title: const Text(
            'Mon Profil',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Responsive.centerContent(
          context,
          Padding(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 1.875),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Icône d'invité
              CircleAvatar(
                radius: Responsive.isMobile(context) ? 60.0 : 80.0,
                backgroundColor: backdColor,
                child: Icon(
                  Icons.person_outline,
                  size: Responsive.isMobile(context) ? 70.0 : 90.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.getVerticalPadding(context) * 3),
              Text(
                'Mode Invité',
                style: TextStyle(
                  fontSize: Responsive.getAdaptiveFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: Responsive.getVerticalPadding(context) * 1.5),
              Text(
                'Connectez-vous pour accéder à toutes les fonctionnalités',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: Responsive.getVerticalPadding(context) * 5),
              // Bouton de connexion
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                icon: const Icon(Icons.login, color: Colors.white),
                label: Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.getAdaptiveFontSize(context, mobile: 18, tablet: 20),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: backdColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.getHorizontalPadding(context) * 2,
                    vertical: Responsive.getVerticalPadding(context) * 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              // Options disponibles en mode invité
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Mon Panier'),
                onTap: _panier,
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Service Client'),
                onTap: _showCustomerServiceDialog,
              ),
            ],
          ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backdColor,
        centerTitle: true,
        title: Text(
          loc.profileTitle,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // 💡 NOUVEAU : Bouton de rafraîchissement dans l'AppBar
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshStatus,
            tooltip: 'Rafraîchir les statuts',
          ),
        ],
      ),
      body: Responsive.centerContent(
        context,
        Padding(
          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 1.875),
          child: ListView(
          children: [
<<<<<<< Updated upstream
            // 💡 NOUVEAU : Carte de profil avec icône de certification
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar avec icône de certification
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: backdColor,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        // 💡 Icône de certification si vendeur ou livreur
                        if (_isVendeur || _isLivreur)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  loggedInUserName ?? 'Utilisateur',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 💡 Badges de statut
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (_isVendeur)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.store,
                                        size: 14,
                                        color: Colors.orange[900],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Vendeur',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isLivreur)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.motorcycle,
                                        size: 14,
                                        color: Colors.green[900],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Livreur',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
=======
            ListTile(
              leading: Icon(Icons.person, size: 33),
              title: Text(loggedInUserName ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(loc.profileUserLabel),
>>>>>>> Stashed changes
            ),
            
            // 💡 DEBUG : Afficher les statuts pour déboguer
            // Card(
            //   color: Colors.blue[50],
            //   child: Padding(
            //     padding: const EdgeInsets.all(12.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.bug_report, color: Colors.blue[900], size: 20),
            //             const SizedBox(width: 8),
            //             Text('🔍 Debug Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
            //             const Spacer(),
            //             IconButton(
            //               icon: Icon(Icons.refresh, color: Colors.blue[900]),
            //               onPressed: () {
            //                 // Rafraîchir les statuts
            //                 _loadUserStatut();
            //                 _checkLivreurStatus();
            //               },
            //               tooltip: 'Rafraîchir',
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 8),
            //         Text('Email: ${_user?.email ?? "N/A"}', style: TextStyle(fontSize: 12)),
            //         Text('Statut DB: $_userStatut', style: TextStyle(fontSize: 12)),
            //         Text('Is Vendeur: $_isVendeur', style: TextStyle(fontSize: 12, color: _isVendeur ? Colors.green : Colors.red)),
            //         Text('Is Livreur: $_isLivreur', style: TextStyle(fontSize: 12, color: _isLivreur ? Colors.green : Colors.red)),
            //       ],
            //     ),
            //   ),
            // ),

            const Divider(),
<<<<<<< Updated upstream
            // 💡 NOUVEAU : Afficher "Mes Produits" uniquement si l'utilisateur est vendeur
            if (_isVendeur)
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
=======
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(loc.profileMyProducts),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyProductsScreen()));
              },
            ),
>>>>>>> Stashed changes
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(loc.profileMyOrders),
              onTap: _historique,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(loc.profileMyCart),
              onTap: _panier,
            ),
            const Divider(),
            
            // Section Paramètres
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                loc.profileSettings,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: Text(loc.profileChangeLanguage),
              subtitle: Text(
                _getCurrentLanguageName(context),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LanguageSelectionScreen(
                      onLanguageSelected: (locale) {
                        MyApp.of(context)?.setLocale(locale);
                        Navigator.pop(context);
                        // Afficher un message de confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${loc.profileChangeLanguage}: ${_getLanguageDisplayName(locale)}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<String>(
              future: _getCurrentThemeName(context),
              builder: (context, snapshot) {
                return ListTile(
                  leading: const Icon(Icons.brightness_6, color: Colors.orange),
                  title: Text(loc.themeTitle),
                  subtitle: Text(
                    snapshot.data ?? loc.themeSystem,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThemeSelectionScreen(
                          onThemeSelected: (themeMode) {
                            MyApp.of(context)?.setThemeMode(themeMode);
                            Navigator.pop(context);
                            // Afficher un message de confirmation
                            final loc = AppLocalizations.of(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.themeChanged(_getThemeDisplayName(themeMode, loc)),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Rafraîchir l'écran pour mettre à jour le sous-titre
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: Text(loc.profileSupport),
              onTap: _showCustomerServiceDialog,
            ),

<<<<<<< Updated upstream
            // const ListTile(
            //   leading: Icon(Icons.share),
            //   title: Text('Partager l\'application'),
            // ),
            // const Divider(),
            // const ListTile(
            //   leading: Icon(Icons.group_add),
            //   title: Text('Inviter des amis'),
            // ),
            //      const Divider(),
            // 💡 NOUVEAU : Afficher "Livreur" uniquement si l'utilisateur est livreur
            // 💡 Un utilisateur peut être à la fois vendeur ET livreur
            if (_isLivreur)
              ListTile(
                leading: Icon(Icons.motorcycle),
                title: const Text('Livreur'),
                onTap: () {
                  // Redirection directe vers la page des commandes livreur
                  // Plus besoin de page de login, tout est géré automatiquement
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersPage()),
                  );
                },
              ),
            const Divider(),
=======
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(loc.profileShareApp),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: Text(loc.profileInviteFriends),
            ),
            //      const Divider(),
            ListTile(
              leading: const Icon(Icons.motorcycle),
              title: Text(loc.profileDelivery),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginLivre()));
              },
            ),
>>>>>>> Stashed changes
            ListTile(
              leading: Icon(Icons.logout, color: backdColor),
              title: Text(loc.profileLogout),
              onTap: _logout,
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red[700]),
              title: Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red[700]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),

            //const Divider(),
            // Center(
            //   child: Image.asset('assets/icon.png',
            //       height: MediaQuery.of(context).size.height * 0.2,
            //       fit: BoxFit.cover),
            // )
          ],
        ),
        ),
      ),
    );
  }
}
