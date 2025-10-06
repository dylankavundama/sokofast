import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importez vos fichiers de support
import 'package:soko/api_config.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart'; // Assurez-vous que primaryYellow et primaryDarkBlue sont définis ici

// Définition de la structure de l'objet Order (pour la clarté)
class Order {
  final String transactionId;
  final String name;
  final String address;
  String status; // Peut changer
  final String paymentMethod;
  final String orderDate;
  final double totalPrice;
  final String productsSummary;
  final double latitude; // Nouvelle propriété pour la latitude
  final double longitude; // Nouvelle propriété pour la longitude

  Order({
    required this.transactionId,
    required this.name,
    required this.address,
    required this.status,
    required this.paymentMethod,
    required this.orderDate,
    required this.totalPrice,
    required this.productsSummary,
    this.latitude = 0.0, // Valeur par défaut
    this.longitude = 0.0, // Valeur par défaut
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      transactionId: json['transaction_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      orderDate: json['order_date'] as String,
      totalPrice: json['total_price'] is int
          ? (json['total_price'] as int).toDouble()
          : json['total_price'] as double,
      productsSummary: json['products_summary'] as String,
      latitude: json.containsKey('latitude')
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: json.containsKey('longitude')
          ? (json['longitude'] as num).toDouble()
          : 0.0,
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'TOUS'; // Par défaut

  // Liste des statuts disponibles pour le filtre et la mise à jour
  final List<String> _validStatuses = [
    'TOUS', // Pour le filtre uniquement
    'EN COURS',
    'TERMINER',
    'ANNULER',
  ];

  // Liste des statuts sans l'option 'TOUS', utilisée pour la modification de commande.
  late final List<String> _updatableStatuses =
      _validStatuses.where((s) => s != 'TOUS').toList();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ==================================================================
  // 1. LOGIQUE DE FILTRAGE DES COMMANDES
  // ==================================================================

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> queryParams = {};

      // CLÉ DU FILTRAGE: Envoi du statut sélectionné à l'API PHP
      if (_selectedStatusFilter != 'TOUS') {
        queryParams['status'] = _selectedStatusFilter;
      }

      final uri = Uri.parse('${ApiConfig.BASE_URL}/api_order.php').replace(
          queryParameters:
              queryParams.map((k, v) => MapEntry(k, v.toString())));

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _orders = jsonList.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception(
            'Échec du chargement des commandes: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur de connexion aux commandes: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================================================================
  // 2. LOGIQUE DE MISE À JOUR DU STATUT
  // ==================================================================

  Future<void> _updateOrderStatus(
      String transactionId, String newStatus) async {
    // Assurez-vous que l'API est correctement définie dans ApiConfig
    final url = '${ApiConfig.BASE_URL}/statut_order.php';

    // Statut en majuscules pour le backend (ex: 'pending' -> 'PENDING')
    final String statusForBackend = newStatus.toUpperCase();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': transactionId,
          // Envoyer le statut en MAJUSCULES
          'status': statusForBackend,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // 💡 CORRECTION : Trouver la commande dans la liste locale
        final orderIndex =
            _orders.indexWhere((o) => o.transactionId == transactionId);

        if (orderIndex != -1) {
          // Mise à jour locale du statut pour rafraîchir l'UI immédiatement
          setState(() {
            // Mettez à jour avec la valeur originale (minuscule ou correcte) pour l'affichage,
            // mais assurez-vous que la classe OrderData gère bien la casse pour l'UI.
            _orders[orderIndex].status = newStatus;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Statut mis à jour à ${statusForBackend}.'),
              backgroundColor: Colors.green),
        );

        // Optionnel : recharger la liste si un filtre est actif
        // Assurez-vous que _selectedStatusFilter et _fetchOrders existent dans votre classe.
        if (_selectedStatusFilter != 'TOUS' &&
            _selectedStatusFilter != newStatus) {
          // Si le nouveau statut ne correspond pas au filtre actuel, on recharge la liste pour masquer la commande.
          _fetchOrders();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Échec de la mise à jour: ${responseData['message'] ?? 'Erreur serveur'}'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur réseau lors de la mise à jour: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ==================================================================
  // 3. INTERFACE UTILISATEUR (UI)
  // ==================================================================
  Future<void> _launchMap(double latitude, double longitude) async {
    // Construction de l'URL Google Maps avec les coordonnées
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    final Uri uri = Uri.parse(googleMapsUrl);

    // Vérifie si l'application peut lancer l'URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Gestion de l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Impossible d\'ouvrir la carte pour $latitude, $longitude')),
        );
      }
    }
  }

// À placer dans la classe d'état de votre Widget (ex: _OrderHistoryScreenState)

// Fonction utilitaire pour extraire le numéro de téléphone du client
  String _extractClientPhoneNumber(String paymentMethod) {
    // Cas FlexPay (ex: 'FlexPay:243812345678')
    if (paymentMethod.contains(':')) {
      return paymentMethod.split(':').last;
    }
    // Cas WhatsApp ou autres (le numéro est le champ lui-même)
    return paymentMethod;
  }

  Future<void> _launchWhatsAppClient(dynamic order) async {
    // Le numéro de téléphone du client est stocké dans paymentMethod dans votre DB
    final String clientPhoneNumber =
        _extractClientPhoneNumber(order.paymentMethod);
    final String transactionId = order.transactionId;

    if (clientPhoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Numéro de client non trouvé pour cette commande.")),
        );
      }
      return;
    }

    // Formatage du numéro pour WhatsApp (doit inclure le code pays sans le '+', ex: 243...)
    // WhatsApp fonctionne mieux avec le code pays (243) directement collé au numéro.

    // Message pré-rempli pour l'administrateur
    final message =
        'Bonjour, je vous contacte au sujet de votre commande n° $transactionId. Elle est actuellement au statut : ${order.status}.';

    // Construction de l'URL WhatsApp
    final url = Uri.parse(
        'https://api.whatsapp.com/send?phone=$clientPhoneNumber&text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Impossible d'ouvrir WhatsApp pour le numéro $clientPhoneNumber.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du lancement de WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des Commandes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryYellow,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre de Statut (Fonctionne pour le triage)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filtrer par Statut',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatusFilter,
              items: _validStatuses
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatusFilter = newValue;
                  });
                  _fetchOrders(); // Recharger les commandes avec le nouveau filtre
                }
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];

                      // Détermine la valeur initiale du Dropdown pour la modification
                      // C'EST LA CORRECTION CLÉ POUR ÉVITER LE CRASH.
                      final String dropdownValue =
                          _updatableStatuses.contains(order.status)
                              ? order.status
                              : 'EN COURS'; // Valeur de secours valide

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${order.transactionId}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              Divider(),
                              const SizedBox(height: 5),
                              Text('Client: ${order.name}'),
                              //   Text('Adresse: ${order.address}'),
                              Text('Méthode: ${order.paymentMethod}'),
                              Text(
                                'Total: ${order.totalPrice.toStringAsFixed(2)} \$',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('Produits: ${order.productsSummary}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                              //  const Divider(),
                              // Assurez-vous que les coordonnées existent et sont valides avant d'afficher le bouton
                              // Affichage et modification du statut
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                    onTap: () {
                                      // Appel avec l'objet de la commande
                                    },
                                    child: Text('Contacter le client',
                                        style: TextStyle(
                                            color: primaryYellow,
                                            //      decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.bold))),
                              ),

                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.pin_drop,
                                          color: Colors.red),
                                      onPressed: () {
                                        // Appel de la fonction de lancement de la carte
                                        double lat = order.latitude;
                                        double lon = order.longitude;
                                        _launchMap(lat, lon);
                                      },
                                    ),
                                    Text(order.address),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _launchWhatsAppClient(order);
                                      },
                                      icon: const Icon(Icons.call,
                                          color: Colors.white),
                                      label: const Text('WhatsApp Client',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ]),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Statut actuel: ${order.status}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: order.status == 'TERMINER'
                                              ? Colors.green
                                              : Colors.orange)),

                                  // Dropdown pour la modification (CORRIGÉ)
                                  DropdownButton<String>(
                                    value:
                                        dropdownValue, // Utilise la valeur sécurisée
                                    items:
                                        _updatableStatuses // Liste sans 'TOUS'
                                            .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        _updateOrderStatus(
                                            order.transactionId, newValue);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
