import 'package:filesieve/models/app_settings_model.dart';
import 'package:filesieve/modules/app_settings/app_settings_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/results/results_screen.dart';
import 'package:filesieve/modules/results/results_screen_cubit.dart';
import 'package:filesieve/modules/results/widgets/results_overlays_widget.dart';
import 'package:filesieve/values/app_theme.dart';
import 'package:filesieve/values/enums.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/results_fakes.dart';

/// Lays the Duplicates list, compare view and confirm dialog out at several
/// window sizes, themes and text scales, and fails on any layout exception
/// (overflow, unbounded constraints).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tests draw with a placeholder font unless the app fonts are loaded; that
  // font is far wider than Inter and would report overflows that don't exist.
  setUpAll(() async {
    for (final (family, asset) in const [
      ('Inter', 'assets/fonts/inter/inter_variable_opsz_wght.ttf'),
      ('Space Grotesk', 'assets/fonts/space_grotesk/SpaceGrotesk-Variable.ttf'),
      ('JetBrains Mono', 'assets/fonts/jetbrains_mono/JetBrainsMono-Variable.ttf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required bool dark,
    required Future<void> Function(ResultsScreenCubit cubit) arrange,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = AppSettingsCubit(
      repository: MemorySettings(),
      initial: const AppSettingsModel(),
    );
    final scanner = FileScannerCubit(
      repo: FakeFinder([
        makeGroup('Brand-Guidelines-2026-with-a-very-long-name-for-wrapping.pdf', 22 * 1024 * 1024, [
          ('Documents', 0), ('Downloads', 1), ('Desktop', 2), ('Projects', 3), ('Backup', 4),
        ]),
        makeGroup('photo.jpg', 4 * 1024 * 1024, [('Pictures', 0), ('Desktop', 2)]),
        makeGroup('movie.mp4', 1270 * 1024 * 1024, [('Downloads', 0), ('Desktop', 2)]),
      ]),
    );
    final cubit = ResultsScreenCubit(
      scanner: scanner,
      settings: settings,
      remover: FakeRemover(),
    );
    await scanner.startScan(['C:\\x']);
    await tester.pump();
    addTearDown(() async {
      await cubit.close();
      await scanner.close();
      await settings.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: cubit),
        ],
        child: ScreenUtilInit(
          designSize: const Size(1600, 1000),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Stack(
                children: const [
                  Positioned.fill(child: ResultsScreen()),
                  Positioned.fill(child: ResultsOverlaysWidget()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await arrange(cubit);
    await tester.pump(const Duration(milliseconds: 50));
  }

  const sizes = [Size(1600, 1000), Size(1200, 800), Size(1000, 700)];

  for (final size in sizes) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        final label = '${size.width.toInt()}x${size.height.toInt()} '
            'text×$scale ${dark ? 'dark' : 'light'}';

        testWidgets('list lays out: $label', (tester) async {
          await pump(tester, size: size, textScale: scale, dark: dark,
              arrange: (_) async {});
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('results.removeAll')), findsOneWidget);
        });

        testWidgets('compare lays out: $label', (tester) async {
          await pump(tester, size: size, textScale: scale, dark: dark,
              arrange: (cubit) async =>
                  cubit.openGroup(cubit.state.activeGroups.first.key));
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('compare.title')), findsOneWidget);
          expect(find.byKey(const ValueKey('compare.keepOthers')), findsOneWidget);
        });

        testWidgets('remove-all dialog lays out: $label', (tester) async {
          await pump(tester, size: size, textScale: scale, dark: dark,
              arrange: (cubit) async => cubit.openRemoveAll());
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('results.dialog')), findsOneWidget);
          expect(find.byKey(const ValueKey('results.folderChoice.0')), findsOneWidget);
        });
      }
    }
  }

  testWidgets('empty state shows when nothing is left', (tester) async {
    await pump(tester, size: sizes.first, textScale: 1, dark: false,
        arrange: (cubit) async {
      cubit.openRemoveAll();
      for (final c in cubit.state.choiceCombos) {
        cubit.chooseFolder(c.key, c.folders.first);
      }
      await cubit.confirmDialog();
    });
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('results.empty')), findsOneWidget);
    expect(find.text('No duplicates left'), findsOneWidget);
    expect(find.byKey(const ValueKey('results.toast')), findsOneWidget);
    // Removal mode default is trash, so the toast offers Undo.
    expect(find.byKey(const ValueKey('results.toast.undo')), findsOneWidget);
    expect(RemovalMode.values, contains(RemovalMode.trash));
    await tester.pump(const Duration(seconds: 6)); // let the toast timer end
  });
}
