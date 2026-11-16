import 'package:material_ui/material_ui.dart';

import 'enums.dart';

/// AppPalette — design tokens of the Dedupe glass design that the Material
/// [ColorScheme] has no slot for (translucent panels, file-type tints, the
/// backdrop gradient). Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.wall,
    required this.glass,
    required this.glassBorder,
    required this.bar,
    required this.side,
    required this.panel,
    required this.panelStrong,
    required this.line,
    required this.dash,
    required this.track,
    required this.text,
    required this.muted,
    required this.accentText,
    required this.accentSoft,
    required this.accentLine,
    required this.danger,
    required this.dangerSoft,
    required this.dangerLine,
    required this.ok,
    required this.onOk,
    required this.okSoft,
    required this.okLine,
    required this.input,
    required this.overlay,
    required this.dialog,
    required this.footer,
    required this.toast,
    required this.toastText,
    required this.tile,
    required this.tintImage,
    required this.tintDocument,
    required this.tintVideo,
    required this.tintAudio,
    required this.tintArchive,
  });

  /// Brand accent shared by both themes (#3D5AFE).
  static const Color brand = Color(0xFF3D5AFE);

  /// Destructive button fill shared by both themes (#D93025).
  static const Color destructive = Color(0xFFD93025);

  final Gradient wall;
  final Color glass;
  final Color glassBorder;
  final Color bar;
  final Color side;
  final Color panel;
  final Color panelStrong;
  final Color line;
  final Color dash;
  final Color track;
  final Color text;
  final Color muted;
  final Color accentText;
  final Color accentSoft;
  final Color accentLine;
  final Color danger;
  final Color dangerSoft;
  final Color dangerLine;
  final Color ok;
  final Color onOk;
  final Color okSoft;
  final Color okLine;
  final Color input;
  final Color overlay;
  final Color dialog;
  final Color footer;
  final Color toast;
  final Color toastText;
  final Color tile;
  final Color tintImage;
  final Color tintDocument;
  final Color tintVideo;
  final Color tintAudio;
  final Color tintArchive;

  static Gradient _wall(Color base, Color a, Color b, Color c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.alphaBlend(a, base),
      Color.alphaBlend(b, base),
      Color.alphaBlend(c, base),
    ],
    stops: const [0, 0.55, 1],
  );

  static final AppPalette dark = AppPalette(
    wall: _wall(
      const Color(0xFF070A14),
      const Color(0x8C3D5AFE),
      const Color(0x6B9333EA),
      const Color(0x730D9488),
    ),
    glass: const Color(0x9910141F),
    glassBorder: const Color(0x1FFFFFFF),
    bar: const Color(0x08FFFFFF),
    side: const Color(0x08FFFFFF),
    panel: const Color(0x0DFFFFFF),
    panelStrong: const Color(0x1AFFFFFF),
    line: const Color(0x17FFFFFF),
    dash: const Color(0x739DAEFF),
    track: const Color(0x1AFFFFFF),
    text: const Color(0xFFF3F5FA),
    muted: const Color(0xFFAEB5C6),
    accentText: const Color(0xFFA9B8FF),
    accentSoft: const Color(0x383D5AFE),
    accentLine: const Color(0xBF6E87FF),
    danger: const Color(0xFFFF968E),
    dangerSoft: const Color(0x1FFF6358),
    dangerLine: const Color(0x59FF786E),
    ok: const Color(0xFF5EE0B4),
    onOk: const Color(0xFF06281C),
    okSoft: const Color(0x2434D399),
    okLine: const Color(0x5934D399),
    input: const Color(0x40000000),
    overlay: const Color(0x8C04060C),
    dialog: const Color(0xD9181C2A),
    footer: const Color(0xBF101420),
    toast: const Color(0xFFF3F5FA),
    toastText: const Color(0xFF121521),
    tile: const Color(0x14FFFFFF),
    tintImage: const Color(0xFF7DD3FC),
    tintDocument: const Color(0xFFA9B8FF),
    tintVideo: const Color(0xFFF0ABFC),
    tintAudio: const Color(0xFFFCD34D),
    tintArchive: const Color(0xFF5EEAD4),
  );

  static final AppPalette light = AppPalette(
    wall: _wall(
      const Color(0xFFEDF0F8),
      const Color(0x806382FF),
      const Color(0x6BC084FC),
      const Color(0x662DD4BF),
    ),
    glass: const Color(0x8FFFFFFF),
    glassBorder: const Color(0xD9FFFFFF),
    bar: const Color(0x59FFFFFF),
    side: const Color(0x47FFFFFF),
    panel: const Color(0x8CFFFFFF),
    panelStrong: const Color(0xE0FFFFFF),
    line: const Color(0x1A141828),
    dash: const Color(0x733D5AFE),
    track: const Color(0x14141828),
    text: const Color(0xFF121521),
    muted: const Color(0xFF4A5368),
    accentText: const Color(0xFF2B45D6),
    accentSoft: const Color(0x1F3D5AFE),
    accentLine: const Color(0xA63D5AFE),
    danger: const Color(0xFFB42318),
    dangerSoft: const Color(0x14D93025),
    dangerLine: const Color(0x4DB42318),
    ok: const Color(0xFF0E7352),
    onOk: const Color(0xFFFFFFFF),
    okSoft: const Color(0x1F10A374),
    okLine: const Color(0x5910A374),
    input: const Color(0xA6FFFFFF),
    overlay: const Color(0x471E243C),
    dialog: const Color(0xE0FFFFFF),
    footer: const Color(0xBFFFFFFF),
    toast: const Color(0xFF151A2B),
    toastText: const Color(0xFFF3F5FA),
    tile: const Color(0xE6FFFFFF),
    tintImage: const Color(0xFF0369A1),
    tintDocument: const Color(0xFF2B45D6),
    tintVideo: const Color(0xFFA21CAF),
    tintAudio: const Color(0xFF92400E),
    tintArchive: const Color(0xFF0F766E),
  );

  /// Accent colour used for a file type's icon.
  Color tintOf(FileCategory category) => switch (category) {
    FileCategory.image => tintImage,
    FileCategory.video => tintVideo,
    FileCategory.document => tintDocument,
    FileCategory.audio => tintAudio,
    FileCategory.archive => tintArchive,
    FileCategory.other => muted,
  };

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null ? this : (t < 0.5 ? this : other);
}
