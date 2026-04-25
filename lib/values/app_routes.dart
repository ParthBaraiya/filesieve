/// AppRoutes — all GoRouter path strings as static constants.
///
/// Use these in GoRoute `path:` declarations and anywhere a literal
/// path string is needed (e.g. GoRouter `initialLocation`).
class AppRoutes {
  AppRoutes._();

  static const String loading = '/loading';
  static const String home = '/';
  static const String results = '/results';
  static const String settings = '/settings';
  static const String history = '/history';
}

/// AppRouteNames — all GoRouter route names as static constants.
///
/// Use these in GoRoute `name:` declarations and in all navigation calls
/// via `context.goNamed(...)` / `context.pushNamed(...)`.
class AppRouteNames {
  AppRouteNames._();

  static const String loading = 'loading';
  static const String home = 'scan';
  static const String results = 'results';
  static const String settings = 'settings';
  static const String history = 'history';
}
