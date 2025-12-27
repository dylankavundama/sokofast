import 'package:flutter/widgets.dart';

/// Localisations simples FR / EN sans génération de code.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'language_title': 'Choose your language',
      'language_subtitle': 'You can change it later in settings.',
      'language_french': 'French',
      'language_english': 'English',
      'language_continue': 'Continue',

      'splash_from': 'From',
      'splash_company': 'Next Byte Technology',

      'onb1_title': 'Welcome to SOKO FAST',
      'onb1_desc':
          'Discover our large selection of gadgets, computers and high‑tech accessories.',
      'onb2_title': 'Technology at your fingertips',
      'onb2_desc':
          'Browse easily and find the devices that match your lifestyle in a few taps.',
      'onb3_title': 'Fast and secure delivery',
      'onb3_desc':
          'Receive your latest tech products at home, quickly and safely.',
      'onb_skip': 'Skip',
      'onb_next': 'Next',
      'onb_start': 'Get started',

      // Navigation bottom bar
      'nav_home': 'Home',
      'nav_categories': 'Categories',
      'nav_profile': 'Profile',

      // Login
      'login_title': 'Welcome',
      'login_subtitle': 'Sign in to continue',
      'login_google': 'Sign in with Google',
      'login_apple': 'Sign in with Apple',
      'login_progress': 'Signing in...',
      'login_session_info':
          'Your session will be saved for automatic reconnection',
      'login_error_account_exists': 'An account already exists with this email.',
      'login_error_invalid_credential': 'Invalid credentials. Please try again.',
      'login_error_user_disabled': 'This account has been disabled.',
      'login_error_user_not_found': 'No account found with this email.',
      'login_error_wrong_password': 'Incorrect password.',
      'login_error_generic': 'Login failed. Please try again.',
      'login_error_google_failed': 'Google sign-in failed. Please try again.',
      'login_error_apple_failed': 'Apple sign-in failed. Please try again.',
      'login_apple_connecting': 'Connecting...',
      'login_apple_button': 'Sign in with Apple',

      // Splash
      'splash_create_account_title': 'Create an account',
      'splash_create_account_content': 'Would you like to create an account to place orders?',
      'splash_no': 'No',
      'splash_yes': 'Yes',

      // Product list
      'product_search_hint': 'Search...',
      'product_empty_search': 'No products found for this search.',
      'product_empty': 'No products are available.',
      'offline_mode': 'Offline mode enabled. Data may be outdated.',
      'offline_error':
          'Connection error and no local data available.',

      // Categories
      'categories_title': 'Categories',
      'categories_empty': 'No category available.',

      // Product detail
      'product_add_to_cart': 'Add to cart',
      'product_description': 'Description',
      'product_no_description': 'No description available',
      'product_quantity': 'Quantity:',
      'product_total': 'Total:',
      'product_to_cart': 'Cart',
      'product_added_to_cart': 'Added to cart',
      'product_login_required':
          'Please log in to add to cart.',
      'product_order_placed': 'Order placed',
      'product_order_failed': 'Failed to send order',
      'product_network_error': 'Network error',
      'product_order_complete': 'Complete order',
      'product_your_name': 'Your name',
      'product_your_address': 'Your address',
      'product_order_summary': 'Product: {name}\nQuantity: {quantity}\nTotal: {total} \$',
      'product_choose_payment': 'Choose payment method:',
      'product_fill_name_address': 'Please fill in the name and address',
      'product_payment_method': 'Payment method',
      'product_payment_number': 'Number: {number}',
      'product_number_copied': '{method} number copied',
      'product_transaction_id': 'Transaction ID',
      'product_transaction_id_hint': 'Enter transaction code',
      'product_enter_transaction_id': 'Please enter the transaction ID',
      'product_confirm_order': 'Confirm order',
      'product_whatsapp_message': 'Hello, my name is {name}.\n\nI would like to order:\n{product}\nQuantity: {quantity}\nUnit price with markup: {price} \$\n\nTotal: {total} \$\n\nAddress: {address}',
      'product_could_not_open_whatsapp': 'Could not open WhatsApp',
      'product_comments_tab': 'Comments',
      'product_description_tab': 'Description',

      // Cart
      'cart_title': 'My Cart',
      'cart_empty': 'Your cart is empty',
      'cart_all_fees_included': 'All fees included',
      'cart_total_final': 'Final Total:',
      'cart_whatsapp': 'WhatsApp',
      'cart_mobile_money': 'Mobile Money',
      'cart_deleted': 'Product removed from cart',
      'cart_loading_position': 'Searching GPS position...',
      'cart_gps_ok': 'GPS position acquired:',
      'cart_gps_unavailable':
          'GPS position unavailable. Please enter the address.',
      'cart_retry_gps': 'Retry GPS location',
      'cart_address_label': 'Your delivery address (if no GPS)',
      'cart_address_hint': 'e.g. 123 Peace Street',
      'cart_phone_label': 'Mobile Money number (e.g. 243812345678)',
      'cart_phone_hint': '243xxxxxxxxx',
      'cart_dialog_title': 'Address and Contact',
      'cart_dialog_cancel': 'Cancel',
      'cart_dialog_confirm': 'Confirm',
      'cart_need_address_or_gps':
          'Please fill in the address or enable GPS.',
      'cart_invalid_phone':
          'Mobile Money phone number missing or invalid (243xxxxxxxx).',
      'cart_invalid_phone_format': 'Invalid phone number format (Ex: 243812345678).',
      'cart_address_not_found': 'Delivery address not found. Please enable GPS or refine the address.',
      'cart_total_zero': 'The total amount is zero or negative.',
      'cart_payment_initiated': 'Payment initiated. Please validate the request on your phone (number: {phone}).',
      'cart_flexpay_failed': 'FlexPay payment initiation failed: {message}',
      'cart_unexpected_error': 'Unexpected error: {error}',
      'cart_order_send_failed': 'Failed to send order to server: {code}',
      'cart_order_success': 'Your order has been processed successfully!',
      'cart_order_process_error': 'Error: Unable to process order. {error}',
      'cart_whatsapp_message': 'Hello, I would like to place an order:',
      'cart_whatsapp_product_line': '- {name} : {quantity} piece(s) at {price} \$ each',
      'cart_whatsapp_total': 'Final total to pay: {total} \$',
      'cart_whatsapp_delivery': 'Delivery address: {address}',
      'cart_whatsapp_contact': 'My contact: {phone}',
      'cart_whatsapp_map_link': 'Map link: {link}',
      'cart_whatsapp_gps_unavailable': 'GPS coordinates: Not available (text address used)',
      'cart_could_not_open_whatsapp': 'Could not open WhatsApp',
      'cart_gps_searching': 'Searching GPS position...',
      'cart_gps_acquired': 'GPS position acquired: {lat}, {lon}',
      'cart_gps_unavailable_text': 'GPS position unavailable. Please enter the address.',
      'cart_retry_gps_location': 'Retry GPS location',

      // Orders history
      'orders_title': 'My Orders',
      'orders_retry': 'Retry',
      'orders_empty': 'No order found',
      'orders_connected_as': 'Logged in as:',
      'orders_list_title': 'Order #',
      'orders_status': 'Status',
      'orders_payment_method': 'Payment method',
      'orders_address': 'Address',
      'orders_products_details': 'Products details:',
      'orders_total': 'Order total',
      'orders_must_login': 'You must be logged in to view your orders.',
      'orders_not_found_message': 'No order found.',
      'orders_server_error': 'Server error ({code})',
      'orders_connection_error': 'Connection error: {error}',
      'orders_not_found': 'No order found',
      'orders_order_number': 'Order #{id}',

      // My products
      'my_products_title': 'My Products',
      'my_products_error_loading': 'Loading error',
      'my_products_retry': 'Retry',
      'my_products_none': 'No product',
      'my_products_none_desc': 'You have not created any products yet',
      'my_products_create_first': 'Create my first product',
      'my_products_connected_as': 'Logged in as:',
      'my_products_refresh': 'Refresh',
      'my_products_add': 'Add product',
      'my_products_clear_cache': 'Clear cache',
      'my_products_logout': 'Logout',
      'my_products_cache_cleared': 'Cache cleared',
      'my_products_cannot_delete':
          'You cannot delete this product',
      'my_products_confirm_delete_title': 'Confirm deletion',
      'my_products_confirm_delete_content':
          'Are you sure you want to delete',
      'my_products_cancel': 'Cancel',
      'my_products_delete': 'Delete',
      'my_products_deleted': 'deleted successfully',
      'my_products_no_user': 'No user connected',
      'my_products_user_error': 'Error loading user data',
      'my_products_please_login': 'Please log in',
      'my_products_offline_cache': '⚠️ Offline mode - cached data',
      'my_products_cannot_delete_product': '❌ You cannot delete this product',
      'my_products_confirm_delete_question': 'Are you sure you want to delete "{name}"?',
      'my_products_logout_question': 'Are you sure you want to log out?',
      'my_products_clear_cache_text': 'Clear cache',
      'my_products_logout_text': 'Logout',
      'my_products_loading': 'Loading your products...',
      'my_products_no_image': 'No image',
      'my_products_created_on': 'Created on {date}',
      'my_products_list_refreshed': 'List refreshed.',
      'my_products_edit': 'Edit',
      'my_products_delete_text': 'Delete',

      // Profile
      'profile_title': 'My Profile',
      'profile_user_label': 'User',
      'profile_my_products': 'My Products',
      'profile_my_orders': 'My Orders',
      'profile_my_cart': 'My Cart',
      'profile_support': 'Customer Service',
      'profile_share_app': 'Share the app',
      'profile_invite_friends': 'Invite friends',
      'profile_delivery': 'Delivery',
      'profile_logout': 'Logout',
      'profile_change_language': 'Change language',
      'profile_change_name': 'Change name',
      'profile_save': 'Save',
      'profile_name_updated': 'Username updated successfully!',
      'profile_name_update_error': 'Error: Unable to update name. {error}',
      'profile_support_title': 'Customer Service',
      'profile_support_content': 'How would you like to contact our customer service?',
      'profile_send_email': 'Send an email',
      'profile_make_call': 'Make a call',
      'profile_send_whatsapp': 'Send a WhatsApp',
      'profile_settings': 'Settings',

      // Add product
      'add_title': 'Add a product',
      'add_name_label': 'Product name',
      'add_name_required': 'Name required',
      'add_price_label': 'Price',
      'add_price_required': 'Price required',
      'add_description_label': 'Description',
      'add_category_label': 'Product category:',
      'add_category_hint': 'Select a category',
      'add_category_required': 'Category required',
      'add_pick_image': 'Choose an image',
      'add_change_image': 'Change image',
      'add_publishing': 'Publishing...',
      'add_create_button': 'Create product',

      // Products by category
      'category_no_products': 'No products in this category',

      // Edit product
      'edit_title': 'Edit: {name}',
      'edit_product_name': 'Product name',
      'edit_name_required': 'Name required',
      'edit_price': 'Price',
      'edit_price_required': 'Price required',
      'edit_description': 'Description',
      'edit_save_changes': 'Save changes',
      'edit_product_updated': '✅ Product updated!',
      'edit_update_failed': '❌ Update failed.',
      'edit_error': 'Error: {error}',

      // Admin - Login livreur
      'admin_login_error': 'Error: Unauthorized user ID.',
      'admin_login_instruction': 'Please enter your ID to access orders.',
      'admin_login_id_label': 'Your ID',
      'admin_login_id_hint': 'Ex: Liv_Billy',
      'admin_login_access': 'Access',

      // Admin - Orders
      'admin_orders_title': 'Order Management',
      'admin_filter_status': 'Filter by Status',
      'admin_connection_error': 'Connection error to orders: {error}',
      'admin_load_failed': 'Failed to load orders: {code}',
      'admin_status_updated': 'Status updated to {status}.',
      'admin_update_failed': 'Update failed: {message}',
      'admin_network_error': 'Network error during update: {error}',
      'admin_could_not_open_map': 'Could not open map for {lat}, {lon}',
      'admin_client_phone_not_found': 'Client phone number not found for this order.',
      'admin_could_not_open_whatsapp': 'Could not open WhatsApp for number {phone}.',
      'admin_whatsapp_error': 'Error launching WhatsApp: {error}',
      'admin_whatsapp_message': 'Hello, I am contacting you regarding your order #{id}. It is currently at status: {status}.',

      // Theme
      'theme_title': 'Theme',
      'theme_light': 'Light mode',
      'theme_dark': 'Dark mode',
      'theme_system': 'System default',
      'theme_changed': 'Theme changed to {theme}',

      // Comments
      'comment_write_comment': 'Please write your comment',
      'comment_sent_success': 'Comment sent successfully!',
      'comment_connection_error': 'Connection error: {error}',
      'comment_timeout': 'Timeout exceeded',
      'comment_load_failed': 'Failed to load comments: {code}',
      'comment_request_timeout': 'The request took too long',
      'comment_cannot_load': 'Unable to load comments: {error}',
      'comment_error': 'Error: {error}',
      'comment_retry': 'Retry',
      'comment_no_comments': 'No comments for this product',
      'comment_add_comment': 'Add a comment',
      'comment_your_review': 'Your review',
      'comment_rating': 'Rating',
      'comment_send': 'Send',
      'comment_posted_on': 'Posted on {date}',
      'comment_anonymous': 'Anonymous',
      'comment_unknown_date': 'Unknown date',
      'comment_send_failed': 'Failed to send comment',

      // Admin Order
      'admin_chat': 'Chat',
      'admin_client': 'Client: {name}',
      'admin_total': 'Total: {total} \$',
      'admin_products': 'Products: {summary}',
      'admin_current_status': 'Current status: {status}',
      'admin_payment_method': 'Payment method',
      'admin_order_id': 'ID: {id}',
      'admin_status_all': 'All',
      'admin_status_in_progress': 'In progress',
      'admin_status_completed': 'Completed',
      'admin_status_cancelled': 'Cancelled',
      'admin_server_error': 'Server error',

      // My Products - Additional
      'my_products_deleted_success': '✅ "{name}" deleted successfully',
      'my_products_error_prefix': '❌ Error:',
      'my_products_default_user': 'User',
      'my_products_count': '{count} product(s)',
      'my_products_no_name': 'No name',

      // Add Product - Additional
      'add_category_load_failed': 'Failed to load categories: {code}',
      'add_category_error': 'Error loading categories. Check WC keys.',
      'add_image_upload_error': 'Image upload error: {message}',
      'add_category_required_warning': '⚠️ Please select a category.',
      'add_image_upload_failed': 'Image upload failed. Product creation stopped.',
      'add_product_created_with_image': '✅ Product created with image!',
      'add_product_created_without_image': '✅ Product created without image.',
      'add_product_creation_error': 'Product creation error: {message}',
      'add_publication_error': 'Publication error: {error}',
    },
    'fr': {
      'language_title': 'Choisissez votre langue',
      'language_subtitle': 'Vous pourrez la changer plus tard dans les réglages.',
      'language_french': 'Français',
      'language_english': 'Anglais',
      'language_continue': 'Continuer',

      'splash_from': 'From',
      'splash_company': 'Next Byte Technology',

      'onb1_title': 'Bienvenue chez SOKO FAST',
      'onb1_desc':
          'Découvrez notre vaste sélection de gadgets, ordinateurs et accessoires high‑tech.',
      'onb2_title': 'Une technologie à portée de main',
      'onb2_desc':
          'Naviguez facilement et trouvez les appareils qui correspondent à votre style de vie en quelques clics.',
      'onb3_title': 'Livraison rapide et sécurisée',
      'onb3_desc':
          'Recevez vos derniers produits technologiques directement chez vous, rapidement et en toute sécurité.',
      'onb_skip': 'Sauter',
      'onb_next': 'Suivant',
      'onb_start': 'Commencer',

      // Navigation bottom bar
      'nav_home': 'Accueil',
      'nav_categories': 'Catégories',
      'nav_profile': 'Profil',

      // Login
      'login_title': 'Bienvenue',
      'login_subtitle': 'Connectez-vous pour continuer',
      'login_google': 'Se connecter avec Google',
      'login_apple': 'Se connecter avec Apple',
      'login_progress': 'Connexion en cours...',
      'login_session_info':
          'Votre session sera sauvegardée pour une reconnexion automatique',

      // Product list
      'product_search_hint': 'Rechercher...',
      'product_empty_search': 'Aucun produit trouvé pour cette recherche.',
      'product_empty': 'Aucun produit n\'est disponible.',
      'offline_mode':
          'Mode hors ligne activé. Données potentiellement obsolètes.',
      'offline_error':
          'Erreur de connexion et aucune donnée locale disponible.',

      // Categories
      'categories_title': 'Catégories',
      'categories_empty': 'Aucune catégorie disponible.',

      // Product detail
      'product_add_to_cart': 'Ajouter au panier',
      'product_description': 'Description',
      'product_no_description': 'Aucune description disponible',
      'product_quantity': 'Quantité :',
      'product_total': 'Total :',
      'product_to_cart': 'Panier',
      'product_added_to_cart': 'Ajouté au panier',
      'product_login_required':
          'Veuillez vous connecter pour ajouter au panier.',

      // Cart
      'cart_title': 'Mon Panier',
      'cart_empty': 'Votre panier est vide',
      'cart_all_fees_included': 'Tout frais inclus',
      'cart_total_final': 'Total Final :',
      'cart_whatsapp': 'WhatsApp',
      'cart_mobile_money': 'Mobile Money',
      'cart_deleted': 'Produit supprimé du panier',
      'cart_loading_position': 'Recherche de la position GPS...',
      'cart_gps_ok': 'Position GPS acquise :',
      'cart_gps_unavailable':
          'Position GPS indisponible. Veuillez saisir l\'adresse.',
      'cart_retry_gps': 'Réessayer la localisation GPS',
      'cart_address_label': 'Votre adresse de livraison (si pas de GPS)',
      'cart_address_hint': 'Ex : 123 Rue de la Paix',
      'cart_phone_label': 'Numéro Mobile Money (Ex : 243812345678)',
      'cart_phone_hint': '243xxxxxxxxx',
      'cart_dialog_title': 'Adresse et Contact',
      'cart_dialog_cancel': 'Annuler',
      'cart_dialog_confirm': 'Confirmer',
      'cart_need_address_or_gps':
          'Veuillez remplir l\'adresse ou activer le GPS.',
      'cart_invalid_phone':
          'Numéro de téléphone FlexPay manquant ou invalide (243xxxxxxxx).',

      // Orders history
      'orders_title': 'Mes Commandes',
      'orders_retry': 'Réessayer',
      'orders_empty': 'Aucune commande trouvée',
      'orders_connected_as': 'Connecté en tant que :',
      'orders_list_title': 'Commande #',
      'orders_status': 'Status',
      'orders_payment_method': 'Méthode de paiement',
      'orders_address': 'Adresse',
      'orders_products_details': 'Détails des produits :',
      'orders_total': 'Total de la commande',

      // My products
      'my_products_title': 'Mes Produits',
      'my_products_error_loading': 'Erreur de chargement',
      'my_products_retry': 'Réessayer',
      'my_products_none': 'Aucun produit',
      'my_products_none_desc':
          'Vous n\'avez pas encore créé de produits',
      'my_products_create_first': 'Créer mon premier produit',
      'my_products_connected_as': 'Connecté en tant que :',
      'my_products_refresh': 'Actualiser',
      'my_products_add': 'Ajouter un produit',
      'my_products_clear_cache': 'Vider le cache',
      'my_products_logout': 'Déconnexion',
      'my_products_cache_cleared': 'Cache vidé',
      'my_products_cannot_delete':
          'Vous ne pouvez pas supprimer ce produit',
      'my_products_confirm_delete_title': 'Confirmer la suppression',
      'my_products_confirm_delete_content':
          'Êtes-vous sûr de vouloir supprimer',
      'my_products_cancel': 'Annuler',
      'my_products_delete': 'Supprimer',
      'my_products_deleted': 'supprimé avec succès',

      // Profile
      'profile_title': 'Mon Profil',
      'profile_user_label': 'Utilisateur',
      'profile_my_products': 'Mes Produits',
      'profile_my_orders': 'Mes Commandes',
      'profile_my_cart': 'Mon Panier',
      'profile_support': 'Service Client',
      'profile_share_app': 'Partager l\'application',
      'profile_invite_friends': 'Inviter des amis',
      'profile_delivery': 'Livreur',
      'profile_logout': 'Se déconnecter',
      'profile_change_language': 'Changer de langue',
      'profile_change_name': 'Changer le nom',
      'profile_save': 'Enregistrer',
      'profile_name_updated': 'Nom d\'utilisateur mis à jour avec succès!',
      'profile_name_update_error': 'Erreur: Impossible de mettre à jour le nom. {error}',
      'profile_support_title': 'Service Client',
      'profile_support_content': 'Comment souhaitez-vous contacter notre service client ?',
      'profile_send_email': 'Envoyer un email',
      'profile_make_call': 'Passer un appel',
      'profile_send_whatsapp': 'Envoyer un WhatsApp',
      'profile_settings': 'Paramètres',

      // Add product
      'add_title': 'Ajouter un produit',
      'add_name_label': 'Nom du produit',
      'add_name_required': 'Nom requis',
      'add_price_label': 'Prix',
      'add_price_required': 'Prix requis',
      'add_description_label': 'Description',
      'add_category_label': 'Catégorie du produit :',
      'add_category_hint': 'Sélectionnez une catégorie',
      'add_category_required': 'Catégorie requise',
      'add_pick_image': 'Choisir une image',
      'add_change_image': 'Changer l\'image',
      'add_publishing': 'Publication...',
      'add_create_button': 'Créer le produit',

      // Products by category
      'category_no_products': 'Aucun produit dans cette catégorie',

      // Edit product
      'edit_title': 'Modifier : {name}',
      'edit_product_name': 'Nom du produit',
      'edit_name_required': 'Nom requis',
      'edit_price': 'Prix',
      'edit_price_required': 'Prix requis',
      'edit_description': 'Description',
      'edit_save_changes': 'Sauvegarder les modifications',
      'edit_product_updated': '✅ Produit mis à jour!',
      'edit_update_failed': '❌ Échec de la mise à jour.',
      'edit_error': 'Erreur: {error}',

      // Admin - Login livreur
      'admin_login_error': 'Erreur : Identifiant d\'utilisateur non autorisé.',
      'admin_login_instruction': 'Veuillez entrer votre Identifiant pour accéder aux commandes.',
      'admin_login_id_label': 'Votre Identifiant',
      'admin_login_id_hint': 'Ex: Liv_Billy',
      'admin_login_access': 'Accéder',

      // Admin - Orders
      'admin_orders_title': 'Gestion des Commandes',
      'admin_filter_status': 'Filtrer par Statut',
      'admin_connection_error': 'Erreur de connexion aux commandes: {error}',
      'admin_load_failed': 'Échec du chargement des commandes: {code}',
      'admin_status_updated': 'Statut mis à jour à {status}.',
      'admin_update_failed': 'Échec de la mise à jour: {message}',
      'admin_network_error': 'Erreur réseau lors de la mise à jour: {error}',
      'admin_could_not_open_map': 'Impossible d\'ouvrir la carte pour {lat}, {lon}',
      'admin_client_phone_not_found': 'Numéro de client non trouvé pour cette commande.',
      'admin_could_not_open_whatsapp': 'Impossible d\'ouvrir WhatsApp pour le numéro {phone}.',
      'admin_whatsapp_error': 'Erreur lors du lancement de WhatsApp: {error}',
      'admin_whatsapp_message': 'Bonjour, je vous contacte au sujet de votre commande n° {id}. Elle est actuellement au statut : {status}.',

      // Theme
      'theme_title': 'Thème',
      'theme_light': 'Mode clair',
      'theme_dark': 'Mode sombre',
      'theme_system': 'Par défaut du système',
      'theme_changed': 'Thème changé en {theme}',

      // Comments
      'comment_write_comment': 'Veuillez écrire votre commentaire',
      'comment_sent_success': 'Commentaire envoyé avec succès!',
      'comment_connection_error': 'Erreur de connexion: {error}',
      'comment_timeout': 'Temps d\'attente dépassé',
      'comment_load_failed': 'Échec du chargement des commentaires: {code}',
      'comment_request_timeout': 'La requête a pris trop de temps',
      'comment_cannot_load': 'Impossible de charger les commentaires: {error}',
      'comment_error': 'Erreur: {error}',
      'comment_retry': 'Réessayer',
      'comment_no_comments': 'Aucun commentaire pour ce produit',
      'comment_add_comment': 'Ajouter un commentaire',
      'comment_your_review': 'Votre avis',
      'comment_rating': 'Note',
      'comment_send': 'Envoyer',
      'comment_posted_on': 'Posté le {date}',
      'comment_anonymous': 'Anonyme',
      'comment_unknown_date': 'Date inconnue',
      'comment_send_failed': 'Échec de l\'envoi du commentaire',

      // Admin Order
      'admin_chat': 'Chat',
      'admin_client': 'Client: {name}',
      'admin_total': 'Total: {total} \$',
      'admin_products': 'Produits: {summary}',
      'admin_current_status': 'Statut actuel: {status}',
      'admin_payment_method': 'Méthode de paiement',
      'admin_order_id': 'ID: {id}',
      'admin_status_all': 'Tous',
      'admin_status_in_progress': 'En cours',
      'admin_status_completed': 'Terminé',
      'admin_status_cancelled': 'Annulé',
      'admin_server_error': 'Erreur serveur',

      // My Products - Additional
      'my_products_deleted_success': '✅ "{name}" supprimé avec succès',
      'my_products_error_prefix': '❌ Erreur:',
      'my_products_default_user': 'Utilisateur',
      'my_products_count': '{count} produit(s)',
      'my_products_no_name': 'Sans nom',

      // Add Product - Additional
      'add_category_load_failed': 'Échec du chargement des catégories: {code}',
      'add_category_error': 'Erreur de chargement des catégories. Vérifiez les clés WC.',
      'add_image_upload_error': 'Erreur upload image: {message}',
      'add_category_required_warning': '⚠️ Veuillez sélectionner une catégorie.',
      'add_image_upload_failed': 'Échec de l\'upload d\'image. Arrêt de la création du produit.',
      'add_product_created_with_image': '✅ Produit créé avec image!',
      'add_product_created_without_image': '✅ Produit créé sans image.',
      'add_product_creation_error': 'Erreur création produit: {message}',
      'add_publication_error': 'Erreur de publication: {error}',
    },
  };

  String _t(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get languageTitle => _t('language_title');
  String get languageSubtitle => _t('language_subtitle');
  String get languageFrench => _t('language_french');
  String get languageEnglish => _t('language_english');
  String get languageContinue => _t('language_continue');

  String get splashFrom => _t('splash_from');
  String get splashCompany => _t('splash_company');

  String get onb1Title => _t('onb1_title');
  String get onb1Desc => _t('onb1_desc');
  String get onb2Title => _t('onb2_title');
  String get onb2Desc => _t('onb2_desc');
  String get onb3Title => _t('onb3_title');
  String get onb3Desc => _t('onb3_desc');
  String get onbSkip => _t('onb_skip');
  String get onbNext => _t('onb_next');
  String get onbStart => _t('onb_start');

  // Navigation
  String get navHome => _t('nav_home');
  String get navCategories => _t('nav_categories');
  String get navProfile => _t('nav_profile');

  // Login
  String get loginTitle => _t('login_title');
  String get loginSubtitle => _t('login_subtitle');
  String get loginGoogle => _t('login_google');
  String get loginApple => _t('login_apple');
  String get loginProgress => _t('login_progress');
  String get loginSessionInfo => _t('login_session_info');
  String get loginErrorAccountExists => _t('login_error_account_exists');
  String get loginErrorInvalidCredential => _t('login_error_invalid_credential');
  String get loginErrorUserDisabled => _t('login_error_user_disabled');
  String get loginErrorUserNotFound => _t('login_error_user_not_found');
  String get loginErrorWrongPassword => _t('login_error_wrong_password');
  String get loginErrorGeneric => _t('login_error_generic');
  String get loginErrorGoogleFailed => _t('login_error_google_failed');
  String get loginErrorAppleFailed => _t('login_error_apple_failed');
  String get loginAppleConnecting => _t('login_apple_connecting');
  String get loginAppleButton => _t('login_apple_button');

  // Splash
  String get splashCreateAccountTitle => _t('splash_create_account_title');
  String get splashCreateAccountContent => _t('splash_create_account_content');
  String get splashNo => _t('splash_no');
  String get splashYes => _t('splash_yes');

  // Product list
  String get productSearchHint => _t('product_search_hint');
  String get productEmptySearch => _t('product_empty_search');
  String get productEmpty => _t('product_empty');
  String get offlineMode => _t('offline_mode');
  String get offlineError => _t('offline_error');

  // Categories
  String get categoriesTitle => _t('categories_title');
  String get categoriesEmpty => _t('categories_empty');

  // Product detail
  String get productAddToCart => _t('product_add_to_cart');
  String get productDescription => _t('product_description');
  String get productNoDescription => _t('product_no_description');
  String get productQuantity => _t('product_quantity');
  String get productTotal => _t('product_total');
  String get productToCart => _t('product_to_cart');
  String get productAddedToCart => _t('product_added_to_cart');
  String get productLoginRequired => _t('product_login_required');
  String productOrderSummary(String name, int quantity, String total) => _t('product_order_summary').replaceAll('{name}', name).replaceAll('{quantity}', quantity.toString()).replaceAll('{total}', total);
  String get productOrderComplete => _t('product_order_complete');
  String get productYourName => _t('product_your_name');
  String get productYourAddress => _t('product_your_address');
  String get productChoosePayment => _t('product_choose_payment');
  String get productFillNameAddress => _t('product_fill_name_address');
  String get productPaymentMethod => _t('product_payment_method');
  String productPaymentNumber(String number) => _t('product_payment_number').replaceAll('{number}', number);
  String productNumberCopied(String method) => _t('product_number_copied').replaceAll('{method}', method);
  String get productTransactionId => _t('product_transaction_id');
  String get productTransactionIdHint => _t('product_transaction_id_hint');
  String get productEnterTransactionId => _t('product_enter_transaction_id');
  String get productConfirmOrder => _t('product_confirm_order');
  String productWhatsappMessage(String name, String product, int quantity, String price, String total, String address) => _t('product_whatsapp_message').replaceAll('{name}', name).replaceAll('{product}', product).replaceAll('{quantity}', quantity.toString()).replaceAll('{price}', price).replaceAll('{total}', total).replaceAll('{address}', address);
  String get productCouldNotOpenWhatsapp => _t('product_could_not_open_whatsapp');
  String get productCommentsTab => _t('product_comments_tab');
  String get productDescriptionTab => _t('product_description_tab');
  String get productOrderPlaced => _t('product_order_placed');
  String get productOrderFailed => _t('product_order_failed');
  String get productNetworkError => _t('product_network_error');

  // Cart
  String get cartTitle => _t('cart_title');
  String get cartEmpty => _t('cart_empty');
  String get cartAllFeesIncluded => _t('cart_all_fees_included');
  String get cartTotalFinal => _t('cart_total_final');
  String get cartWhatsapp => _t('cart_whatsapp');
  String get cartMobileMoney => _t('cart_mobile_money');
  String get cartDeleted => _t('cart_deleted');
  String get cartLoadingPosition => _t('cart_loading_position');
  String get cartGpsOk => _t('cart_gps_ok');
  String get cartGpsUnavailable => _t('cart_gps_unavailable');
  String get cartRetryGps => _t('cart_retry_gps');
  String get cartAddressLabel => _t('cart_address_label');
  String get cartAddressHint => _t('cart_address_hint');
  String get cartPhoneLabel => _t('cart_phone_label');
  String get cartPhoneHint => _t('cart_phone_hint');
  String get cartDialogTitle => _t('cart_dialog_title');
  String get cartDialogCancel => _t('cart_dialog_cancel');
  String get cartDialogConfirm => _t('cart_dialog_confirm');
  String get cartNeedAddressOrGps => _t('cart_need_address_or_gps');
  String get cartInvalidPhone => _t('cart_invalid_phone');
  String get cartInvalidPhoneFormat => _t('cart_invalid_phone_format');
  String get cartAddressNotFound => _t('cart_address_not_found');
  String get cartTotalZero => _t('cart_total_zero');
  String cartPaymentInitiated(String phone) => _t('cart_payment_initiated').replaceAll('{phone}', phone);
  String cartFlexpayFailed(String message) => _t('cart_flexpay_failed').replaceAll('{message}', message);
  String cartUnexpectedError(String error) => _t('cart_unexpected_error').replaceAll('{error}', error);
  String cartOrderSendFailed(String code) => _t('cart_order_send_failed').replaceAll('{code}', code);
  String get cartOrderSuccess => _t('cart_order_success');
  String cartOrderProcessError(String error) => _t('cart_order_process_error').replaceAll('{error}', error);
  String get cartWhatsappMessage => _t('cart_whatsapp_message');
  String cartWhatsappProductLine(String name, int quantity, String price) => _t('cart_whatsapp_product_line').replaceAll('{name}', name).replaceAll('{quantity}', quantity.toString()).replaceAll('{price}', price);
  String cartWhatsappTotal(String total) => _t('cart_whatsapp_total').replaceAll('{total}', total);
  String cartWhatsappDelivery(String address) => _t('cart_whatsapp_delivery').replaceAll('{address}', address);
  String cartWhatsappContact(String phone) => _t('cart_whatsapp_contact').replaceAll('{phone}', phone);
  String cartWhatsappMapLink(String link) => _t('cart_whatsapp_map_link').replaceAll('{link}', link);
  String get cartWhatsappGpsUnavailable => _t('cart_whatsapp_gps_unavailable');
  String get cartCouldNotOpenWhatsapp => _t('cart_could_not_open_whatsapp');
  String get cartGpsSearching => _t('cart_gps_searching');
  String cartGpsAcquired(String lat, String lon) => _t('cart_gps_acquired').replaceAll('{lat}', lat).replaceAll('{lon}', lon);
  String get cartGpsUnavailableText => _t('cart_gps_unavailable_text');
  String get cartRetryGpsLocation => _t('cart_retry_gps_location');

  // Orders
  String get ordersTitle => _t('orders_title');
  String get ordersRetry => _t('orders_retry');
  String get ordersEmpty => _t('orders_empty');
  String get ordersConnectedAs => _t('orders_connected_as');
  String get ordersListTitle => _t('orders_list_title');
  String get ordersStatus => _t('orders_status');
  String get ordersPaymentMethod => _t('orders_payment_method');
  String get ordersAddress => _t('orders_address');
  String get ordersProductsDetails => _t('orders_products_details');
  String get ordersTotal => _t('orders_total');
  String get ordersMustLogin => _t('orders_must_login');
  String get ordersNotFoundMessage => _t('orders_not_found_message');
  String ordersServerError(String code) => _t('orders_server_error').replaceAll('{code}', code);
  String ordersConnectionError(String error) => _t('orders_connection_error').replaceAll('{error}', error);
  String get ordersNotFound => _t('orders_not_found');
  String ordersOrderNumber(String id) => _t('orders_order_number').replaceAll('{id}', id);

  // My products
  String get myProductsTitle => _t('my_products_title');
  String get myProductsErrorLoading => _t('my_products_error_loading');
  String get myProductsRetry => _t('my_products_retry');
  String get myProductsNone => _t('my_products_none');
  String get myProductsNoneDesc => _t('my_products_none_desc');
  String get myProductsCreateFirst => _t('my_products_create_first');
  String get myProductsConnectedAs => _t('my_products_connected_as');
  String get myProductsRefresh => _t('my_products_refresh');
  String get myProductsAdd => _t('my_products_add');
  String get myProductsClearCache => _t('my_products_clear_cache');
  String get myProductsLogout => _t('my_products_logout');
  String get myProductsCacheCleared => _t('my_products_cache_cleared');
  String get myProductsCannotDelete => _t('my_products_cannot_delete');
  String get myProductsConfirmDeleteTitle =>
      _t('my_products_confirm_delete_title');
  String get myProductsConfirmDeleteContent =>
      _t('my_products_confirm_delete_content');
  String get myProductsCancel => _t('my_products_cancel');
  String get myProductsDelete => _t('my_products_delete');
  String get myProductsDeleted => _t('my_products_deleted');
  String get myProductsNoUser => _t('my_products_no_user');
  String get myProductsUserError => _t('my_products_user_error');
  String get myProductsPleaseLogin => _t('my_products_please_login');
  String get myProductsOfflineCache => _t('my_products_offline_cache');
  String get myProductsCannotDeleteProduct => _t('my_products_cannot_delete_product');
  String myProductsConfirmDeleteQuestion(String name) => _t('my_products_confirm_delete_question').replaceAll('{name}', name);
  String get myProductsLogoutQuestion => _t('my_products_logout_question');
  String get myProductsClearCacheText => _t('my_products_clear_cache_text');
  String get myProductsLogoutText => _t('my_products_logout_text');
  String get myProductsLoading => _t('my_products_loading');
  String get myProductsNoImage => _t('my_products_no_image');
  String myProductsCreatedOn(String date) => _t('my_products_created_on').replaceAll('{date}', date);
  String get myProductsListRefreshed => _t('my_products_list_refreshed');
  String get myProductsEdit => _t('my_products_edit');
  String get myProductsDeleteText => _t('my_products_delete_text');
  String myProductsDeletedSuccess(String name) => _t('my_products_deleted_success').replaceAll('{name}', name);
  String get myProductsErrorPrefix => _t('my_products_error_prefix');
  String get myProductsDefaultUser => _t('my_products_default_user');
  String myProductsCount(int count) => _t('my_products_count').replaceAll('{count}', count.toString());
  String get myProductsNoName => _t('my_products_no_name');

  // Profile
  String get profileTitle => _t('profile_title');
  String get profileUserLabel => _t('profile_user_label');
  String get profileMyProducts => _t('profile_my_products');
  String get profileMyOrders => _t('profile_my_orders');
  String get profileMyCart => _t('profile_my_cart');
  String get profileSupport => _t('profile_support');
  String get profileShareApp => _t('profile_share_app');
  String get profileInviteFriends => _t('profile_invite_friends');
  String get profileDelivery => _t('profile_delivery');
  String get profileLogout => _t('profile_logout');
  String get profileChangeLanguage => _t('profile_change_language');
  String get profileChangeName => _t('profile_change_name');
  String get profileSave => _t('profile_save');
  String get profileNameUpdated => _t('profile_name_updated');
  String profileNameUpdateError(String error) => _t('profile_name_update_error').replaceAll('{error}', error);
  String get profileSupportTitle => _t('profile_support_title');
  String get profileSupportContent => _t('profile_support_content');
  String get profileSendEmail => _t('profile_send_email');
  String get profileMakeCall => _t('profile_make_call');
  String get profileSendWhatsapp => _t('profile_send_whatsapp');
  String get profileSettings => _t('profile_settings');

  // Add product
  String get addProductTitle => _t('add_title');
  String get addNameLabel => _t('add_name_label');
  String get addNameRequired => _t('add_name_required');
  String get addPriceLabel => _t('add_price_label');
  String get addPriceRequired => _t('add_price_required');
  String get addDescriptionLabel => _t('add_description_label');
  String get addCategoryLabel => _t('add_category_label');
  String get addCategoryHint => _t('add_category_hint');
  String get addCategoryRequired => _t('add_category_required');
  String get addPickImage => _t('add_pick_image');
  String get addChangeImage => _t('add_change_image');
  String get addPublishing => _t('add_publishing');
  String get addCreateButton => _t('add_create_button');
  String addCategoryLoadFailed(String code) => _t('add_category_load_failed').replaceAll('{code}', code);
  String get addCategoryError => _t('add_category_error');
  String addImageUploadError(String message) => _t('add_image_upload_error').replaceAll('{message}', message);
  String get addCategoryRequiredWarning => _t('add_category_required_warning');
  String get addImageUploadFailed => _t('add_image_upload_failed');
  String get addProductCreatedWithImage => _t('add_product_created_with_image');
  String get addProductCreatedWithoutImage => _t('add_product_created_without_image');
  String addProductCreationError(String message) => _t('add_product_creation_error').replaceAll('{message}', message);
  String addPublicationError(String error) => _t('add_publication_error').replaceAll('{error}', error);

  // Products by category
  String get categoryNoProducts => _t('category_no_products');

  // Edit product
  String editTitle(String name) => _t('edit_title').replaceAll('{name}', name);
  String get editProductName => _t('edit_product_name');
  String get editNameRequired => _t('edit_name_required');
  String get editPrice => _t('edit_price');
  String get editPriceRequired => _t('edit_price_required');
  String get editDescription => _t('edit_description');
  String get editSaveChanges => _t('edit_save_changes');
  String get editProductUpdated => _t('edit_product_updated');
  String get editUpdateFailed => _t('edit_update_failed');
  String editError(String error) => _t('edit_error').replaceAll('{error}', error);

  // Admin - Login livreur
  String get adminLoginError => _t('admin_login_error');
  String get adminLoginInstruction => _t('admin_login_instruction');
  String get adminLoginIdLabel => _t('admin_login_id_label');
  String get adminLoginIdHint => _t('admin_login_id_hint');
  String get adminLoginAccess => _t('admin_login_access');

  // Admin - Orders
  String get adminOrdersTitle => _t('admin_orders_title');
  String get adminFilterStatus => _t('admin_filter_status');
  String adminConnectionError(String error) => _t('admin_connection_error').replaceAll('{error}', error);
  String adminLoadFailed(String code) => _t('admin_load_failed').replaceAll('{code}', code);
  String adminStatusUpdated(String status) => _t('admin_status_updated').replaceAll('{status}', status);
  String adminUpdateFailed(String message) => _t('admin_update_failed').replaceAll('{message}', message);
  String adminNetworkError(String error) => _t('admin_network_error').replaceAll('{error}', error);
  String adminCouldNotOpenMap(String lat, String lon) => _t('admin_could_not_open_map').replaceAll('{lat}', lat).replaceAll('{lon}', lon);
  String get adminClientPhoneNotFound => _t('admin_client_phone_not_found');
  String adminCouldNotOpenWhatsapp(String phone) => _t('admin_could_not_open_whatsapp').replaceAll('{phone}', phone);
  String adminWhatsappError(String error) => _t('admin_whatsapp_error').replaceAll('{error}', error);
  String adminWhatsappMessage(String id, String status) => _t('admin_whatsapp_message').replaceAll('{id}', id).replaceAll('{status}', status);
  String get adminChat => _t('admin_chat');
  String adminClient(String name) => _t('admin_client').replaceAll('{name}', name);
  String adminTotal(String total) => _t('admin_total').replaceAll('{total}', total);
  String adminProducts(String summary) => _t('admin_products').replaceAll('{summary}', summary);
  String adminCurrentStatus(String status) => _t('admin_current_status').replaceAll('{status}', status);
  String get adminPaymentMethod => _t('admin_payment_method');
  String adminOrderId(String id) => _t('admin_order_id').replaceAll('{id}', id);
  String get adminStatusAll => _t('admin_status_all');
  String get adminStatusInProgress => _t('admin_status_in_progress');
  String get adminStatusCompleted => _t('admin_status_completed');
  String get adminStatusCancelled => _t('admin_status_cancelled');
  String get adminServerError => _t('admin_server_error');

  // Theme
  String get themeTitle => _t('theme_title');
  String get themeLight => _t('theme_light');
  String get themeDark => _t('theme_dark');
  String get themeSystem => _t('theme_system');
  String themeChanged(String theme) => _t('theme_changed').replaceAll('{theme}', theme);

  // Comments
  String get commentWriteComment => _t('comment_write_comment');
  String get commentSentSuccess => _t('comment_sent_success');
  String commentConnectionError(String error) => _t('comment_connection_error').replaceAll('{error}', error);
  String get commentTimeout => _t('comment_timeout');
  String commentLoadFailed(String code) => _t('comment_load_failed').replaceAll('{code}', code);
  String get commentRequestTimeout => _t('comment_request_timeout');
  String commentCannotLoad(String error) => _t('comment_cannot_load').replaceAll('{error}', error);
  String commentError(String error) => _t('comment_error').replaceAll('{error}', error);
  String get commentRetry => _t('comment_retry');
  String get commentNoComments => _t('comment_no_comments');
  String get commentAddComment => _t('comment_add_comment');
  String get commentYourReview => _t('comment_your_review');
  String get commentRating => _t('comment_rating');
  String get commentSend => _t('comment_send');
  String commentPostedOn(String date) => _t('comment_posted_on').replaceAll('{date}', date);
  String get commentAnonymous => _t('comment_anonymous');
  String get commentUnknownDate => _t('comment_unknown_date');
  String get commentSendFailed => _t('comment_send_failed');
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}


