import 'package:material_ui/material_ui.dart';

import '../models/miel_models.dart';
import '../storage/app_database.dart';

/// Paleta cromática fiel a MIeL UNLaM (modo claro y modo oscuro).
@immutable
class MielPalette extends ThemeExtension<MielPalette> {
  const MielPalette({
    required this.primary,
    required this.primaryHover,
    required this.primaryDark,
    required this.linkAccent,
    required this.pageBackground,
    required this.topBarBackground,
    required this.sidebarBackground,
    required this.sidebarBorder,
    required this.sidebarHover,
    required this.sidebarSelected,
    required this.sidebarIcon,
    required this.sidebarIconActive,
    required this.cardBackground,
    required this.cardHover,
    required this.cardBorder,
    required this.buttonSecondaryBackground,
    required this.buttonSecondaryHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.inputBackground,
    required this.inputBorder,
    required this.dropdownBackground,
    required this.badgeRed,
    required this.toolMaterialsHover,
    required this.toolCommunicationHover,
    required this.toolEvaluationHover,
    required this.unreadBackground,
    required this.unreadBorder,
    required this.paleYellowBackground,
    required this.paleYellowBorder,
    required this.paleRedBackground,
    required this.paleRedBorder,
    required this.paleGreenBackground,
  });

  final Color primary;
  final Color primaryHover;
  final Color primaryDark;
  final Color linkAccent;
  final Color pageBackground;
  final Color topBarBackground;
  final Color sidebarBackground;
  final Color sidebarBorder;
  final Color sidebarHover;
  final Color sidebarSelected;
  final Color sidebarIcon;
  final Color sidebarIconActive;
  final Color cardBackground;
  final Color cardHover;
  final Color cardBorder;
  final Color buttonSecondaryBackground;
  final Color buttonSecondaryHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color inputBackground;
  final Color inputBorder;
  final Color dropdownBackground;
  final Color badgeRed;
  final Color toolMaterialsHover;
  final Color toolCommunicationHover;
  final Color toolEvaluationHover;
  final Color unreadBackground;
  final Color unreadBorder;
  final Color paleYellowBackground;
  final Color paleYellowBorder;
  final Color paleRedBackground;
  final Color paleRedBorder;
  final Color paleGreenBackground;

  static const MielPalette light = MielPalette(
    primary: Color(0xFF009674),
    primaryHover: Color(0xFF008566),
    primaryDark: Color(0xFF00765B),
    linkAccent: Color(0xFF009674),
    pageBackground: Color(0xFFFFFFFF),
    topBarBackground: Color(0xFFFFFFFF),
    sidebarBackground: Color(0xFFF3F9F6),
    sidebarBorder: Color(0xFFE2E7E7),
    sidebarHover: Color(0xFFE2E7E7),
    sidebarSelected: Color(0xFFC9ECDC),
    sidebarIcon: Color(0xFF999999),
    sidebarIconActive: Color(0xFF555555),
    cardBackground: Color(0xFFEEEEEE),
    cardHover: Color(0xFFE5E5E5),
    cardBorder: Color(0xFFE0E0E0),
    buttonSecondaryBackground: Color(0xFFF1F1F1),
    buttonSecondaryHover: Color(0xFFDCDCDC),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF757575),
    divider: Color(0xFFE5E5E5),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFCCCCCC),
    dropdownBackground: Color(0xFFFFFFFF),
    badgeRed: Color(0xFFF44336),
    toolMaterialsHover: Color(0xFF4CAF50),
    toolCommunicationHover: Color(0xFF2196F3),
    toolEvaluationHover: Color(0xFFF44336),
    unreadBackground: Color(0xFFF4FAF4),
    unreadBorder: Color(0xFF009674),
    paleYellowBackground: Color(0xFFFFFFCC),
    paleYellowBorder: Color(0xFFE0D78C),
    paleRedBackground: Color(0xFFFFDDDD),
    paleRedBorder: Color(0xFFF44336),
    paleGreenBackground: Color(0xFFDDFFDD),
  );

  static const MielPalette dark = MielPalette(
    primary: Color(0xFF128268),
    primaryHover: Color(0xFF10755E),
    primaryDark: Color(0xFF0E6853),
    linkAccent: Color(0xFF7BCEB9),
    pageBackground: Color(0xFF121212),
    topBarBackground: Color(0xFF121212),
    sidebarBackground: Color(0xFF262626),
    sidebarBorder: Color(0xFF333333),
    sidebarHover: Color(0xFF444444),
    sidebarSelected: Color(0xFF333333),
    sidebarIcon: Color(0xFF6E6E6E),
    sidebarIconActive: Color(0xFFBBBBBB),
    cardBackground: Color(0xFF262626),
    cardHover: Color(0xFF333333),
    cardBorder: Color(0xFF343434),
    buttonSecondaryBackground: Color(0xFF262626),
    buttonSecondaryHover: Color(0xFF383838),
    textPrimary: Color(0xFFEEEEEE),
    textSecondary: Color(0xFFDDDDDD),
    textMuted: Color(0xFF999999),
    divider: Color(0xFF3A3A3A),
    inputBackground: Color(0xFF222222),
    inputBorder: Color(0xFF444444),
    dropdownBackground: Color(0xFF333333),
    badgeRed: Color(0xFFEA4A3E),
    toolMaterialsHover: Color(0xFF59A15B),
    toolCommunicationHover: Color(0xFF4F90C4),
    toolEvaluationHover: Color(0xFFEA4A3E),
    unreadBackground: Color(0xFF23332B),
    unreadBorder: Color(0xFF128268),
    paleYellowBackground: Color(0xFF464633),
    paleYellowBorder: Color(0xFF69694C),
    paleRedBackground: Color(0xFF483535),
    paleRedBorder: Color(0xFFD47D75),
    paleGreenBackground: Color(0xFF283A2E),
  );

  static MielPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<MielPalette>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  MielPalette copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primaryDark,
    Color? linkAccent,
    Color? pageBackground,
    Color? topBarBackground,
    Color? sidebarBackground,
    Color? sidebarBorder,
    Color? sidebarHover,
    Color? sidebarSelected,
    Color? sidebarIcon,
    Color? sidebarIconActive,
    Color? cardBackground,
    Color? cardHover,
    Color? cardBorder,
    Color? buttonSecondaryBackground,
    Color? buttonSecondaryHover,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? inputBackground,
    Color? inputBorder,
    Color? dropdownBackground,
    Color? badgeRed,
    Color? toolMaterialsHover,
    Color? toolCommunicationHover,
    Color? toolEvaluationHover,
    Color? unreadBackground,
    Color? unreadBorder,
    Color? paleYellowBackground,
    Color? paleYellowBorder,
    Color? paleRedBackground,
    Color? paleRedBorder,
    Color? paleGreenBackground,
  }) {
    return MielPalette(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryDark: primaryDark ?? this.primaryDark,
      linkAccent: linkAccent ?? this.linkAccent,
      pageBackground: pageBackground ?? this.pageBackground,
      topBarBackground: topBarBackground ?? this.topBarBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarIcon: sidebarIcon ?? this.sidebarIcon,
      sidebarIconActive: sidebarIconActive ?? this.sidebarIconActive,
      cardBackground: cardBackground ?? this.cardBackground,
      cardHover: cardHover ?? this.cardHover,
      cardBorder: cardBorder ?? this.cardBorder,
      buttonSecondaryBackground:
          buttonSecondaryBackground ?? this.buttonSecondaryBackground,
      buttonSecondaryHover: buttonSecondaryHover ?? this.buttonSecondaryHover,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      dropdownBackground: dropdownBackground ?? this.dropdownBackground,
      badgeRed: badgeRed ?? this.badgeRed,
      toolMaterialsHover: toolMaterialsHover ?? this.toolMaterialsHover,
      toolCommunicationHover:
          toolCommunicationHover ?? this.toolCommunicationHover,
      toolEvaluationHover: toolEvaluationHover ?? this.toolEvaluationHover,
      unreadBackground: unreadBackground ?? this.unreadBackground,
      unreadBorder: unreadBorder ?? this.unreadBorder,
      paleYellowBackground: paleYellowBackground ?? this.paleYellowBackground,
      paleYellowBorder: paleYellowBorder ?? this.paleYellowBorder,
      paleRedBackground: paleRedBackground ?? this.paleRedBackground,
      paleRedBorder: paleRedBorder ?? this.paleRedBorder,
      paleGreenBackground: paleGreenBackground ?? this.paleGreenBackground,
    );
  }

  @override
  MielPalette lerp(ThemeExtension<MielPalette>? other, double t) {
    if (other is! MielPalette) return this;
    return MielPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      linkAccent: Color.lerp(linkAccent, other.linkAccent, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      topBarBackground: Color.lerp(
        topBarBackground,
        other.topBarBackground,
        t,
      )!,
      sidebarBackground: Color.lerp(
        sidebarBackground,
        other.sidebarBackground,
        t,
      )!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarHover: Color.lerp(sidebarHover, other.sidebarHover, t)!,
      sidebarSelected: Color.lerp(sidebarSelected, other.sidebarSelected, t)!,
      sidebarIcon: Color.lerp(sidebarIcon, other.sidebarIcon, t)!,
      sidebarIconActive: Color.lerp(
        sidebarIconActive,
        other.sidebarIconActive,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      buttonSecondaryBackground: Color.lerp(
        buttonSecondaryBackground,
        other.buttonSecondaryBackground,
        t,
      )!,
      buttonSecondaryHover: Color.lerp(
        buttonSecondaryHover,
        other.buttonSecondaryHover,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      dropdownBackground: Color.lerp(
        dropdownBackground,
        other.dropdownBackground,
        t,
      )!,
      badgeRed: Color.lerp(badgeRed, other.badgeRed, t)!,
      toolMaterialsHover: Color.lerp(
        toolMaterialsHover,
        other.toolMaterialsHover,
        t,
      )!,
      toolCommunicationHover: Color.lerp(
        toolCommunicationHover,
        other.toolCommunicationHover,
        t,
      )!,
      toolEvaluationHover: Color.lerp(
        toolEvaluationHover,
        other.toolEvaluationHover,
        t,
      )!,
      unreadBackground: Color.lerp(
        unreadBackground,
        other.unreadBackground,
        t,
      )!,
      unreadBorder: Color.lerp(unreadBorder, other.unreadBorder, t)!,
      paleYellowBackground: Color.lerp(
        paleYellowBackground,
        other.paleYellowBackground,
        t,
      )!,
      paleYellowBorder: Color.lerp(
        paleYellowBorder,
        other.paleYellowBorder,
        t,
      )!,
      paleRedBackground: Color.lerp(
        paleRedBackground,
        other.paleRedBackground,
        t,
      )!,
      paleRedBorder: Color.lerp(paleRedBorder, other.paleRedBorder, t)!,
      paleGreenBackground: Color.lerp(
        paleGreenBackground,
        other.paleGreenBackground,
        t,
      )!,
    );
  }
}

ThemeData buildMielLightTheme() {
  const p = MielPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: Brightness.light,
    primary: p.primary,
    surface: p.pageBackground,
    error: p.badgeRed,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.pageBackground,
    dividerColor: p.divider,
    extensions: const [p],
    textTheme: _buildTextTheme(p.textPrimary, p.textSecondary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.primary : null,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.pageBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

ThemeData buildMielDarkTheme() {
  const p = MielPalette.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: Brightness.dark,
    primary: p.primary,
    surface: p.pageBackground,
    error: p.badgeRed,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.pageBackground,
    dividerColor: p.divider,
    extensions: const [p],
    textTheme: _buildTextTheme(p.textPrimary, p.textSecondary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.primary : null,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

TextTheme _buildTextTheme(Color primary, Color secondary) {
  return TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w300,
      height: 1.35,
      color: primary,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w300,
      height: 1.35,
      color: primary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: primary,
    ),
    bodyMedium: TextStyle(fontSize: 13.5, height: 1.45, color: primary),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: secondary),
  );
}

/// Mapeo de cada herramienta de MIeL a su ícono Material exacto y color de hover semántico.
extension MielToolKindUi on MielToolKind {
  IconData get icon {
    switch (this) {
      case MielToolKind.contenidos:
        return Icons.import_contacts;
      case MielToolKind.autoguia:
        return Icons.auto_stories;
      case MielToolKind.portafolio:
        return Icons.description;
      case MielToolKind.mensajeria:
        return Icons.drafts;
      case MielToolKind.foro:
        return Icons.forum;
      case MielToolKind.chat:
        return Icons.chat;
      case MielToolKind.encuestas:
        return Icons.note_alt;
      case MielToolKind.evaluacion:
        return Icons.assignment_turned_in;
    }
  }

  Color hoverColor(MielPalette palette) {
    switch (category) {
      case MielToolCategory.materials:
        return palette.toolMaterialsHover;
      case MielToolCategory.communication:
        return palette.toolCommunicationHover;
      case MielToolCategory.evaluation:
        return palette.toolEvaluationHover;
    }
  }
}

/// Helpers para renderizar una materia de Drift como tarjeta de MIeL.
extension SubjectMielUiExt on Subject {
  List<MielToolKind> get enabledTools => <MielToolKind>[
    if (hasContenidos) MielToolKind.contenidos,
    if (hasAutoguia) MielToolKind.autoguia,
    if (hasPortafolio) MielToolKind.portafolio,
    if (hasMensajeria) MielToolKind.mensajeria,
    if (hasForo) MielToolKind.foro,
    if (hasChat) MielToolKind.chat,
    if (hasEncuestas) MielToolKind.encuestas,
    if (hasEvaluacion) MielToolKind.evaluacion,
  ];

  int badgeFor(MielToolKind tool) {
    switch (tool) {
      case MielToolKind.contenidos:
        return lastContenidosBadge;
      case MielToolKind.mensajeria:
        return lastMensajesBadge;
      case MielToolKind.foro:
        return lastForoBadge;
      case MielToolKind.autoguia:
      case MielToolKind.portafolio:
      case MielToolKind.chat:
      case MielToolKind.encuestas:
      case MielToolKind.evaluacion:
        return 0;
    }
  }

  /// Formato exacto de MIeL: `3622 - Com: 12-6300 - Alumno/a` (omitiendo segmentos vacíos).
  String get formattedSubtitle {
    final parts = <String>[
      if (subjectCode.isNotEmpty) subjectCode,
      if (commissionCode.isNotEmpty) 'Com: $commissionCode',
      if (roleLabel.isNotEmpty) roleLabel,
    ];
    return parts.join(' - ');
  }

  /// Etiqueta usada en el dropdown de materia del encabezado de módulos: `Materia (12-6300)`.
  String get breadcrumbLabel {
    if (commissionCode.isEmpty) return name;
    return '$name ($commissionCode)';
  }
}
