# Skill: Routing, Navigation & App Shell

**Applies when**: Adding new routes, creating new module screens, modifying the sidebar/navigation, or changing the app shell layout.

**Constitution references**: Principle X (Shell-Based Navigation Architecture), Principle I (Layered Architecture)

---

## App Shell Architecture

The app uses a `ShellRoute` that owns the persistent chrome (sidebar, header, footer). Screen widgets MUST return body content only.

```
┌─────────────────────────────────────────┐
│ ShellRoute → DashboardScreenContent     │
│ ┌──────┬────────────────────────────┐   │
│ │      │ HeaderSectionWidget        │   │
│ │ Side │────────────────────────────│   │
│ │ bar  │                            │   │
│ │      │   child (GoRoute screen)   │   │
│ │      │                            │   │
│ │      │────────────────────────────│   │
│ │      │ FooterSectionWidget        │   │
│ └──────┴────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## Router Structure

```dart
final router = GoRouter(
  initialLocation: AppRoutes.loading,
  routes: [
    // Outside shell — no sidebar/header/footer
    GoRoute(
      path: AppRoutes.loading,
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,     // MANDATORY
        child: const LoadingScreen(),
      ),
    ),
    // Inside shell — all primary screens
    ShellRoute(
      builder: (context, state, child) =>
          DashboardScreenContent(child: child),
      routes: [
        GoRoute(
          name: AppRouteNames.home,
          path: AppRoutes.home,
          pageBuilder: (context, state) => SharedAxisTransitionPage(
            key: state.pageKey, // MANDATORY
            child: HomeScreen(),
          ),
        ),
        // ... more routes ...
      ],
    ),
  ],
);
```

---

## Adding a New Route — Complete Checklist

### 1. Define route constants in `lib/values/app_routes.dart`

```dart
class AppRoutes {
  static const String newFeature = '/new-feature';
}

class AppRouteNames {
  static const String newFeature = 'new-feature';
}
```

### 2. Create screen widget in `lib/modules/<module>/`

```dart
// lib/modules/new_feature/new_feature_screen.dart
class NewFeatureScreen extends StatelessWidget {
  const NewFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Return BODY CONTENT ONLY — no shell wrapping
    return const Center(child: Text('New Feature'));
  }
}
```

### 3. Register route inside ShellRoute in `lib/main.dart`

```dart
GoRoute(
  name: AppRouteNames.newFeature,
  path: AppRoutes.newFeature,
  pageBuilder: (context, state) => SharedAxisTransitionPage(
    key: state.pageKey,   // NEVER omit — suppresses transitions
    child: const NewFeatureScreen(),
  ),
),
```

### 4. Add NavigationItem entry in `lib/values/enums.dart`

```dart
enum NavigationItem {
  home,
  newFeature,  // Add entry
  // ...

  String get route => switch (this) {
    NavigationItem.home => AppRoutes.home,
    NavigationItem.newFeature => AppRoutes.newFeature,
    // ...
  };

  static NavigationItem fromRoute(String location) => switch (location) {
    AppRoutes.newFeature => NavigationItem.newFeature,
    // ...
    _ => NavigationItem.home,  // Default fallback
  };

  IconData get icon => switch (this) {
    NavigationItem.newFeature => Icons.new_releases,
    // ...
  };

  String get label => switch (this) {
    NavigationItem.newFeature => 'New Feature',
    // ...
  };
}
```

---

## Critical Rules

### 1. Always use `pageBuilder`, never `builder`

```dart
// CORRECT — custom transition
GoRoute(
  path: AppRoutes.home,
  pageBuilder: (context, state) => SharedAxisTransitionPage(
    key: state.pageKey,
    child: HomeScreen(),
  ),
),

// WRONG — produces MaterialPage transition that conflicts with shell
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) => HomeScreen(),
),
```

### 2. Always pass `key: state.pageKey`

```dart
// CORRECT
SharedAxisTransitionPage(
  key: state.pageKey,  // Flutter detects page identity changes
  child: HomeScreen(),
)

// WRONG — Navigator treats all pages as identical, suppresses transitions
SharedAxisTransitionPage(
  child: HomeScreen(),
)
```

### 3. Screens MUST NOT wrap themselves in shell

```dart
// CORRECT — body content only
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const HomeContentBody();
  }
}

// WRONG — duplicate shell chrome
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardScreenContent(
      child: const HomeContentBody(),  // NEVER DO THIS
    );
  }
}
```

### 4. Cross-module navigation via GoRouter only

```dart
// CORRECT
context.go(AppRoutes.results);
context.go(NavigationItem.results.route);

// WRONG — direct module import and push
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ResultsScreen(),  // NEVER import across modules
));
```

---

## NavigationItem Enum Pattern

The enum is the single source of truth for route↔UI mapping:

```dart
enum NavigationItem {
  home,
  scanner,
  results,
  settings,
  history;

  // Route → enum (used by sidebar to highlight active item)
  static NavigationItem fromRoute(String location) => switch (location) {
    AppRoutes.results  => NavigationItem.results,
    AppRoutes.settings => NavigationItem.settings,
    AppRoutes.history  => NavigationItem.history,
    AppRoutes.scanner  => NavigationItem.scanner,
    _                  => NavigationItem.home, // Default fallback
  };

  // Enum → route, icon, label (used by sidebar to render items)
  String get route => switch (this) { /* ... */ };
  IconData get icon => switch (this) { /* ... */ };
  String get label => switch (this) { /* ... */ };
}
```

**Bidirectional mapping** is required: `route` (item → path) AND `fromRoute` (path → item).

---

## MultiBlocProvider at Shell Level

Cubits shared across multiple child routes MUST be provided at the shell level:

```dart
class _DashboardScreenState extends State<DashboardScreenContent> {
  final _cubit = DashboardScreenCubit();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider(
          create: (_) => HomeScreenCubit(
            repository: ScanSessionRepositoryImpl(),
            scanRepository: DuplicateFinderRepositoryImpl(storePath: ''),
          ),
        ),
      ],
      child: /* shell layout */,
    );
  }
}
```

Cubits scoped to a single screen can be provided at the screen level via `BlocProvider(create: ...)`.

---

## Custom Transition Pages

All custom transition pages live in `lib/utils/routes/`:

```dart
// lib/utils/routes/shared_axis_transition_page.dart
class SharedAxisTransitionPage extends CustomTransitionPage<void> {
  SharedAxisTransitionPage({
    required super.child,
    super.key,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  );
}
```

---

## Checklist

- [ ] Route constants defined in `lib/values/app_routes.dart`
- [ ] Screen widget returns body content only — no shell wrapping
- [ ] GoRoute uses `pageBuilder`, not `builder`
- [ ] `SharedAxisTransitionPage` receives `key: state.pageKey`
- [ ] `NavigationItem` enum updated with `route`, `fromRoute`, `icon`, `label`
- [ ] Cross-module navigation uses `context.go()` — no direct module imports
- [ ] Shared cubits provided at shell level via `MultiBlocProvider`
- [ ] Custom transition pages live in `lib/utils/routes/`
