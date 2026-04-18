# Skill: Widget Architecture & Responsive Layout

**Applies when**: Creating or modifying any screen, widget, or layout in `lib/modules/` or `lib/views/`.

**Constitution references**: Principle III (Widget Modularity), Principle IV (Responsive Layout), Principle IX (Theme-Driven Styling), Principle XIII (Theme Color Modification)

---

## File Placement Rules

| Widget type                   | Location                                                   | Naming                                    |
| ----------------------------- | ---------------------------------------------------------- | ----------------------------------------- |
| Screen body (route content)   | `lib/modules/<module>/widgets/` or `lib/modules/<module>/` | `*_screen.dart` (screen entry point only) |
| Module-specific sub-widget    | `lib/modules/<module>/widgets/`                            | `*_widget.dart`                           |
| Reusable (used in 2+ modules) | `lib/views/`                                               | `*_widget.dart`                           |
| Section-level layout widget   | `lib/views/`                                               | `*_section_widget.dart`                   |

**Promotion rule**: If a widget in `modules/<module>/widgets/` is imported by a second module, MOVE it to `lib/views/`.

---

## Screen Structure

Every screen MUST return only body content. It MUST NOT wrap itself in shell/sidebar/header/footer.

```dart
// CORRECT — screen returns body content only
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeScreenCubit, HomeScreenState>(
      builder: (context, state) {
        // Dispatch to section widgets based on state
        if (state is HomeScreenScanning) {
          return const ScanProgressBodyWidget();
        }
        if (state.hasFolders) {
          return const ScanConfigBodyWidget();
        }
        return const OnboardingBodyWidget();
      },
    );
  }
}
```

**500-line rule**: Any screen or widget file exceeding 500 lines MUST be split into sub-widgets in the `widgets/` folder.

---

## Widget Design Rules

### Single Responsibility

Each widget MUST do exactly one thing:

```dart
// GOOD — one purpose: display a progress bar with percentage
class ScanProgressWidget extends StatelessWidget {
  const ScanProgressWidget({super.key, required this.progress});
  final ScanProgress progress;

  @override
  Widget build(BuildContext context) { /* ... */ }
}

// BAD — mixed concerns: progress display + folder list + scan button
class EverythingWidget extends StatelessWidget { /* ... */ }
```

### Data via Constructor Parameters

Widgets receive ALL data through constructor parameters. No repository calls, no path parsing, no formatting:

```dart
// CORRECT
class ScanLiveFeedRowWidget extends StatelessWidget {
  const ScanLiveFeedRowWidget({super.key, required this.entry});
  final ScanDuplicateEntryModel entry; // Pre-formatted by Cubit

  @override
  Widget build(BuildContext context) {
    // entry.fileName, entry.parentPath, entry.sizeBytes — all ready to display
  }
}

// WRONG — widget performs data transformation
class ScanLiveFeedRowWidget extends StatelessWidget {
  final String fullPath;

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(fullPath); // FORBIDDEN in widgets
    final dir = p.dirname(fullPath);       // FORBIDDEN in widgets
  }
}
```

### Prefer StatelessWidget

Use `StatefulWidget` ONLY for:

- Mouse-hover tracking
- Animation controllers
- Focus node management
- Prototyping form state (must migrate to Cubit when wired — Principle XII)

---

## Responsive Layout Pattern

### LayoutBuilder Breakpoint Pattern

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 900;
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 8, child: MainContentWidget()),
          SizedBox(width: 16.w),
          Expanded(flex: 4, child: SidePanel()),
        ],
      );
    }
    return Column(
      children: [
        MainContentWidget(),
        SizedBox(height: 16.h),
        SidePanel(),
      ],
    );
  },
)
```

### ScreenUtil Usage Rules

**Design size**: `Size(1600, 1000)` — initialized in `main.dart` via `ScreenUtilInit`.

| Use `.w/.h/.sp/.r` for                       | NEVER use for                  |
| -------------------------------------------- | ------------------------------ |
| Padding: `EdgeInsets.all(24.r)`              | `Expanded` children            |
| Spacing: `SizedBox(width: 16.w)`             | `Flexible` children            |
| Font sizes: `TextStyle(fontSize: 14.sp)`     | `LayoutBuilder` constraints    |
| Border radius: `BorderRadius.circular(12.r)` | Naturally unbounded dimensions |
| Icon size: `Icon(Icons.search, size: 20.r)`  | `MediaQuery` values            |
| Fixed decorative elements                    | Any dynamically computed size  |

**`const` rule**: NEVER apply `const` to children lists containing ScreenUtil values (`.w`, `.h`, `.r`, `.sp`) — they are resolved at runtime.

```dart
// WRONG — will not compile
const children: [
  SizedBox(height: 16.h), // runtime value
]

// CORRECT
children: [
  SizedBox(height: 16.h),
]
```

---

## Theme-Driven Styling

### Color Rules

```dart
// CORRECT — all colors from theme
final colorScheme = Theme.of(context).colorScheme;

Container(
  color: colorScheme.surfaceContainerLow,
  child: Icon(icon, color: colorScheme.primary),
)

// Alpha modification is allowed (Principle XIII)
Container(color: colorScheme.primaryContainer.withAlpha(80))

// WRONG — hardcoded color literal
Container(color: Colors.blue)                    // FORBIDDEN
Container(color: Color(0xFF2196F3))              // FORBIDDEN
Container(color: Colors.grey.withAlpha(80))      // FORBIDDEN — base must be theme-sourced
```

### Text Style Rules

```dart
// CORRECT — all text styles from theme
final textTheme = Theme.of(context).textTheme;

Text(
  'Scan Complete',
  style: textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.w700,
  ),
)

// WRONG — inline TextStyle
Text('Scan Complete', style: TextStyle(fontSize: 24, color: Colors.black))
```

### String Constants

All user-facing text MUST come from `lib/values/app_strings.dart`:

```dart
// CORRECT
Text(AppStrings.scanProgressAnalysing)

// WRONG
Text('Analysing files…')
```

---

## Section-Based Screen Composition

Every screen MUST be divided into independent layout sections:

```dart
// Screen entry point composes sections
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderSection(),
        Expanded(child: ContentSection()),
        const FooterSection(),
      ],
    );
  }
}
```

Shell-level sections (sidebar, header, footer) live in `lib/views/`:

- `header_section_widget.dart`
- `sidebar_section_widget.dart`
- `footer_section_widget.dart`

Module-specific sections live in `lib/modules/<module>/widgets/`.

---

## Checklist

- [ ] Widget file placed in correct folder (`views/` vs `modules/<x>/widgets/`)
- [ ] File name uses `*_widget.dart` suffix
- [ ] Widget is `StatelessWidget` (or justified `StatefulWidget`)
- [ ] All data received via constructor parameters — no repository calls
- [ ] No path parsing, size formatting, or data transformation in widget
- [ ] No `Colors.*` literals or inline `TextStyle` — all from `Theme.of(context)`
- [ ] ScreenUtil used only for padding, spacing, fonts, fixed elements
- [ ] ScreenUtil NOT used on `Expanded`/`Flexible`/`LayoutBuilder` dimensions
- [ ] No `const` on children lists with ScreenUtil values
- [ ] User-facing strings from `AppStrings`, not hardcoded
- [ ] Screen widget returns body content only — no shell wrapping
- [ ] File does not exceed 500 lines
- [ ] Responsive breakpoint used for wide/narrow layouts via `LayoutBuilder`
