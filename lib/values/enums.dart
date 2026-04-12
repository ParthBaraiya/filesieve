import 'package:filesieve/values/app_routes.dart';

/// NavigationItem — the four persistent sidebar navigation destinations.
enum NavigationItem {
  scan,
  results,
  settings,
  history;

  String get route => switch (this) {
    NavigationItem.scan => AppRoutes.home,
    NavigationItem.results => AppRoutes.results,
    NavigationItem.settings => AppRoutes.settings,
    NavigationItem.history => AppRoutes.history,
  };

  static NavigationItem fromRoute(String location) => switch (location) {
    AppRoutes.results => NavigationItem.results,
    AppRoutes.settings => NavigationItem.settings,
    AppRoutes.history => NavigationItem.history,
    _ => NavigationItem.scan,
  };
}

/// ScanSessionStatus — lifecycle state of a scan session.
enum ScanSessionStatus {
  pending,
  scanning,
  done,
  cancelled,
}
