import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:soko/services.dart'; // Assurez-vous que ce fichier contient `baseUrl`
import 'package:soko/l10n/app_localizations.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? loggedInUserName;

  @override
  void initState() {
    super.initState();
    // Appelle une seule fonction pour initialiser l'utilisateur et récupérer les données
    _initializeAndFetchOrders();
  }

  /// Initialise les données en s'assurant que l'utilisateur est connecté et récupère ensuite les commandes.
  Future<void> _initializeAndFetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.displayName == null) {
      // Si l'utilisateur n'est pas connecté ou n'a pas de nom d'affichage
      setState(() {
        _isLoading = false;
        _errorMessage = loc.ordersMustLogin;
      });
      return;
    }

    // Définit le nom d'utilisateur et récupère les commandes
    setState(() {
      loggedInUserName = user.displayName;
    });
    await _fetchOrdersFromApi();
  }

  /// Récupère les commandes de l'utilisateur depuis l'API.
  Future<void> _fetchOrdersFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // L'API est maintenant responsable de filtrer les commandes par nom d'utilisateur
      final response = await http.get(Uri.parse('$baseUrl/getcmd.php?username=$loggedInUserName'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'success') {
          final List<dynamic> fetchedOrders = json['data'];

          setState(() {
            orders = fetchedOrders.map<Map<String, dynamic>>((order) {
              final List<dynamic> productList = order['productList'] ?? [];
              return {
                ...order,
                'productList': productList,
              };
            }).toList();

            // Triez les commandes par date (la plus récente en premier)
            orders.sort((a, b) => b['order_date'].compareTo(a['order_date']));
          });
        } else {
          final loc = AppLocalizations.of(context);
          setState(() {
            _errorMessage = json['message'] ?? loc.ordersNotFoundMessage;
            orders = []; // S'assurer que la liste est vide en cas d'erreur
          });
        }
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          _errorMessage = loc.ordersServerError(response.statusCode.toString());
          orders = [];
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        _errorMessage = loc.ordersConnectionError(e.toString());
        orders = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Traduit le statut pour l'affichage
  String _getLocalizedStatus(BuildContext context, String status) {
    final loc = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'en cours':
      case 'pending':
      case 'in progress':
        return loc.statusInProgress;
      case 'terminé':
      case 'completed':
        return loc.statusCompleted;
      case 'annulé':
      case 'cancelled':
        return loc.statusCancelled;
      default:
        return status;
    }
  }

  /// Fonction utilitaire pour obtenir la couleur du statut.
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'annulé':
        return Colors.red;
      case 'en cours':
        return Colors.orange;
      case 'terminé':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ordersTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Rafraîchir les données en appelant la fonction de récupération
              if (loggedInUserName != null) {
                _fetchOrdersFromApi();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initializeAndFetchOrders,
                        child: Text(loc.ordersRetry),
                      ),
                    ],
                  ),
                )
              : orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
                          const SizedBox(height: 20),
                          Text(
                            loc.ordersNotFound,
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${loc.ordersConnectedAs} ${loggedInUserName ?? ''}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrdersFromApi,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final date = DateTime.parse(order['order_date']);
                          final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);

                          final totalPriceFromBackend = double.tryParse(order['total_price'].toString()) ?? 0.0;
                          // --- MODIFICATION POUR AJOUTER 30% AU PRIX TOTAL ---
                          final percentageIncrease = 0.30;
                          final displayedOrderTotal = totalPriceFromBackend * (1 + percentageIncrease);
                          // -----------------------------------------------------
                          final status = order['status']?.toString() ?? loc.statusUnknown;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ExpansionTile(
                              leading: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                loc.ordersOrderNumber(order['id'].toString()),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formattedDate,style: GoogleFonts.abel(),),
                                  Text(
                                    '${displayedOrderTotal.toStringAsFixed(2)} \$',
                                    style: GoogleFonts.abel(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(loc, loc.ordersStatus, _getLocalizedStatus(context, status), getStatusColor(status)),
                                      _buildInfoRow(loc, loc.ordersPaymentMethod, order['payment_method']),
                                      if (order['address'] != null)
                                        _buildInfoRow(loc, loc.ordersAddress, order['address']),
                                      const SizedBox(height: 15),
                                      const Divider(),
                                      Text(
                                        loc.ordersProductsDetails,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 10),
                                      ...(order['productList'] as List)
                                          .map((product) {
                                            final productName = product['product_name'] ?? loc.productUnknown;
                                            final quantity = product['quantity'] ?? 0;
                                            final totalForProductLine = (product['total_price'] as num?)?.toDouble() ?? 0.0;
                                            
                                            // L'augmentation de 30% ne s'applique QU'AU total de la commande
                                            // On garde ici le prix unitaire et le total de la ligne sans l'augmentation pour les détails.
                                            final unitPrice = quantity > 0 ? totalForProductLine / quantity : 0.0;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 5),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(productName, style: const TextStyle(fontSize: 14)),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      // '$quantity x ${unitPrice.toStringAsFixed(2)} \$',
                                                                        '$quantity x',
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                  ),
                                                  // Expanded(
                                                  //   flex: 2,
                                                  //   child: Text(
                                                  //     '${totalForProductLine.toStringAsFixed(2)} \$',
                                                  //     textAlign: TextAlign.end,
                                                  //     style: const TextStyle(
                                                  //       fontSize: 14,
                                                  //       fontWeight: FontWeight.bold,
                                                  //     ),
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            );
                                          })
                                          ,
                                      const SizedBox(height: 15),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            loc.ordersTotal,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            '${displayedOrderTotal.toStringAsFixed(2)} \$',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  /// Widget utilitaire pour afficher les lignes d'information.
  Widget _buildInfoRow(AppLocalizations loc, String label, String? value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value ?? loc.unspecified,
              style: TextStyle(fontSize: 14, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}