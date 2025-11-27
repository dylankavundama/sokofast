import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importez vos fichiers de support
import 'package:soko/api_config.dart';
import 'package:soko/style.dart';
import 'package:soko/utils/responsive.dart';
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
  String? _livreurEmail; // 💡 NOUVEAU : Email du livreur connecté

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
    _loadLivreurEmail();
  }

  // 💡 NOUVEAU : Charger l'email du livreur connecté
  Future<void> _loadLivreurEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _livreurEmail = user.email;
      });
      _fetchOrders();
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Aucun utilisateur connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================================================================
  // 1. LOGIQUE DE FILTRAGE DES COMMANDES
  // ==================================================================

  Future<void> _fetchOrders() async {
    if (_livreurEmail == null) {
      return; // Ne pas charger si l'email n'est pas disponible
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> queryParams = {};

      // 💡 NOUVEAU : Filtrer par email du livreur connecté
      queryParams['livreur_email'] = _livreurEmail!;

      // CLÉ DU FILTRAGE: Envoi du statut sélectionné à l'API PHP
      if (_selectedStatusFilter != 'TOUS') {
        queryParams['status'] = _selectedStatusFilter;
      }

      final uri = Uri.parse('${ApiConfig.BASE_URL}/api_order.php').replace(
          queryParameters:
              queryParams.map((k, v) => MapEntry(k, v.toString())));

      print("🔍 Récupération des commandes pour livreur: $_livreurEmail");
      print("🌐 URL: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _orders = jsonList.map((json) => Order.fromJson(json)).toList();
        });
        print("✅ ${_orders.length} commandes trouvées pour le livreur");
      } else {
        throw Exception(
            'Échec du chargement des commandes: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des commandes: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de connexion aux commandes: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
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

        // 💡 NOUVEAU : Vérifier si une notification WhatsApp est disponible
        final whatsappNotification = responseData['whatsapp_notification'];
        if (whatsappNotification != null && 
            whatsappNotification['sent'] == true && 
            whatsappNotification['url'] != null) {
          // Afficher un SnackBar avec option d'ouvrir WhatsApp
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Expanded(
                    child: Text('Statut mis à jour. Notification WhatsApp disponible.'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final whatsappUrl = whatsappNotification['url'];
                      if (whatsappUrl != null) {
                        try {
                          final uri = Uri.parse(whatsappUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Impossible d\'ouvrir WhatsApp'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Ouvrir WhatsApp',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // Message simple si pas de WhatsApp
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statut mis à jour à $statusForBackend.'),
              backgroundColor: Colors.green,
            ),
          );
        }

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

  // 💡 NOUVEAU : Formater la date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Il y a ${difference.inMinutes} min';
        }
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  // 💡 NOUVEAU : Obtenir la couleur du badge selon le statut
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TERMINER':
        return Colors.green;
      case 'EN COURS':
        return Colors.orange;
      case 'ANNULER':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 💡 NOUVEAU : Obtenir l'icône selon le statut
  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'TERMINER':
        return Icons.check_circle;
      case 'EN COURS':
        return Icons.hourglass_empty;
      case 'ANNULER':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Commandes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryYellow,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // 💡 NOUVEAU : Filtre amélioré avec style moderne
          Container(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 0.75),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: primaryYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Filtrer par statut',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedStatusFilter,
                    items: _validStatuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            if (status != 'TOUS')
                              Icon(
                                _getStatusIcon(status),
                                size: 18,
                                color: _getStatusColor(status),
                              ),
                            if (status != 'TOUS') const SizedBox(width: 8),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatusFilter = newValue;
                        });
                        _fetchOrders();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_orders.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 💡 NOUVEAU : Liste améliorée avec pull-to-refresh
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                        SizedBox(height: 16),
                        Text('Chargement des commandes...'),
                      ],
                    ),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune commande',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedStatusFilter == 'TOUS'
                                  ? 'Vous n\'avez aucune commande pour le moment'
                                  : 'Aucune commande avec le statut "$_selectedStatusFilter"',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        color: primaryYellow,
                        child: Responsive.centerContent(
                          context,
                          ListView.builder(
                            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 0.75),
                            itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final String dropdownValue =
                                _updatableStatuses.contains(order.status)
                                    ? order.status
                                    : 'EN COURS';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Optionnel : afficher les détails
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 💡 NOUVEAU : En-tête avec ID et statut
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryYellow
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '#${order.transactionId}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: primaryYellow,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            order.status)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _getStatusIcon(
                                                            order.status),
                                                        size: 14,
                                                        color: _getStatusColor(
                                                            order.status),
                                                      ),
                                                      const SizedBox(
                                                          width: 6),
                                                      Text(
                                                        order.status,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                          color: _getStatusColor(
                                                              order.status),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatDate(order.orderDate),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // 💡 NOUVEAU : Informations client
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order.paymentMethod,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // 💡 NOUVEAU : Adresse avec bouton carte
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              order.address,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.map,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _launchMap(
                                                  order.latitude,
                                                  order.longitude);
                                            },
                                            tooltip: 'Ouvrir la carte',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // 💡 NOUVEAU : Produits
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.shopping_bag,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                order.productsSummary,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // 💡 NOUVEAU : Total et actions
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                '${order.totalPrice.toStringAsFixed(2)} \$',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: primaryYellow,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              _launchWhatsAppClient(order);
                                            },
                                            icon: const Icon(
                                              Icons.chat,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Contacter',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // 💡 NOUVEAU : Changer le statut
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Changer le statut',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: DropdownButton<String>(
                                              value: dropdownValue,
                                              underline: const SizedBox(),
                                              items: _updatableStatuses
                                                  .map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _getStatusIcon(value),
                                                        size: 16,
                                                        color:
                                                            _getStatusColor(value),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(value),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  _updateOrderStatus(
                                                      order.transactionId,
                                                      newValue);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
        
        ],
      ),
    );
  }
}
