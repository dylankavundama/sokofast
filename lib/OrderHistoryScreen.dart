import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:soko/services.dart'; // Assurez-vous que ce fichier contient `baseUrl`
import 'package:url_launcher/url_launcher.dart';

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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.displayName == null) {
      // Si l'utilisateur n'est pas connecté ou n'a pas de nom d'affichage
      setState(() {
        _isLoading = false;
        _errorMessage = 'Vous devez être connecté pour voir vos commandes.';
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
          setState(() {
            _errorMessage = json['message'] ?? 'Aucune commande trouvée.';
            orders = []; // S'assurer que la liste est vide en cas d'erreur
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur de serveur (${response.statusCode})';
          orders = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
        orders = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fonction utilitaire pour obtenir la couleur du statut.
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'annulé':
      case 'annuler':
        return Colors.red;
      case 'en cours':
        return Colors.orange;
      case 'terminé':
      case 'terminer':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
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
                        child: const Text('Réessayer'),
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
                          const Text(
                            'Aucune commande trouvée',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Connecté en tant que: ${loggedInUserName ?? ''}',
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
                          final status = order['status']?.toString() ?? 'Inconnu';

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
                                'Commande #${order['id']}',
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
                                      _buildInfoRow('Status', status, getStatusColor(status)),
                                      _buildInfoRow('Méthode de paiement', order['payment_method']),
                                      if (order['address'] != null)
                                        _buildInfoRow('Adresse', order['address']),
                                      
                                      // 💡 NOUVEAU : Informations du livreur
                                      if (order['livreur_id'] != null && order['livreur_nom'] != null)
                                        _buildLivreurSection(order),
                                      
                                      const SizedBox(height: 15),
                                      const Divider(),
                                      const Text(
                                        'Détails des produits:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 10),
                                      ...(order['productList'] as List)
                                          .map((product) {
                                            final productName = product['product_name'] ?? 'Produit inconnu';
                                            final quantity = product['quantity'] ?? 0;

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
                                          const Text(
                                            // 'Total de la commande (30% incl. ):',
                                                    'Total de la commande',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  Widget _buildInfoRow(String label, String? value, [Color? valueColor]) {
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
              value ?? 'Non spécifié',
              style: TextStyle(fontSize: 14, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 NOUVEAU : Section livreur avec contact et notation
  Widget _buildLivreurSection(Map<String, dynamic> order) {
    final livreurNom = order['livreur_nom'] ?? '';
    final livreurPrenom = order['livreur_prenom'] ?? '';
    final livreurTelephone = order['livreur_telephone'] ?? '';
    final livreurNoteMoyenne = order['livreur_note_moyenne'];
    final livreurId = order['livreur_id'];
    final transactionId = order['transaction_id'];
    final clientName = order['name'] ?? loggedInUserName ?? '';
    final status = order['status']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(),
        const Text(
          'Livreur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.motorcycle, size: 20, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$livreurPrenom $livreurNom',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (livreurNoteMoyenne != null)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final noteValue = (livreurNoteMoyenne is num) 
                              ? livreurNoteMoyenne.toDouble() 
                              : double.tryParse(livreurNoteMoyenne.toString()) ?? 0.0;
                          return Icon(
                            index < noteValue.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '(${livreurNoteMoyenne.toString()})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        // 💡 NOUVEAU : TextButton pour contacter le livreur
        if (livreurTelephone != null && livreurTelephone.toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => _launchWhatsAppLivreur(livreurTelephone.toString(), transactionId),
              icon: const Icon(Icons.chat, size: 18, color: Colors.green),
              label: const Text(
                'Contacter le livreur',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.green, width: 1),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        // 💡 NOUVEAU : Bouton pour noter le livreur (seulement si commande terminée)
        if (status.toLowerCase() == 'terminé' || status.toLowerCase() == 'terminer')
          FutureBuilder<Map<String, dynamic>>(
            future: _checkExistingNote(transactionId, clientName),
            builder: (context, snapshot) {
              final hasNote = snapshot.data?['has_note'] ?? false;
              final existingNote = snapshot.data?['note'];
              
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasNote ? Colors.blue : Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(
                  hasNote ? Icons.star : Icons.star_border,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  hasNote ? 'Modifier la note' : 'Noter le livreur',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: () => _showRatingDialog(
                  order,
                  livreurId,
                  transactionId,
                  clientName,
                  existingNote,
                ),
              );
            },
          ),
      ],
    );
  }

  // 💡 NOUVEAU : Vérifier si une note existe déjà
  Future<Map<String, dynamic>> _checkExistingNote(String transactionId, String clientName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_note_livreur.php?transaction_id=$transactionId&client_name=${Uri.encodeComponent(clientName)}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'has_note': data['has_note'] ?? false,
          'note': data['note'],
        };
      }
    } catch (e) {
      print('Erreur lors de la vérification de la note: $e');
    }
    return {'has_note': false, 'note': null};
  }

  // 💡 NOUVEAU : Lancer WhatsApp pour contacter le livreur
  Future<void> _launchWhatsAppLivreur(String telephone, String transactionId) async {
    final message = 'Bonjour, je vous contacte au sujet de ma commande n° $transactionId.';
    final url = Uri.parse(
      'https://api.whatsapp.com/send?phone=$telephone&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Impossible d'ouvrir WhatsApp pour le numéro $telephone."),
            ),
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

  // 💡 NOUVEAU : Dialog pour noter le livreur
  void _showRatingDialog(
    Map<String, dynamic> order,
    dynamic livreurId,
    String transactionId,
    String clientName,
    Map<String, dynamic>? existingNote,
  ) {
    int selectedRating = existingNote?['note'] != null 
        ? (existingNote!['note'] is int 
            ? existingNote['note'] 
            : int.tryParse(existingNote['note'].toString()) ?? 5)
        : 5;
    final TextEditingController commentController = TextEditingController(
      text: existingNote?['commentaire']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Noter le livreur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order['livreur_prenom']} ${order['livreur_nom']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Note:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitRating(
                  livreurId is int ? livreurId : int.tryParse(livreurId.toString()) ?? 0,
                  transactionId,
                  clientName,
                  selectedRating,
                  commentController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _fetchOrdersFromApi(); // Rafraîchir pour afficher la note
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 💡 NOUVEAU : Soumettre la note
  Future<void> _submitRating(
    int livreurId,
    String transactionId,
    String clientName,
    int note,
    String commentaire,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/noter_livreur.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'livreur_id': livreurId,
          'transaction_id': transactionId,
          'client_name': clientName,
          'note': note,
          'commentaire': commentaire,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note enregistrée avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Erreur lors de l\'enregistrement'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}