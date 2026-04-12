import 'package:filesieve/utils/routes/shared_axis_transition_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'modules/dashboard_screen.dart';
import 'modules/history/history_screen.dart';
import 'modules/home/home_screen.dart';
import 'modules/loading/loading_screen.dart';
import 'modules/results/results_screen.dart';
import 'modules/settings/settings_screen.dart';
import 'repository/scan_session_repository_impl.dart';
import 'values/app_routes.dart';
import 'values/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FileSieveApp());
}

/// Instantiate the repository once at startup and pass it down explicitly —
/// no BuildContext / BlocProvider lookup needed at this level.
final _repo = ScanSessionRepositoryImpl();

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
      // pageBuilder: (context, state, child) =>
      //     SharedAxisTransitionPage(child: DashboardScreenContent(child: child)),
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
          pageBuilder: (context, state) => SharedAxisTransitionPage(
            key: state.pageKey,
            child: SettingsScreen(),
          ),
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
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'FileSieve',
          theme: AppTheme.light(),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
