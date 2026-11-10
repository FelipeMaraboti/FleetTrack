import 'package:flutter/material.dart';

/// Identidade visual do FleetTrack: preto e branco, tipografia forte,
/// superfícies planas e cantos arredondados (inspirado em apps de mobilidade).
class AppColors {
  static const preto = Color(0xFF000000);
  static const branco = Color(0xFFFFFFFF);
  static const cinza50 = Color(0xFFF6F6F6);
  static const cinza100 = Color(0xFFEEEEEE);
  static const cinza300 = Color(0xFFCBCBCB);
  static const cinza500 = Color(0xFF6B6B6B);
  static const cinza800 = Color(0xFF282828);
  static const verde = Color(0xFF05A357);
  static const laranja = Color(0xFFFF8A00);
  static const vermelho = Color(0xFFE11900);
  static const azul = Color(0xFF276EF1);
}

class AppTheme {
  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get escuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness b) {
    final escuro = b == Brightness.dark;
    final fundo = escuro ? AppColors.preto : AppColors.branco;
    final texto = escuro ? AppColors.branco : AppColors.preto;
    final superficie = escuro ? const Color(0xFF161616) : AppColors.cinza50;
    final superficieAlta = escuro ? AppColors.cinza800 : AppColors.cinza100;
    final secundario = escuro ? const Color(0xFFAFAFAF) : AppColors.cinza500;

    final esquema = ColorScheme(
      brightness: b,
      primary: texto,
      onPrimary: fundo,
      primaryContainer: superficieAlta,
      onPrimaryContainer: texto,
      secondary: AppColors.verde,
      onSecondary: AppColors.branco,
      tertiary: AppColors.azul,
      onTertiary: AppColors.branco,
      error: AppColors.vermelho,
      onError: AppColors.branco,
      errorContainer: escuro ? const Color(0xFF3D0A00) : const Color(0xFFFFEFED),
      onErrorContainer: escuro ? const Color(0xFFFFB4A8) : const Color(0xFF8A1000),
      surface: fundo,
      onSurface: texto,
      onSurfaceVariant: secundario,
      surfaceContainerLowest: fundo,
      surfaceContainerLow: superficie,
      surfaceContainer: superficie,
      surfaceContainerHigh: superficieAlta,
      surfaceContainerHighest: superficieAlta,
      outline: escuro ? const Color(0xFF3A3A3A) : AppColors.cinza300,
      outlineVariant: escuro ? const Color(0xFF2A2A2A) : AppColors.cinza100,
      inverseSurface: texto,
      onInverseSurface: fundo,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: esquema, brightness: b);
    final tt = base.textTheme.apply(bodyColor: texto, displayColor: texto);
    const raio = BorderRadius.all(Radius.circular(12));
    const pilula = StadiumBorder();

    return base.copyWith(
      scaffoldBackgroundColor: fundo,
      splashFactory: InkSparkle.splashFactory,
      textTheme: tt.copyWith(
        headlineLarge: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodySmall: tt.bodySmall?.copyWith(color: secundario),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: texto,
        titleTextStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: tt.bodyMedium?.copyWith(color: secundario),
      ),
      dividerTheme: DividerThemeData(color: esquema.outlineVariant, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficieAlta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(borderRadius: raio, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: raio, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: raio, borderSide: BorderSide(color: texto, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: raio, borderSide: BorderSide(color: AppColors.vermelho, width: 1.5)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: raio, borderSide: BorderSide(color: AppColors.vermelho, width: 2)),
        labelStyle: TextStyle(color: secundario),
        floatingLabelStyle: TextStyle(color: texto, fontWeight: FontWeight.w600),
        prefixIconColor: texto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: texto,
          foregroundColor: fundo,
          minimumSize: const Size(64, 56),
          shape: raio.toShape(),
          textStyle: tt.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: texto,
          foregroundColor: fundo,
          elevation: 0,
          minimumSize: const Size(64, 56),
          shape: raio.toShape(),
          textStyle: tt.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texto,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: esquema.outline),
          shape: raio.toShape(),
          textStyle: tt.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: texto,
          textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: texto,
        foregroundColor: fundo,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        shape: pilula,
        extendedTextStyle: tt.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: superficieAlta,
        selectedColor: texto,
        side: BorderSide.none,
        shape: pilula,
        labelStyle: TextStyle(color: texto, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: fundo, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fundo : secundario),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? texto : superficieAlta),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: texto,
        linearTrackColor: superficieAlta,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: escuro ? AppColors.cinza800 : AppColors.preto,
        contentTextStyle: const TextStyle(color: AppColors.branco, fontWeight: FontWeight.w500),
        shape: const RoundedRectangleBorder(borderRadius: raio),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: fundo,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fundo,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: fundo,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.vermelho),
    );
  }
}

extension on BorderRadius {
  OutlinedBorder toShape() => RoundedRectangleBorder(borderRadius: this);
}
