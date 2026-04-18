import 'package:filesieve/values/app_routes.dart';
import 'package:flutter/material.dart';

/// NavigationItem — the four persistent sidebar navigation destinations.
enum NavigationItem {
  home,
  scanner,
  results,
  settings,
  history;

  String get route => switch (this) {
    NavigationItem.home => AppRoutes.home,
    NavigationItem.results => AppRoutes.results,
    NavigationItem.settings => AppRoutes.settings,
    NavigationItem.history => AppRoutes.history,
    NavigationItem.scanner => AppRoutes.scanner,
  };

  static NavigationItem fromRoute(String location) => switch (location) {
    AppRoutes.results => NavigationItem.results,
    AppRoutes.settings => NavigationItem.settings,
    AppRoutes.history => NavigationItem.history,
    AppRoutes.scanner => NavigationItem.scanner,
    _ => NavigationItem.home,
  };

  IconData get icon => switch (this) {
    NavigationItem.home => Icons.search,
    NavigationItem.results => Icons.list_alt_outlined,
    NavigationItem.settings => Icons.settings_outlined,
    NavigationItem.history => Icons.history,
    NavigationItem.scanner => Icons.search,
  };

  String get label => switch (this) {
    NavigationItem.home => 'Select',
    NavigationItem.results => 'Results',
    NavigationItem.settings => 'Settings',
    NavigationItem.history => 'History',
    NavigationItem.scanner => 'Scan',
  };
}

/// ScanSessionStatus — lifecycle state of a scan session.
enum ScanSessionStatus { pending, scanning, done, cancelled }
