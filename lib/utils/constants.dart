import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App constants including colors, text styles, and dimensions.
///
/// Uses a refined food-themed color palette with warm tones for
/// psychological impact — creates a cozy, appetizing feel.
class AppConstants {
  AppConstants._();

  // ============== COLORS ==============

  /// Primary warm terracotta color — appetizing and inviting
  static const Color primaryColor = Color(0xFFE07B39);

  /// Darker primary for hover/pressed states
  static const Color primaryDark = Color(0xFFBC5D2E);

  /// Lighter primary for subtle backgrounds
  static const Color primaryLight = Color(0xFFFFF3EB);

  /// Secondary olive green — natural, fresh feel
  static const Color secondaryColor = Color(0xFF6B7B3C);

  /// Warm beige background — cozy and rustic
  static const Color backgroundColor = Color(0xFFF7F3EE);

  /// Dark brown for text — earthy and readable
  static const Color textPrimary = Color(0xFF2D1810);

  /// Medium brown for secondary text
  static const Color textSecondary = Color(0xFF6B5B50);

  /// Muted text for hints/placeholders
  static const Color textMuted = Color(0xFF9E8E82);

  /// Light beige for cards
  static const Color cardColor = Color(0xFFFFFCF9);

  /// Error/complaint red
  static const Color errorColor = Color(0xFFD32F2F);

  /// Success green
  static const Color successColor = Color(0xFF2E7D32);

  /// Warning amber
  static const Color warningColor = Color(0xFFF9A825);

  /// Info blue
  static const Color infoColor = Color(0xFF1565C0);

  /// Gradient colors for login screen
  static const Color gradientStart = Color(0xFFE07B39);
  static const Color gradientMiddle = Color(0xFFBC5D2E);
  static const Color gradientEnd = Color(0xFF6B7B3C);

  /// Pool type colors
  static const Color snackPoolColor = Color(0xFFFFB74D);
  static const Color fruitPoolColor = Color(0xFF81C784);
  static const Color proteinPoolColor = Color(0xFFFFCC80);

  // ============== GRADIENTS ==============

  /// Main app gradient
  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  /// Premium header gradient
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE07B39), Color(0xFFD4692F), Color(0xFFC05525)],
  );

  /// Card gradient for subtle depth
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFCF9), Color(0xFFF7F0E8)],
  );

  /// Surface gradient for elevated surfaces
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F3EE), Color(0xFFEFE8DF)],
  );

  // ============== TEXT STYLES ==============

  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle headingSmall = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.2,
  );

  // ============== DIMENSIONS ==============

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ============== SHADOWS ==============

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF2D1810).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF2D1810).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: const Color(0xFFE07B39).withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF2D1810).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  // ============== ANIMATIONS ==============

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Curve animCurve = Curves.easeOutCubic;
}

/// App theme data built from constants
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.cardColor,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide:
              const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
          borderSide:
              const BorderSide(color: AppConstants.errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppConstants.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppConstants.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.textSecondary,
        indicatorColor: AppConstants.primaryColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE6DD),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
