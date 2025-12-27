import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importez vos fichiers de support
import 'package:soko/api_config.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart'; // Assurez-vous que primaryYellow et primaryDarkBlue sont définis ici
import 'package:soko/utils/responsive.dart';

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
  String? _selectedStatusFilter; // Sera initialisé dans build()

  // Liste des statuts disponibles pour le filtre et la mise à jour
  List<String> _getValidStatuses(AppLocalizations loc) {
    return [
      loc.adminStatusAll, // Pour le filtre uniquement
      loc.adminStatusInProgress,
      loc.adminStatusCompleted,
      loc.adminStatusCancelled,
    ];
  }

  // Liste des statuts sans l'option 'Tous', utilisée pour la modification de commande.
  List<String> _getUpdatableStatuses(AppLocalizations loc) {
    final allStatuses = _getValidStatuses(loc);
    return allStatuses.where((s) => s != loc.adminStatusAll).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> queryParams = {};

      final loc = AppLocalizations.of(context);
      if (_selectedStatusFilter != null && _selectedStatusFilter != loc.adminStatusAll) {
        queryParams['status'] = _selectedStatusFilter;
      }

      final uri = Uri.parse('https://babutik.com/soko/api_order.php').replace(
          queryParameters:
              queryParams.map((k, v) => MapEntry(k, v.toString())));

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _orders = jsonList.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        final loc = AppLocalizations.of(context);
        throw Exception(loc.adminLoadFailed(response.statusCode.toString()));
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.adminConnectionError(e.toString())),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(
      String transactionId, String newStatus) async {
    final url = '${ApiConfig.BASE_URL}/statut_order.php';
    final String statusForBackend = newStatus.toUpperCase();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': transactionId,
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

        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.adminStatusUpdated(statusForBackend)),
              backgroundColor: Colors.green),
        );

        if (_selectedStatusFilter != null && 
            _selectedStatusFilter != loc.adminStatusAll &&
            _selectedStatusFilter != newStatus) {
          _fetchOrders();
        }
      } else {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.adminUpdateFailed(responseData['message'] ?? loc.adminServerError)),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.adminNetworkError(e.toString())),
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

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.adminCouldNotOpenMap(latitude.toString(), longitude.toString()))),
        );
      }
    }
  }

  String _extractClientPhoneNumber(String paymentMethod) {
    if (paymentMethod.contains(':')) {
      return paymentMethod.split(':').last;
    }
    return paymentMethod;
  }

  Future<void> _launchWhatsAppClient(dynamic order) async {
    final String clientPhoneNumber =
        _extractClientPhoneNumber(order.paymentMethod);
    final String transactionId = order.transactionId;

    final loc = AppLocalizations.of(context);
    if (clientPhoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.adminClientPhoneNotFound)),
        );
      }
      return;
    }

    final message = loc.adminWhatsappMessage(transactionId, order.status);

    // Construction de l'URL WhatsApp
    final url = Uri.parse(
        'https://api.whatsapp.com/send?phone=$clientPhoneNumber&text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final loc = AppLocalizations.of(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(loc.adminCouldNotOpenWhatsapp(clientPhoneNumber))),
          );
        }
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.adminWhatsappError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // Initialiser le filtre si ce n'est pas déjà fait
    _selectedStatusFilter ??= loc.adminStatusAll;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.adminOrdersTitle,
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
        ),
        backgroundColor: primaryYellow,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre de Statut (Fonctionne pour le triage)
          Padding(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 0.5),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: loc.adminFilterStatus,
                border: const OutlineInputBorder(),
              ),
              value: _selectedStatusFilter ?? loc.adminStatusAll,
              items: _getValidStatuses(loc)
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
                : Responsive.centerContent(
                    context,
                    ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];

<<<<<<< Updated upstream
                        // Détermine la valeur initiale du Dropdown pour la modification
                        // C'EST LA CORRECTION CLÉ POUR ÉVITER LE CRASH.
                        final String dropdownValue =
                            _updatableStatuses.contains(order.status)
                                ? order.status
                                : 'EN COURS'; // Valeur de secours valide
=======
                      final loc = AppLocalizations.of(context);
                      final updatableStatuses = _getUpdatableStatuses(loc);
                      // Détermine la valeur initiale du Dropdown pour la modification
                      // C'EST LA CORRECTION CLÉ POUR ÉVITER LE CRASH.
                      final String dropdownValue =
                          updatableStatuses.contains(order.status)
                              ? order.status
                              : loc.adminStatusInProgress; // Valeur de secours valide
>>>>>>> Stashed changes

                        return Card(
                          margin: EdgeInsets.symmetric(
                            vertical: Responsive.getVerticalPadding(context),
                            horizontal: Responsive.getHorizontalPadding(context) * 0.625,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 0.75),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.adminOrderId(order.transactionId),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              Divider(),
                              const SizedBox(height: 5),
                              Text(loc.adminClient(order.name)),
                              Text('${loc.adminPaymentMethod}: ${order.paymentMethod}'),
                              Text(
                                loc.adminTotal(order.totalPrice.toStringAsFixed(2)),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(loc.adminProducts(order.productsSummary),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.pin_drop,
                                          color: Colors.red),
                                      onPressed: () {
                                        _launchMap(order.latitude, order.longitude);
                                      },
                                    ),
                                    Text(order.address),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryYellow,
                                      ) ,
                                      onPressed: () {
                                        _launchWhatsAppClient(order);
                                      },
                                      icon: const Icon(Icons.call,
                                          color: Colors.green),
                                      label: Text(loc.adminChat,
                                          style:
                                              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white)),
                                    ),
                                  ]),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(loc.adminCurrentStatus(order.status),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: order.status == loc.adminStatusCompleted
                                              ? Colors.green
                                              : Colors.orange)                                  ),
                                  DropdownButton<String>(
                                    value: dropdownValue,
                                    items: updatableStatuses
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
          ),
        ],
      ),
    );
  }
}
