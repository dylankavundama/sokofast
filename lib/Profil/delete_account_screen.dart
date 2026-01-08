// delete_account_screen.dart - Écran de confirmation et suppression de compte

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soko/Profil/delete_account_service.dart';
import 'package:soko/l10n/app_localizations.dart';
import 'package:soko/utils/responsive.dart';

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
    final loc = AppLocalizations.of(context)!;
    
    if (user == null) {
      _showError(loc.deleteAccountNoUser);
      return;
    }

    // Vérifier que l'utilisateur a tapé "SUPPRIMER"
    if (_confirmController.text.trim().toUpperCase() != loc.deleteAccountKeyword) {
      _showError(loc.deleteAccountTypeConfirm);
      return;
    }

    // Afficher une dernière confirmation
    final bool? finalConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          loc.deleteAccountLastConfirmTitle,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          loc.deleteAccountLastConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.deleteAccountCancel),
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
                        title: Text(
                          loc.deleteAccountSuccessTitle,
                          style: const TextStyle(color: Colors.green),
                        ),
                        content: Text(
                          loc.deleteAccountSuccessContent,
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
                            child: Text(loc.deleteAccountOk),
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
                          title: Text(
                            loc.deleteAccountVerificationTitle,
                            style: const TextStyle(color: Colors.red),
                          ),
                          content: Text(
                            loc.deleteAccountVerificationContent,
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
                              child: Text(loc.deleteAccountOk),
                            ),
                          ],
                        ),
                      );
                    }
                    else{
                      _showError(result['message'] ?? loc.deleteAccountGenericError);
                    }
                  }
              } catch (e) {
                if (mounted) {
                  // _showError('Erreur: $e');

                  // Le message d'erreur ci-bas est beaucoup plus proche
                  // du language humain que celui de dessus (juste une suggestion)
                  _showError(loc.deleteAccountGenericError);
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                }
              }
            },
            child: Text(loc.deleteAccountButtonConfirm),
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: Text(
          loc.deleteAccountTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Responsive.centerContent(
        context,
        SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône d'avertissement
              Container(
                padding: EdgeInsets.all(Responsive.getHorizontalPadding(context) * 1.25),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: Responsive.isMobile(context) ? 64.0 : 80.0,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: Responsive.getVerticalPadding(context) * 3),

              // Titre
              Text(
                loc.deleteAccountWarningTitle,
                style: GoogleFonts.roboto(
                  fontSize: Responsive.getAdaptiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.getVerticalPadding(context) * 2),

            // Message d'avertissement
            Container(
              padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.deleteAccountWarningIntro,
                    style: GoogleFonts.roboto(
                      fontSize: Responsive.getAdaptiveFontSize(context, mobile: 16, tablet: 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  SizedBox(height: Responsive.getVerticalPadding(context) * 1.5),
                  Text(
                    loc.deleteAccountWarningListIntro,
                    style: TextStyle(
                      fontSize: Responsive.getAdaptiveFontSize(context, mobile: 14, tablet: 16),
                    ),
                  ),
                  SizedBox(height: Responsive.getVerticalPadding(context)),
                  _buildWarningItem(loc.deleteAccountWarningAccount),
                  _buildWarningItem(loc.deleteAccountWarningProducts),
                  _buildWarningItem(loc.deleteAccountWarningOrders),
                  _buildWarningItem(loc.deleteAccountWarningComments),
                  _buildWarningItem(loc.deleteAccountWarningPersonalData),
                  _buildWarningItem(loc.deleteAccountWarningHistory),
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
                      loc.deleteAccountAccountToDelete,
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
                            loc.deleteAccountWarningsLabel,
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
                          ,
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            // Champ de confirmation
            Text(
              loc.deleteAccountInputLabel,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: loc.deleteAccountInputHint,
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(loc.deleteAccountButtonProgress),
                      ],
                    )
                  : Text(
                      loc.deleteAccountButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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

