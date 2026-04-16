import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'modules/home/home_screen.dart';
import 'modules/loading/loading_screen.dart';
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
    GoRoute(
      name: AppRouteNames.home,
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      name: AppRouteNames.scanner,
      path: AppRoutes.scanner,
      builder: (context, state) => const _PlaceholderScreen(label: 'Scanner'),
    ),
    GoRoute(
      name: AppRouteNames.results,
      path: AppRoutes.results,
      builder: (context, state) => const _PlaceholderScreen(label: 'Results'),
    ),
    GoRoute(
      name: AppRouteNames.settings,
      path: AppRoutes.settings,
      builder: (context, state) => const _PlaceholderScreen(label: 'Settings'),
    ),
    GoRoute(
      name: AppRouteNames.history,
      path: AppRoutes.history,
      builder: (context, state) => const _PlaceholderScreen(label: 'History'),
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

/// Temporary placeholder used until each route's real screen is implemented
/// in later phases. Replaced by HomeScreen (T020), etc.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
