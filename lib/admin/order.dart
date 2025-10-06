import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:soko/style.dart';
import 'package:url_launcher/url_launcher.dart';

// -----------------------------------------------------------------
// MODÈLE DE DONNÉES (Commande)
// -----------------------------------------------------------------

class Commande {
  final String transactionReference; 
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double totalPrice; 
  final String status;
  final String paymentMethod;
  final DateTime orderDate;
  final String productsSummary;

  Commande({
    required this.transactionReference,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.orderDate,
    required this.productsSummary,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    // Gestion sécurisée des champs double (pour éviter l'erreur int vs double)
    double? lat = double.tryParse(json['latitude']?.toString() ?? '');
    double? lng = double.tryParse(json['longitude']?.toString() ?? '');
    
    // S'assurer qu'ils sont null si non valides
    if (lat == null || lat.isNaN) lat = null;
    if (lng == null || lng.isNaN) lng = null;

    // FIX INT/DOUBLE: utilise 'num' (int ou double) puis convertit en double.
    num priceAsNum = json['total_price'] ?? 0;
    double finalPrice = priceAsNum.toDouble();

    return Commande(
      transactionReference: json['transaction_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: lat,
      longitude: lng,
      totalPrice: finalPrice, 
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      productsSummary: json['products_summary'] as String,
    );
  }
}

// -----------------------------------------------------------------
// WIDGET PRINCIPAL (OrdersPage)
// -----------------------------------------------------------------

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // ⚠️ ADAPTEZ CES URLS AVANT D'EXÉCUTER
  static const String _apiUrl = 'http://192.168.1.64/soko/api_order.php';
  static const String _updateApiUrl = 'http://192.168.1.64/soko/statut_order.php';

  late Future<List<Commande>> _futureOrders;
  
  // États pour les filtres
  DateTimeRange? _selectedDateRange; 
  String? _selectedStatusFilter; 
  
  // Options de statut
  final List<String> _statusOptions = ['Tous', 'EN COURS', 'TERMINER', 'ANNULER'];
  final List<String> _availableStatuses = ['EN COURS', 'TERMINER', 'ANNULER'];

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = _statusOptions.first; 
    _futureOrders = fetchOrders();
  }

  // --- LOGIQUE DE GESTION DES COMMANDES (Fetch/Update) ---

  Future<List<Commande>> fetchOrders() async {
    try {
      String url = _apiUrl;
      Uri uri = Uri.parse(url);
      
      Map<String, String> queryParams = {};

      // 1. Filtre par Date
      if (_selectedDateRange != null) {
        final startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        final endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }
      
      // 2. Filtre par Statut
      if (_selectedStatusFilter != null && _selectedStatusFilter!.toUpperCase() != 'TOUS') {
        queryParams['status'] = _selectedStatusFilter!.toUpperCase();
      }

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Commande.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des commandes. Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }

  Future<void> _updateOrderStatus(String transactionId, String newStatus) async {
    final response = await http.post(
      Uri.parse(_updateApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transaction_id': transactionId,
        'status': newStatus,
      }),
    );

    final responseJson = jsonDecode(response.body);
    
    if (mounted) {
      if (response.statusCode == 200 && responseJson['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseJson['message'] ?? 'Statut mis à jour avec succès!')),
        );
        setState(() {
          _futureOrders = fetchOrders();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la mise à jour: ${responseJson['message'] ?? 'Erreur inconnue'}')),
        );
      }
    }
  }

  // --- LOGIQUE D'INTERFACE UTILISATEUR (Filtre/Dialogues) ---

  Future<void> _selectDateRange() async {
    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      currentDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('fr', 'FR'),
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
        _futureOrders = fetchOrders();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _futureOrders = fetchOrders();
    });
  }

  void _showStatusUpdateDialog(Commande order) {
    String? selectedStatus = order.status; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mettre à jour Commande #${order.transactionReference}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Détermine la valeur initiale, en s'assurant qu'elle est dans la liste des options
              String? initialStatus = _availableStatuses.contains(order.status.toUpperCase()) 
                  ? order.status.toUpperCase() 
                  : null;

              return DropdownButtonFormField<String>(
                value: initialStatus,
                decoration: const InputDecoration(labelText: 'Nouveau Statut'),
                items: _availableStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirmer'),
              onPressed: selectedStatus == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      if (selectedStatus != null && selectedStatus != order.status) {
                        _updateOrderStatus(order.transactionReference, selectedStatus!);
                      }
                    },
            ),
          ],
        );
      },
    );
  }

  // --- FONCTIONS UTILITAIRES ---

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TERMINER':
      case 'CONFIRMED':
        return Colors.green;
      case 'EN COURS':
      case 'PENDING':
        return Colors.orange;
      case 'ANNULER':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  void _launchMap(double lat, double lng) async {
    final urlString = 'http://maps.google.com/maps?q=$lat,$lng';
    final uri = Uri.parse(urlString);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la carte.')),
        );
      }
    }
  }

  // --- WIDGET BUILD ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes',style: TextStyle(color: Colors.white),),
        backgroundColor: primaryYellow,
        actions: [
          // Filtre par Statut (Dropdown)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatusFilter,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                dropdownColor: const Color(0xFF2C3E50),
                items: _statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatusFilter = newValue;
                      _futureOrders = fetchOrders(); 
                    });
                  }
                },
              ),
            ),
          ),
          // Filtre par Date
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDateRange,
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearDateRange,
              tooltip: 'Annuler le filtre de date',
            ),
        ],
      ),
      body: Column(
        children: [
          // Affichage des filtres actifs
          if (_selectedDateRange != null || (_selectedStatusFilter != null && _selectedStatusFilter!.toUpperCase() != 'TOUS'))
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedDateRange != null)
                    Expanded(
                      child: Text(
                        'Date: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_selectedStatusFilter != null && _selectedStatusFilter!.toUpperCase() != 'TOUS')
                    Expanded(
                      child: Text(
                        'Statut: ${_selectedStatusFilter}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(_selectedStatusFilter!), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _futureOrders = fetchOrders();
                });
              },
              child: FutureBuilder<List<Commande>>(
                future: _futureOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucune commande trouvée.'));
                  } else {
                    final orders = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Référence: ${order.transactionReference}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF007BFF)),
                                    ),
                                    // BOUTON DE MODIFICATION DU STATUT
                                    ElevatedButton.icon(
                                      onPressed: () => _showStatusUpdateDialog(order),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Statut'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                
                                // Client, Adresse, Carte
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.person, size: 20, color: Colors.blueGrey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(order.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(order.address, style: const TextStyle(fontSize: 14)),
                                          if (order.latitude != null && order.longitude != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: OutlinedButton.icon(
                                                onPressed: () => _launchMap(order.latitude!, order.longitude!),
                                                icon: const Icon(Icons.map, size: 18),
                                                label: const Text('Voir la carte'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.teal,
                                                  side: const BorderSide(color: Colors.teal),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 10),
                                
                                // Statut et Montant
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Statut:', style: TextStyle(color: Colors.grey)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            order.status.toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(order.status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Montant Total:', style: TextStyle(color: Colors.grey)),
                                        Text(
                                          NumberFormat.currency(locale: 'fr_CD', symbol: '\$').format(order.totalPrice),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        Text(
                                          'Paiement: ${order.paymentMethod}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 10),
                                
                                // Articles et Date
                                const Text('Articles Commandés:', style: TextStyle(color: Colors.grey)),
                                Text(
                                  order.productsSummary,
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 5),

                                Text(
                                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toLocal())}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}