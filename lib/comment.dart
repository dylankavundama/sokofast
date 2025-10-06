import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:soko/services.dart';
import 'package:soko/Auth/LoginPage.dart';
import 'package:html_unescape/html_unescape.dart';
class CommentSection extends StatefulWidget {
  final int productId;

  const CommentSection({required this.productId, super.key});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late Future<List<Comment>> futureComments;
  final TextEditingController commentController = TextEditingController();
  int rating = 5;
  bool isSubmitting = false;
  final bool _isLoggedIn = true;
  //String? _loggedInUsername;

  static const Duration apiTimeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    futureComments = fetchComments(widget.productId);
    // No need to clear or refresh here, as it's for initial load
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // --- New function to clear the comment input field ---
  void _clearCommentField() {
    setState(() {
      commentController.clear();
    });
  }
  // ---------------------------------------------------

  Future<void> postComment(
      int productId, String userName, String comment, int rating) async {
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire votre commentaire')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/add_comment.php'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'product_id': productId,
              'user_name': userName,
              'comment': comment,
              'rating': rating,
            }),
          )
          .timeout(apiTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commentaire envoyé avec succès!')),
          );
        }
        await _refreshComments(); // This refreshes the comment list
        _clearCommentField(); // This clears the input field
      } else {
        throw Exception(
            responseData['message'] ?? 'Échec de l\'envoi du commentaire');
      }
    } on http.ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion: ${e.message}')),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temps d\'attente dépassé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
            '\nCommentaire envoyé avec succès!',
            textAlign: TextAlign.center,
          )),
        );
      }
    } finally {
      setState(() => isSubmitting = false);
    }

    _clearCommentField();
  }

  Future<List<Comment>> fetchComments(int productId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/comments.php?product_id=$productId'),
          )
          .timeout(apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception(
            'Échec du chargement des commentaires: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('La requête a pris trop de temps');
    } catch (e) {
      throw Exception(
          'Impossible de charger les commentaires: ${e.toString()}');
    }
  }

  Future<void> _refreshComments() async {
    setState(() {
      futureComments = fetchComments(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Commentaires')),
      body: RefreshIndicator(
        onRefresh: _refreshComments,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Comment List
              FutureBuilder<List<Comment>>(
                future: futureComments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _refreshComments,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucun commentaire pour ce produit'),
                    );
                  }

                  return Column(
                    children: snapshot.data!
                        .map((comment) => CommentCard(comment: comment))
                        .toList(),
                  );
                },
              ),

              const Divider(height: 33),

              // Conditional Comment Form
              if (_isLoggedIn && loggedInUserName != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ajouter un commentaire',
                      // en tant que ${loggedInUserName!}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        labelText: "Votre avis",
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        // --- Add clear button here ---
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearCommentField,
                        ),
                        // ------------------------------
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: rating,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(5, (i) => i + 1).map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Row(
                            children: [
                              Text("$r ", style: const TextStyle(fontSize: 16)),
                              Row(
                                children: List.generate(
                                  r,
                                  (_) => const Icon(Icons.star,
                                      color: Colors.amber, size: 18),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => rating = val!),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              await postComment(
                                widget.productId,
                                loggedInUserName!,
                                commentController.text,
                                rating,
                              );
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Envoyer"),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({required this.comment, super.key});

  @override
  
  Widget build(BuildContext context) {
   var unescape = HtmlUnescape();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < comment.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Text(
            //   comment.comment,
            //   style: GoogleFonts.abel(
            //       fontSize: 14), // prend en charge + de caractères
            // ),
            Text(unescape.convert(comment.comment),style: GoogleFonts.abel(
                fontSize: 14),),
            const SizedBox(height: 18),
            Text(
              'Posté le ${comment.createdAt}',
              style: GoogleFonts.roboto(
            //    fontSize: 12,
                color: Colors.grey,
              ),
              //   style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class Comment {
  final String userName;
  final String comment;
  final int rating;
  final String createdAt;

  Comment({
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      userName: json['user_name'] ?? 'Anonyme',
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 0,
      createdAt: json['created_at'] ?? 'Date inconnue',
    );
  }
}
