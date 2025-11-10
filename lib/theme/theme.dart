import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black87,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ), // old headline6
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ), // old bodyText2
      titleMedium: TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ), // old subtitle1
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white70,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white70,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.white70),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      titleMedium: TextStyle(fontSize: 14, color: Colors.white54),
    ),
  );
}
