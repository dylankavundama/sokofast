import 'package:flutter/material.dart';

/// Classe utilitaire pour gérer la responsivité de l'application
class Responsive {
  // Seuils de largeur pour différents types d'appareils
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;
  
  // Seuils de largeur pour les grilles
  static const double smallScreenWidth = 600;
  static const double mediumScreenWidth = 900;
  static const double largeScreenWidth = 1200;

  /// Vérifie si l'appareil est un téléphone
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Vérifie si l'appareil est une tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Vérifie si l'appareil est un desktop ou grande tablette
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Retourne le nombre de colonnes approprié pour une grille selon la taille de l'écran
  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < smallScreenWidth) {
      // Téléphone : 2 colonnes
      return 2;
    } else if (width < mediumScreenWidth) {
      // Petite tablette : 3 colonnes
      return 3;
    } else if (width < largeScreenWidth) {
      // Tablette moyenne : 4 colonnes
      return 4;
    } else {
      // Grande tablette/iPad Pro : 5 colonnes
      return 5;
    }
  }

  /// Retourne le nombre de colonnes pour les catégories
  static int getCategoryColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < smallScreenWidth) {
      return 2;
    } else if (width < mediumScreenWidth) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Retourne le padding horizontal adaptatif
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 48.0;
    }
  }

  /// Retourne le padding vertical adaptatif
  static double getVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  /// Retourne l'espacement entre les éléments de grille
  static double getGridSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Retourne le ratio d'aspect adaptatif pour les cartes de produits
  static double getProductAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 0.7;
    } else if (isTablet(context)) {
      return 0.75;
    } else {
      return 0.8;
    }
  }

  /// Retourne le ratio d'aspect adaptatif pour les catégories
  static double getCategoryAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 0.8;
    } else if (isTablet(context)) {
      return 0.85;
    } else {
      return 0.9;
    }
  }

  /// Retourne la largeur maximale pour le contenu centré (utile pour les tablettes)
  static double? getMaxContentWidth(BuildContext context) {
    if (isTablet(context) || isDesktop(context)) {
      return 1200.0; // Limiter la largeur sur les grandes écrans
    }
    return null; // Pas de limite sur mobile
  }

  /// Retourne la taille de police adaptative
  static double getAdaptiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.1;
    } else {
      return desktop ?? mobile * 1.2;
    }
  }

  /// Wrapper pour centrer le contenu sur les grandes écrans
  static Widget centerContent(BuildContext context, Widget child) {
    if (isTablet(context) || isDesktop(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: getMaxContentWidth(context) ?? double.infinity,
          ),
          child: child,
        ),
      );
    }
    return child;
  }
}

