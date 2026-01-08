import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/OrderHistoryScreen.dart';
import 'package:soko/Profil/mes_produits.dart';
import 'package:soko/Screen/CartScreen.dart';
import 'package:soko/Screen/language_selection.dart';
import 'package:soko/Screen/theme_selection.dart';
import 'package:soko/admin/login_livreur.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/main.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // L'objet utilisateur de Firebase, qui est la source unique de vérité pour l'authentification.
  User? _user;
  String _username = "";
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
        _username = '';
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
          _username = userDoc.get('username') ?? '';
        });
      } else {
        // Si le document Firestore n'existe pas, on utilise le displayName de Firebase Auth
        setState(() {
          _username = _user!.displayName ?? '';
        });
      }
    } catch (e) {
      print("Erreur de chargement des données utilisateur : $e");
      setState(() {
        _username = '';
      });
    }
  }

  // Met à jour le nom de l'utilisateur dans Firebase et Firestore
  Future<void> _changeName() async {
    if (_user == null) return;
    final loc = AppLocalizations.of(context)!;
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
            child: Text(loc.profileSendWhatsapp),
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
    final loc = AppLocalizations.of(context);
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
        title: Text(
          loc.profileTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person, size: 33),
              title: Text(_username.isNotEmpty ? _username : loc.myProductsDefaultUser,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(loc.profileUserLabel),
            ),
            //   if (loggedInUserName != null)

            const Divider(),
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
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(loc.profileMyOrders),
              onTap: _historique,
            ),
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
            ListTile(
              leading: Icon(Icons.logout, color: backdColor),
              title: Text(loc.profileLogout),
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
