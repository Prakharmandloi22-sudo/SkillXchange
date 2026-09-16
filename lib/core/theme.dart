import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core Palette - "Deep Aurora"
  static const List<String> avatars = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Julian&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Milo&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Lilly&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Toby&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Kiki&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Zoe&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Max&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Jack&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Lucy&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Finn&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Sasha&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Kobe&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Nala&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Mochi&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Ruby&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Leo&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Luna&size=640',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Bruno&size=640',
  ];

  static const List<String> realPersonPhotos = [
    'https://randomuser.me/api/portraits/men/1.jpg', // Man
    'https://randomuser.me/api/portraits/women/1.jpg', // Woman
    'https://randomuser.me/api/portraits/men/2.jpg', // Man
    'https://randomuser.me/api/portraits/women/2.jpg', // Woman
    'https://randomuser.me/api/portraits/men/3.jpg', // Man
    'https://randomuser.me/api/portraits/women/3.jpg', // Woman
    'https://randomuser.me/api/portraits/men/4.jpg', // Man
    'https://randomuser.me/api/portraits/women/4.jpg', // Woman
    'https://randomuser.me/api/portraits/women/5.jpg', // Youthful woman
    'https://randomuser.me/api/portraits/men/6.jpg', // Professional man
    'https://randomuser.me/api/portraits/women/7.jpg', // Woman smiling
    'https://randomuser.me/api/portraits/women/8.jpg', // Woman portrait
    'https://randomuser.me/api/portraits/men/9.jpg', // Man portrait
    'https://randomuser.me/api/portraits/women/10.jpg', // Woman smiling
    'https://randomuser.me/api/portraits/men/11.jpg', // Man sitting
  ];

   static const Color background = Color(0xFF0F172A); // Deep Navy
   static const Color surface = Color(0xFF1E293B); 
   static const Color cardBackground = Color(0xFF1E293B); 
   static const Color cardBorder = Color(0xFF334155); 
 
   static const Color accent = Color(0xFFF43F5E); // Pulse Red (Previously Vivid Violet)
   static const Color neonCyan = Color(0xFF06B6D4); 
   static const Color neonMagenta = Color(0xFFEC4899); 
   static const Color coral = Color(0xFFF43F5E); 
   static const Color purple = Color(0xFF8B5CF6);
   static const Color deepAurora = Color(0xFF4F46E5);
 
   // Solar Gold Palette (Used by Logo)
   static const Color solarGold = Color(0xFFF59E0B);
   static const Color solarAmber = Color(0xFFFDE68A);
   static const Color solarOrange = Color(0xFFEA580C);
 
   static const Color textPrimary = Colors.white;
   static const Color textSecondary = Colors.white70;
   static const Color textMuted = Colors.white54;
 
   static const Gradient primaryGradient = LinearGradient(
     colors: [Color(0xFFF43F5E), Color(0xFFF59E0B)],
   );
   static const Gradient cosmicGradient = LinearGradient(
     colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
   );
   static const Gradient auroraGradient = LinearGradient(
     colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
   );
   static const Gradient glassGradient = LinearGradient(
     colors: [Colors.white12, Colors.white10],
   );
 }

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.neonCyan,
        onSecondary: Colors.black,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0C0C0C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.cardBackground,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
      ),
    );
  }
}

