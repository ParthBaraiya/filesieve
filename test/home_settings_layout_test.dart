import 'dart:async';
import 'dart:io';

import 'package:filesieve/models/app_settings_model.dart';
import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/models/scan_folder_model.dart';
import 'package:filesieve/models/scan_progress_model.dart';
import 'package:filesieve/models/scan_session_model.dart';
import 'package:filesieve/modules/app_settings/app_settings_cubit.dart';
import 'package:filesieve/modules/home/home_screen.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:filesieve/modules/settings/widgets/appearance_section_widget.dart';
import 'package:filesieve/modules/settings/widgets/removal_settings_section_widget.dart';
import 'package:filesieve/modules/settings/widgets/reset_section_widget.dart';
import 'package:filesieve/modules/settings/widgets/watched_folders_section_widget.dart';
import 'package:filesieve/repository/duplicate_finder/duplicate_finder_repository_base.dart';
import 'package:filesieve/repository/scan_session/scan_session_repository_base.dart';
import 'package:filesieve/utils/cancel_token.dart';
import 'package:filesieve/values/app_theme.dart';
import 'package:filesieve/values/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/results_fakes.dart';

class _FakeSessions implements ScanSessionRepositoryBase {
  @override
  Future<bool> hasActiveSession() async => false;
  @override
  Future<bool> hasCompletedResults() async => false;
  @override
  Future<ScanSessionModel> createSession(List<ScanFolderModel> folders) async =>
      ScanSessionModel(id: 'test', createdAt: DateTime(2026), folders: folders);
}

/// Reports a mid-scan progress and then waits until [finish] is completed.
class _SlowFinder implements DuplicateFinderRepositoryBase {
  final finish = Completer<void>();

  @override
  Future<List<DuplicateGroup>> find({
    required List<Directory> folders,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
    bool includeSubfolders = true,
    bool skipHidden = true,
    void Function(DuplicateGroup)? onGroupFound,
  }) async {
    onProgress(
      const ScanProgress(
        stageTotal: 200,
        stageProcessed: 80,
        stage: ScanProgressStage.calcPartialHash,
        currentPath: r'C:\Users\someone\Documents\a-rather-long-folder-name\and-another-one\report-final-v3.pdf',
      ),
    );
    await finish.future;
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<HomeScreenCubit> pump(
    WidgetTester tester, {
    required Widget child,
    required Size size,
    required double textScale,
    required bool dark,
    DuplicateFinderRepositoryBase? finder,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = AppSettingsCubit(
      repository: MemorySettings(),
      initial: const AppSettingsModel(),
    );
    final home = HomeScreenCubit(
      repository: _FakeSessions(),
      scanRepository: finder ?? FakeFinder(const []),
    );
    addTearDown(() async {
      await home.close();
      await settings.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: home),
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
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    return home;
  }

  const sizes = [Size(1600, 1000), Size(1200, 800), Size(1000, 700)];

  for (final size in sizes) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        final label = '${size.width.toInt()}x${size.height.toInt()} '
            'text×$scale ${dark ? 'dark' : 'light'}';

        testWidgets('setup (empty) lays out: $label', (tester) async {
          await pump(tester, child: const HomeScreen(), size: size, textScale: scale, dark: dark);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('setup.dropZone')), findsOneWidget);
        });

        testWidgets('setup (with folders) lays out: $label', (tester) async {
          final home = await pump(tester, child: const HomeScreen(), size: size, textScale: scale, dark: dark);
          await tester.runAsync(() => home.addFolderPaths([
                Directory.systemTemp.path,
                Directory.current.path,
              ]));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('2 folders to scan'), findsOneWidget);
          expect(find.byKey(const ValueKey('setup.removeFolder.1')), findsOneWidget);
        });

        testWidgets('scan progress lays out: $label', (tester) async {
          final finder = _SlowFinder();
          final home = await pump(tester, child: const HomeScreen(), size: size, textScale: scale, dark: dark, finder: finder);
          await tester.runAsync(() => home.addFolderPaths([Directory.systemTemp.path]));
          await tester.pump();
          unawaited(home.startScan());
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('scan.percent')), findsOneWidget);
          expect(find.byKey(const ValueKey('scan.cancel')), findsOneWidget);
          expect(find.text('Computing partial hashes…'), findsWidgets);
          expect(find.textContaining('report-final-v3.pdf'), findsOneWidget);
          finder.finish.complete();
          await tester.pump(const Duration(milliseconds: 100));
        });

        testWidgets('settings sections lay out: $label', (tester) async {
          await pump(
            tester,
            child: const SingleChildScrollView(
              child: Column(children: [
                RemovalSettingsSectionWidget(),
                WatchedFoldersSectionWidget(),
                AppearanceSectionWidget(),
                ResetSectionWidget(),
              ]),
            ),
            size: size,
            textScale: scale,
            dark: dark,
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('settings.theme.dark')), findsOneWidget);
          expect(find.byKey(const ValueKey('settings.mode.trash')), findsOneWidget);
        });
      }
    }
  }

  testWidgets('choosing Delete permanently and Dark updates settings', (tester) async {
    await pump(
      tester,
      child: const SingleChildScrollView(
        child: Column(children: [
          RemovalSettingsSectionWidget(),
          AppearanceSectionWidget(),
        ]),
      ),
      size: sizes.first,
      textScale: 1,
      dark: false,
    );
    final cubit = tester.element(find.byType(RemovalSettingsSectionWidget)).read<AppSettingsCubit>();

    await tester.tap(find.byKey(const ValueKey('settings.mode.permanent')));
    await tester.tap(find.byKey(const ValueKey('settings.theme.dark')));
    await tester.tap(find.byKey(const ValueKey('settings.confirmSwitch')));
    await tester.pump();

    expect(cubit.state.removalMode, RemovalMode.permanent);
    expect(cubit.state.themeMode, AppThemeMode.dark);
    expect(cubit.state.confirmBeforeEveryRemoval, isTrue);
  });
}
