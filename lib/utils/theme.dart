import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color secondarySurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color borderLight;
  final Color borderMedium;
  final Color searchBackground;
  final Color searchText;
  final Color secondaryButtonBackground;
  final Color secondaryButtonBorder;
  final LinearGradient primaryGradient;
  final Color shadowColor;

  const AppThemeColors({
    required this.secondarySurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.borderLight,
    required this.borderMedium,
    required this.searchBackground,
    required this.searchText,
    required this.secondaryButtonBackground,
    required this.secondaryButtonBorder,
    required this.primaryGradient,
    required this.shadowColor,
  });

  @override
  AppThemeColors copyWith({
    Color? secondarySurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? borderLight,
    Color? borderMedium,
    Color? searchBackground,
    Color? searchText,
    Color? secondaryButtonBackground,
    Color? secondaryButtonBorder,
    LinearGradient? primaryGradient,
    Color? shadowColor,
  }) {
    return AppThemeColors(
      secondarySurface: secondarySurface ?? this.secondarySurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      borderLight: borderLight ?? this.borderLight,
      borderMedium: borderMedium ?? this.borderMedium,
      searchBackground: searchBackground ?? this.searchBackground,
      searchText: searchText ?? this.searchText,
      secondaryButtonBackground:
          secondaryButtonBackground ?? this.secondaryButtonBackground,
      secondaryButtonBorder:
          secondaryButtonBorder ?? this.secondaryButtonBorder,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      secondarySurface:
          Color.lerp(secondarySurface, other.secondarySurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderMedium: Color.lerp(borderMedium, other.borderMedium, t)!,
      searchBackground:
          Color.lerp(searchBackground, other.searchBackground, t)!,
      searchText: Color.lerp(searchText, other.searchText, t)!,
      secondaryButtonBackground: Color.lerp(
        secondaryButtonBackground,
        other.secondaryButtonBackground,
        t,
      )!,
      secondaryButtonBorder:
          Color.lerp(secondaryButtonBorder, other.secondaryButtonBorder, t)!,
      primaryGradient: LinearGradient(
        begin: t < 0.5 ? primaryGradient.begin : other.primaryGradient.begin,
        end: t < 0.5 ? primaryGradient.end : other.primaryGradient.end,
        colors: List.generate(
          primaryGradient.colors.length,
          (index) => Color.lerp(
            primaryGradient.colors[index],
            other.primaryGradient.colors[index],
            t,
          )!,
        ),
      ),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFF4F7CFF);
  static const Color primaryLight = Color(0xFF6D9CFF);
  static const Color primaryDark = Color(0xFF3A5AD9);

  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSecondarySurface = Color(0xFF111827);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  static const Color categoryMobile = Color(0xFFEEF2FF);
  static const Color categoryHeadphone = Color(0xFFFDF2F8);
  static const Color categoryTablet = Color(0xFFF0FDF4);
  static const Color categoryLaptop = Color(0xFFFEF3C7);
  static const Color categorySpeaker = Color(0xFFECFDF5);
  static const Color categoryMore = Color(0xFFF3F4F6);

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color darkBorderLight = Color(0xFF334155);
  static const Color darkBorderMedium = Color(0xFF475569);

  static AppThemeColors colors(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackground: background,
      cardColor: cardBackground,
      secondarySurface: surface,
      textPrimaryColor: textPrimary,
      textSecondaryColor: textSecondary,
      textDisabledColor: textMuted,
      dividerColor: borderLight,
      borderColor: borderMedium,
      searchBackground: const Color(0xFFF7FAFF),
      searchText: textPrimary,
      secondaryButtonBackground: surface,
      secondaryButtonBorder: borderLight,
      navBackground: surface,
      navActive: primaryColor,
      navInactive: textMuted,
      appBarBackground: surface,
      iconColor: textPrimary,
      shadowColor: Colors.black.withValues(alpha: 0.06),
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackground: darkBackground,
      cardColor: darkSurface,
      secondarySurface: darkSecondarySurface,
      textPrimaryColor: darkTextPrimary,
      textSecondaryColor: darkTextSecondary,
      textDisabledColor: darkTextMuted,
      dividerColor: darkBorderLight,
      borderColor: darkBorderMedium,
      searchBackground: darkSecondarySurface,
      searchText: darkTextPrimary,
      secondaryButtonBackground: darkSurface,
      secondaryButtonBorder: darkBorderLight,
      navBackground: darkSecondarySurface,
      navActive: primaryColor,
      navInactive: darkTextMuted,
      appBarBackground: darkSecondarySurface,
      iconColor: darkTextPrimary,
      shadowColor: Colors.black.withValues(alpha: 0.28),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color secondarySurface,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color textDisabledColor,
    required Color dividerColor,
    required Color borderColor,
    required Color searchBackground,
    required Color searchText,
    required Color secondaryButtonBackground,
    required Color secondaryButtonBorder,
    required Color navBackground,
    required Color navActive,
    required Color navInactive,
    required Color appBarBackground,
    required Color iconColor,
    required Color shadowColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: cardColor,
      primary: primaryColor,
      secondary: primaryLight,
      error: accentRed,
    );

    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primaryColor,
      cardColor: cardColor,
      canvasColor: navBackground,
      dividerColor: dividerColor,
      colorScheme: colorScheme,
      extensions: [
        AppThemeColors(
          secondarySurface: secondarySurface,
          textPrimary: textPrimaryColor,
          textSecondary: textSecondaryColor,
          textDisabled: textDisabledColor,
          borderLight: dividerColor,
          borderMedium: borderColor,
          searchBackground: searchBackground,
          searchText: searchText,
          secondaryButtonBackground: secondaryButtonBackground,
          secondaryButtonBorder: secondaryButtonBorder,
          primaryGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryLight],
          ),
          shadowColor: shadowColor,
        ),
      ],
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textDisabledColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: appBarBackground,
        foregroundColor: textPrimaryColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData(color: iconColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBackground,
        selectedItemColor: navActive,
        unselectedItemColor: navInactive,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: secondaryButtonBackground,
          foregroundColor: textPrimaryColor,
          side: BorderSide(color: secondaryButtonBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textDisabledColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight.withValues(alpha: 0.45);
          }
          return borderColor;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryButtonBackground,
        selectedColor: primaryColor,
        disabledColor: borderColor,
        side: BorderSide(color: secondaryButtonBorder),
        labelStyle: TextStyle(color: textPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textDisabledColor,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryColor,
        ),
      ),
    );
  }
}
