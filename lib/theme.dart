import 'package:flutter/material.dart';

/// Same palette as the web prototype: ledger green accent, slightly green-tinted
/// neutrals, one set of category colours that reads on both backgrounds.
class AppColors extends ThemeExtension<AppColors> {
  final Color bg, surface, surface2, ink, muted, line, accent, accentInk, accentSoft, income, expense, warn;
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.income,
    required this.expense,
    required this.warn,
  });

  static const light = AppColors(
    bg: Color(0xFFEDF1EF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE2E8E5),
    ink: Color(0xFF14201B),
    muted: Color(0xFF5A6963),
    line: Color(0xFFD2DBD7),
    accent: Color(0xFF1D6A56),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD3E8E0),
    income: Color(0xFF2C7A4C),
    expense: Color(0xFFB23F28),
    warn: Color(0xFFA86A12),
  );
  static const dark = AppColors(
    bg: Color(0xFF0F1513),
    surface: Color(0xFF172019),
    surface2: Color(0xFF212C27),
    ink: Color(0xFFE5ECE8),
    muted: Color(0xFF93A39C),
    line: Color(0xFF2A3631),
    accent: Color(0xFF5CC2A3),
    accentInk: Color(0xFF0B1612),
    accentSoft: Color(0xFF1D3B32),
    income: Color(0xFF78D19B),
    expense: Color(0xFFEE8A72),
    warn: Color(0xFFE3B256),
  );

  @override
  AppColors copyWith() => this;
  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

const slotColors = {
  'c1': Color(0xFFD9822B),
  'c2': Color(0xFF3A78B5),
  'c3': Color(0xFF7A5BB0),
  'c4': Color(0xFFC2453B),
  'c5': Color(0xFF2E9C8F),
  'c6': Color(0xFFD4A72C),
  'c7': Color(0xFFC25A8C),
  'c8': Color(0xFF4F8A3A),
  'c9': Color(0xFF8C6A4A),
  'c10': Color(0xFF7D8A86),
};
Color slot(String id) => slotColors[id] ?? slotColors['c10']!;

extension Ctx on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

const numStyle = TextStyle(fontFamily: 'IBMPlexMono', fontFeatures: [FontFeature.tabularFigures()]);

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: b).copyWith(
    primary: c.accent,
    onPrimary: c.accentInk,
    surface: c.surface,
    onSurface: c.ink,
    outline: c.line,
    outlineVariant: c.line,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.accent,
    error: c.expense,
  );
  final base = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme, fontFamily: 'IBMPlexSans');
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.muted, size: 22)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.accentInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: c.accent, width: 2)),
      labelStyle: TextStyle(color: c.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.accentInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.surface2,
        selectedBackgroundColor: c.surface,
        selectedForegroundColor: c.ink,
        foregroundColor: c.muted,
        side: BorderSide(color: c.surface2),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.surface2,
      side: BorderSide(color: c.line),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: c.ink, fontSize: 13.5),
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.bg),
    ),
  );
}
