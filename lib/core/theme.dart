import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color bgDark = Color(0xFF0F172A);      // Slate 900
  static const Color cardDark = Color(0xFF1E293B);    // Slate 800
  static const Color cardBorder = Color(0xFF334155);  // Slate 700
  
  static const Color primaryEmerald = Color(0xFF10B981); // Emerald 500
  static const Color primaryCyan = Color(0xFF06B6D4);    // Cyan 500
  static const Color accentPurple = Color(0xFF8B5CF6);   // Violet 500
  
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static const LinearGradient walletGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient quickPayGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryEmerald,
      cardColor: cardDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        secondary: primaryCyan,
        surface: cardDark,
        background: bgDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textWhite, fontWeight: FontWeight.bold, fontSize: 32),
        titleLarge: GoogleFonts.outfit(color: textWhite, fontWeight: FontWeight.w600, fontSize: 20),
        bodyMedium: GoogleFonts.inter(color: textMuted, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(color: textWhite, fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }
}
