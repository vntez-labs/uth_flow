import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Claude Colors: iconic warm parchment light mode & deep warm charcoal dark mode
  static const Color _lightBg = Color(0xFFFAF9F5);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF1F1E1D);

  static const Color _darkBg = Color(0xFF1F1E1D);
  static const Color _darkSurface = Color(0xFF282724);
  static const Color _darkText = Color(0xFFECEAE2);

  // Màu xanh nhận diện thương hiệu của Trường ĐH Giao thông Vận tải TP.HCM (UTH)
  static const Color _primaryColor = Color(0xFF008689);

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Headline (Giờ giấc, số liệu)
      displayLarge: GoogleFonts.plusJakartaSans(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      // Body (Tên môn, chi tiết)
      bodyMedium: GoogleFonts.beVietnamPro(color: textColor),
      bodySmall: GoogleFonts.beVietnamPro(color: textColor),
      labelSmall: GoogleFonts.beVietnamPro(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // --- HÀM CORE ĐỂ THUẦN HÓA MATERIAL 3 ---
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color bgColor,
    required Color textColor,
  }) {
    // Ép toàn bộ ColorScheme không dùng surface tint
    final effectiveColorScheme = colorScheme.copyWith(
      surfaceTint: Colors.transparent,
    );

    final isDark = textColor == _darkText;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: effectiveColorScheme,
      textTheme: _buildTextTheme(textColor),

      // 1. CONFIG APPBAR
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor:
            Colors.transparent, // AppBarTheme thì có thuộc tính này
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      ),

      // 2. CONFIG CARD
      cardTheme: CardThemeData(
        color: effectiveColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: textColor.withValues(alpha: 0.08), width: 1),
        ),
      ),

      // 3. CONFIG BOTTOM SHEET
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: textColor.withValues(alpha: 0.2),
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // Khởi tạo Light Theme
  static ThemeData get light => _buildTheme(
    bgColor: _lightBg,
    textColor: _lightText,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      surface: _lightSurface,
      onSurface: _lightText,
    ),
  );

  // Khởi tạo Dark Theme
  static ThemeData get dark => _buildTheme(
    bgColor: _darkBg,
    textColor: _darkText,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      surface: _darkSurface,
      onSurface: _darkText,
    ),
  );
}
