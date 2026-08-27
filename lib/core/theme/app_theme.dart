import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chủ đề Dididi — hiện đại tối giản kiểu Agoda/Booking, giữ xanh lá thương hiệu (#2f8b60),
/// chữ Inter (gần với font hệ thống iOS SF, hỗ trợ tiếng Việt đầy đủ). Chỉ chế độ sáng.
class AppTheme {
  // ----- Bảng màu -----
  static const brand = Color(0xFF2F8B60); // xanh lá thương hiệu
  static const brandDark = Color(0xFF23694A);
  static const brandSoft = Color(0xFFE8F2EC); // nền nhạt cho chip/indicator
  static const ink = Color(0xFF17201C); // chữ chính
  static const muted = Color(0xFF69736F); // chữ phụ
  static const line = Color(0xFFE7EBE9); // đường kẻ mảnh
  static const bg = Color(0xFFF5F7F6); // nền màn hình
  static const surface = Colors.white;
  static const amber = Color(0xFFF5A623); // sao đánh giá

  // ----- Bo góc -----
  static const rCard = 16.0;
  static const rControl = 13.0;
  static const rSheet = 22.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: brandSoft,
      onPrimaryContainer: brandDark,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: const Color(0xFFF0F3F1),
      outline: line,
      outlineVariant: line,
      error: const Color(0xFFD64545),
    );

    // Chữ: Inter, tinh chỉnh trọng lượng + giãn chữ hơi âm cho cảm giác iOS.
    final baseText = ThemeData(brightness: Brightness.light).textTheme;
    final text = GoogleFonts.interTextTheme(baseText)
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: ink),
          titleLarge: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: ink),
          titleMedium: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: ink),
          titleSmall: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: ink),
          bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.4, color: ink),
          bodyMedium: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: ink),
          bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.35, color: muted),
          labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
        );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(rControl),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      primaryColor: brand,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      iconTheme: const IconThemeData(color: ink, size: 22),

      // App bar: trắng, phẳng, chữ đậm.
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 18.5, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: ink),
        iconTheme: const IconThemeData(color: ink, size: 22),
      ),

      // Thẻ: trắng, bo mềm, viền mảnh, bóng rất nhẹ.
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
          side: const BorderSide(color: line),
        ),
      ),

      // Ô nhập: nền trắng, viền mảnh, focus xanh.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: muted),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: muted),
        floatingLabelStyle: GoogleFonts.inter(fontSize: 13, color: brand, fontWeight: FontWeight.w600),
        prefixIconColor: muted,
        border: border(line),
        enabledBorder: border(line),
        focusedBorder: border(brand, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
      ),

      // Nút.
      //
      // ⚠️ CẢNH BÁO — `Size.fromHeight(n)` bên dưới CHÍNH LÀ `Size(double.infinity, n)`,
      // tức mọi nút trong app có bề rộng tối thiểu VÔ HẠN.
      //
      // Cố ý: để nút tự kéo hết bề ngang trong Column/form mà không phải bọc SizedBox
      // ở hàng chục màn. Trong Column vô hại vì chiều rộng đã bị giới hạn sẵn.
      //
      // NHƯNG: đặt một nút làm con TRỰC TIẾP của `Row` là bố trí đổ vỡ ngay —
      // Row cấp chiều rộng không giới hạn, ném "BoxConstraints forces an infinite
      // width", rồi "RenderBox was not laid out" lan ngược lên và làm CẢ danh sách
      // cha không vẽ được (trang trắng trơn, xem lịch sử ngày 27/08/2026 ở
      // hotel_detail_screen.dart).
      //
      // Khi đặt nút trong Row, PHẢI làm một trong hai:
      //   • đặt lại `minimumSize: const Size(0, 40)` cho riêng nút đó, hoặc
      //   • bọc nút trong `Expanded` / `Flexible`.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brand.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rControl)),
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: 0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rControl)),
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rControl)),
          textStyle: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink),
      ),

      // Chip dạng viên thuốc (pill).
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: brandSoft,
        secondarySelectedColor: brandSoft,
        checkmarkColor: brandDark,
        showCheckmark: false,
        side: const BorderSide(color: line),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: ink),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Thanh điều hướng dưới.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brandSoft,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? brandDark : muted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected) ? brandDark : muted,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brand,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Hộp thoại + bottom sheet.
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 17.5, fontWeight: FontWeight.w700, color: ink),
        contentTextStyle: GoogleFonts.inter(fontSize: 14.5, height: 1.4, color: ink),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontSize: 14, color: ink),
      ),

      // SnackBar nổi, tối, bo góc.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
        actionTextColor: const Color(0xFF8FD3B0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(14),
      ),

      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: muted, textColor: ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? brand : const Color(0xFFCED4D1)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? brand : muted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? brand : Colors.transparent),
        side: const BorderSide(color: muted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: brand,
        selectionColor: brandSoft,
        selectionHandleColor: brand,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: brand,
        unselectedLabelColor: muted,
        indicatorColor: brand,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
