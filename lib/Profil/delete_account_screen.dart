// delete_account_screen.dart - Écran de confirmation et suppression de compte

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Auth/loginPage.dart';
import 'package:soko/Profil/delete_account_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  bool _hasChecked = false;
  Map<String, dynamic>? _checkResult;
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCanDelete();
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  /// Vérifie si l'utilisateur peut supprimer son compte
  Future<void> _checkCanDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _hasChecked = true;
    });

    final result = await DeleteAccountService.canDeleteAccount(
      firebaseUid: user.uid,
      email: user.email ?? '',
    );

    setState(() {
      _checkResult = result;
    });
  }

  /// Supprime le compte et toutes les données
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Aucun utilisateur connecté');
      return;
    }

    // Vérifier que l'utilisateur a tapé "SUPPRIMER"
    if (_confirmController.text.trim().toUpperCase() != 'SUPPRIMER') {
      _showError('Veuillez taper "SUPPRIMER" pour confirmer');
      return;
    }

    // Afficher une dernière confirmation
    final bool? finalConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '⚠️ Dernière Confirmation',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Cette action est IRRÉVERSIBLE. Toutes vos données seront définitivement supprimées :\n\n'
          '• Votre compte utilisateur\n'
          '• Tous vos produits (si vendeur)\n'
          '• Toutes vos commandes\n'
          '• Tous vos commentaires\n'
          '• Toutes vos données personnelles\n\n'
          'Êtes-vous ABSOLUMENT SÛR de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            // onPressed: () => Navigator.pop(context, true),
            onPressed: () async{

              setState(() {
                _isDeleting = true;
              });

              Navigator.pop(dialogContext);

              try {
                final result = await DeleteAccountService.deleteAccount(
                  firebaseUid: user.uid,
                  email: user.email ?? '',
                  // context: context,
                );

                if(!mounted) return;
                  if (result['success'] == true && result['success'] != null) {
                    // Afficher un message de succès
                     showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          '✅ Compte Supprimé',
                          style: TextStyle(color: Colors.green),
                        ),
                        content: const Text(
                          'Votre compte et toutes vos données ont été supprimés avec succès.',
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Rediriger vers la page de connexion
                              // Navigator.pushAndRemoveUntil(
                              //   context,
                              //   MaterialPageRoute(builder: (_) => LoginPage()),
                              //       (Route<dynamic> route) => false,
                              // );
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    if (result['errorCode'] == "requires-recent-login"){
                      print('❌ Cette opération requièrt une authentification récente');
                      showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text(
                            '⚠️ Vérification',
                            style: TextStyle(color: Colors.red),
                          ),
                          content: const Text(
                            'Veuillez vous déconnecter et vous reconnecter à nouveau pour supprimer \nvotre compte.\n\n'
                            'Rassurez-vous de vous reconnecter avec le meme compte pour le supprimer.'
                            ,
                          ),
                          actions: [
                            // TextButton(
                            //   onPressed: () => Navigator.pop(context),
                            //   child: const Text('Annuler'),
                            // ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async{
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                    else{
                      _showError(result['message'] ?? 'Erreur lors de la suppression');
                    }
                  }
              } catch (e) {
                if (mounted) {
                  // _showError('Erreur: $e');

                  // Le message d'erreur ci-bas est beaucoup plus proche
                  // du language humain que celui de dessus (juste une suggestion)
                  _showError('Une erreur est survenue');
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                }
              }
            },
            child: const Text('OUI, SUPPRIMER'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text(
          'Supprimer mon compte',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône d'avertissement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Attention !',
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message d'avertissement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'La suppression de votre compte est une action IRRÉVERSIBLE.',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Toutes les données suivantes seront définitivement supprimées :',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildWarningItem('Votre compte utilisateur'),
                  _buildWarningItem('Tous vos produits (si vous êtes vendeur)'),
                  _buildWarningItem('Toutes vos commandes'),
                  _buildWarningItem('Tous vos commentaires et avis'),
                  _buildWarningItem('Toutes vos données personnelles'),
                  _buildWarningItem('Votre historique d\'achats'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informations utilisateur
            if (user != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte à supprimer :',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}'),
                    Text('UID: ${user.uid.substring(0, 20)}...'),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Vérifications
            if (_hasChecked && _checkResult != null)
              if (_checkResult!['warnings'] != null &&
                  (_checkResult!['warnings'] as List).isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Avertissements :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(_checkResult!['warnings'] as List)
                          .map((warning) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $warning'),
                              ))
                          .toList(),
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            // Champ de confirmation
            Text(
              'Pour confirmer, tapez "SUPPRIMER" ci-dessous :',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: 'Tapez "SUPPRIMER"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),

            // Bouton de suppression
            ElevatedButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isDeleting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Suppression en cours...'),
                      ],
                    )
                  : const Text(
                      'SUPPRIMER MON COMPTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Bouton d'annulation
            OutlinedButton(
              onPressed: _isDeleting
                  ? null
                  : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.close, size: 16, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

