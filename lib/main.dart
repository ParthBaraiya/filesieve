import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/file_picker/fs_picker.dart';
import 'package:filesieve/utils/file_picker/fs_picker_base.dart';
import 'package:filesieve/utils/routes/shared_axis_transition_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'modules/dashboard_screen.dart';
import 'modules/history/history_screen.dart';
import 'modules/home/home_screen.dart';
import 'modules/loading/loading_screen.dart';
import 'modules/results/results_screen.dart';
import 'modules/settings/settings_screen.dart';
import 'modules/settings/settings_screen_cubit.dart';
import 'modules/app_settings/app_settings_cubit.dart';
import 'repository/app_settings/app_settings_repository.dart';
import 'repository/cache_paths/cache_paths_repository.dart';
import 'objectbox.g.dart';
import 'repository/scan_session/scan_session_repository.dart';
import 'values/app_routes.dart';
import 'values/app_theme.dart';
import 'values/enums.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the ObjectBox store once on the main isolate.
  // Worker isolates attach to it via Store.attach(getObjectBoxModel(), path).
  final store = await openStore();

  serviceLocator.registerSingleton<Store>(store);
  serviceLocator.registerLazySingleton<FsPickerBase>(FsPicker.new);

  final settingsRepository = AppSettingsRepository(store.directoryPath);
  final settings = await settingsRepository.load();

  runApp(
    BlocProvider(
      create: (_) => AppSettingsCubit(
        repository: settingsRepository,
        initial: settings,
      ),
      child: const FileSieveApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1600, 1000);
    appWindow.minSize = initialSize;
    appWindow.title = "FileSieve";
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

/// Instantiate the repository once at startup and pass it down explicitly —
/// no BuildContext / BlocProvider lookup needed at this level.
final _repo = ScanSessionRepository();

final router = GoRouter(
  initialLocation: AppRoutes.loading,
  routes: [
    GoRoute(
      name: AppRouteNames.loading,
      path: AppRoutes.loading,
      builder: (context, state) => LoadingScreen(repository: _repo),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardScreenContent(child: child),
      routes: [
        GoRoute(
          name: AppRouteNames.home,
          path: AppRoutes.home,
          pageBuilder: (context, state) =>
              SharedAxisTransitionPage(key: state.pageKey, child: HomeScreen()),
        ),
        GoRoute(
          name: AppRouteNames.results,
          path: AppRoutes.results,
          pageBuilder: (context, state) => SharedAxisTransitionPage(
            key: state.pageKey,
            child: ResultsScreen(),
          ),
        ),
        GoRoute(
          name: AppRouteNames.settings,
          path: AppRoutes.settings,
          pageBuilder: (context, state) {
            final storePath = serviceLocator.get<Store>().directoryPath;
            final repo = CachePathsRepository(storePath);
            final cubit = SettingsScreenCubit(repository: repo);

            return SharedAxisTransitionPage(
              key: state.pageKey,
              child: BlocProvider.value(value: cubit, child: SettingsScreen()),
            );
          },
        ),
        GoRoute(
          name: AppRouteNames.history,
          path: AppRoutes.history,
          pageBuilder: (context, state) => SharedAxisTransitionPage(
            key: state.pageKey,
            child: HistoryScreen(),
          ),
        ),
      ],
    ),
  ],
);

class FileSieveApp extends StatelessWidget {
  const FileSieveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1600, 1000),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        final themeMode = context.select<AppSettingsCubit, AppThemeMode>(
          (cubit) => cubit.state.themeMode,
        );
        return MaterialApp.router(
          title: 'FileSieve',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(gradient: context.palette.wall),
            child: child,
          ),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
