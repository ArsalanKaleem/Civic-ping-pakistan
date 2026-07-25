import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CivicPing design system.
///
/// Palette: deep emerald + warm ivory + muted gold. Display type is Fraunces
/// (a warm, editorial serif); body/UI type is Inter. Generous whitespace,
/// hairline borders, soft 20px radii — refined rather than loud.
class Lux {
  // Brand
  static const emerald = Color(0xFF0E4D3A);
  static const emeraldDeep = Color(0xFF082F24);
  static const emeraldSoft = Color(0xFF1B7A5A);
  static const gold = Color(0xFFC9A24B);
  static const goldSoft = Color(0xFFE7D4A8);

  // Neutrals
  static const ivory = Color(0xFFFAF7F0);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF14201B);
  static const inkMuted = Color(0xFF5C6B64);
  static const hairline = Color(0xFFE5E0D3);

  // Dark neutrals
  static const night = Color(0xFF0C1512);
  static const nightSurface = Color(0xFF122019);
  static const nightHairline = Color(0xFF23342B);

  // Status
  static const red = Color(0xFFC0392B);
  static const amber = Color(0xFFC9880A);
  static const green = Color(0xFF1E7B4F);

  static const radius = 20.0;
  static const radiusSm = 12.0;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: isDark ? Lux.emeraldSoft : Lux.emerald,
      onPrimary: Colors.white,
      secondary: Lux.gold,
      onSecondary: Lux.ink,
      surface: isDark ? Lux.nightSurface : Lux.paper,
      onSurface: isDark ? const Color(0xFFE8EFEA) : Lux.ink,
      error: Lux.red,
      onError: Colors.white,
      outline: isDark ? Lux.nightHairline : Lux.hairline,
      outlineVariant: isDark ? Lux.nightHairline : Lux.hairline,
      surfaceContainerHighest:
          isDark ? const Color(0xFF16261E) : Lux.ivory,
      onSurfaceVariant: isDark ? const Color(0xFF9DB2A8) : Lux.inkMuted,
    );

    final body = GoogleFonts.interTextTheme(
      ThemeData(brightness: b).textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final display = GoogleFonts.fraunces(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      letterSpacing: -0.5,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? Lux.night : Lux.ivory,
      textTheme: body.copyWith(
        displayLarge: display.copyWith(fontSize: 52),
        displayMedium: display.copyWith(fontSize: 40),
        displaySmall: display.copyWith(fontSize: 32),
        headlineMedium: display.copyWith(fontSize: 26),
        headlineSmall: display.copyWith(fontSize: 22),
        titleLarge: body.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display.copyWith(fontSize: 22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Lux.radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Lux.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lux.radiusSm),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lux.radiusSm),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lux.radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(color: scheme.outline),
        ),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withOpacity(0.10),
        labelStyle: body.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Lux.radiusSm),
        ),
      ),
    );
  }
}

/// A refined card: hairline border, soft radius, optional hover lift on web.
class LuxCard extends StatefulWidget {
  const LuxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  State<LuxCard> createState() => _LuxCardState();
}

class _LuxCardState extends State<LuxCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Lux.radius),
        border: Border.all(
          color: _hover && widget.onTap != null
              ? scheme.primary.withOpacity(0.45)
              : scheme.outline,
        ),
        boxShadow: _hover && widget.onTap != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : const [],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return card;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
