import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores principal
  static const Color primaryColor = Color(0xFF0F2C59);   // Azul Marino
  static const Color accentColor = Color(0xFFFF6B00);    // Naranja
  static const Color backgroundColor = Color(0xFFF8F9FA); // Fondo Claro
  static const Color surfaceColor = Colors.white;         // Blanco Tarjetas
  static const Color textPrimary = Color(0xFF1F2937);     // Texto Oscuro
  static const Color textSecondary = Color(0xFF6B7280);   // Texto Gris

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}