<!--
SYNC IMPACT REPORT
==================
Version change: 1.4.0 → 1.5.0 (MINOR — added Dependency Injection principle and DI tooling)
Modified sections:
  - Added Principle XVI — Dependency Injection & Service Registration
  - Tech Stack & Tooling Standards — added Dependency Injection: get_it
  - Module Boundary Rules — clarified `FsPickerBase` usage and DI expectations
  - Templates updated:
    - .specify/templates/plan-template.md ✅ updated (Constitution Check now references v1.5.0)
Previously added (v1.4.0):
  - Principles XI–XV (infrastructure, isolate, and pipeline rules)
Templates requiring review:
  - .specify/templates/plan-template.md ✅ updated
Follow-up TODOs:
  - Ensure CI and developer README list `get_it` and show `lib/di/service_locator.dart` usage
-->

# FileSieve Constitution

## Core Principles

### I. Strict Layered Architecture (NON-NEGOTIABLE)

The application MUST follow a unidirectional data flow with no shortcuts:

```
UI → Cubit → Repository → Data Source
```

- Every feature MUST reside within one of the canonical folders:
  `lib/repository/`, `lib/values/`, `lib/utils/`, `lib/modules/`, `lib/views/`, `lib/models/`
- UI layers MUST NOT directly call repository or data-source code
- Cubits coordinate business logic; repositories own all data operations (ObjectBox, FFI, filesystem)
- Naming conventions MUST be followed without exception:
  `*_screen.dart`, `*_screen_cubit.dart`, `*_screen_state.dart`, `*_model.dart`, `*_repository.dart`

**Rationale**: Enforces separation of concerns and enables independent testing of each layer without UI dependencies.

### II. Performance Engineering by Design

Duplicate detection MUST apply a staged efficiency strategy; skipping stages is forbidden:

1. **Group by file size** — cheapest filter; eliminates non-matches without any I/O beyond metadata
2. **Partial hash** — read only the first N bytes (configurable); compare within size groups
3. **Full hash** — only for files that match on partial hash
4. **ObjectBox cache** — cache `partialHash` and `fullHash` keyed by `(path, size, lastModified)`;
   skip re-hashing on unchanged files
5. **Dart Isolates** — all hashing and scanning work MUST run in isolates; never on the UI thread
6. **FFI for CPU-heavy work** — C/C++ via FFI for hashing algorithms; Dart controls flow and
   orchestration but MUST NOT implement CPU-bound tight loops itself
7. **Lazy execution** — operations MUST NOT run until explicitly triggered by the user

**Rationale**: A 100 GB drive scan must remain responsive. Each stage reduces the candidate set before
applying a more expensive operation.

### III. Widget Modularity & Single Responsibility

Every screen and widget MUST follow these rules:

- Any screen exceeding **500 lines** MUST be split into sub-widgets
- Each widget MUST serve exactly one purpose and receive all data via constructor parameters
- No business logic inside widgets — delegate to Cubit
- Module-specific widgets live under `modules/<module>/widgets/`; reusable widgets live in `views/`
- A widget reused in two or more places MUST be promoted to `views/`
- Avoid deeply nested widget trees — extract sub-trees into named widgets
- All widget files MUST use the `*_widget.dart` suffix
- Prefer `StatelessWidget`; use `StatefulWidget` only when local ephemeral state is unavoidable
  and Cubit would be overkill

**Rationale**: Modular widgets are independently testable, easier to refactor, and prevent the
monolithic screen anti-pattern that creates maintenance debt.

### IV. Responsive-First Layout (Desktop Windows)

Every screen MUST be designed as a composition of independent layout sections:

- Screens MUST be divided into named section widgets (e.g., `HeaderSection`, `SidebarSection`,
  `ContentSection`, `FooterSection`)
- Layouts MUST use flexible widgets (`Expanded`, `Flexible`, `LayoutBuilder`) as the primary
  sizing mechanism; fixed pixel sizes MUST NOT be used for full-screen or container-level layout
- `flutter_screenutil` MUST be initialised with `designSize: Size(1600, 1000)` as the reference
- ScreenUtil scaling (`.w`, `.h`, `.sp`, `.r`) MUST be applied to: padding, spacing, font sizes,
  and fixed-size decorative elements
- ScreenUtil MUST NOT be applied to: `Expanded`/`Flexible` children, `LayoutBuilder` constraints,
  or any dimension that is naturally unbounded
- The UI MUST remain usable and non-overflowing at small, medium, and ultra-wide window sizes

**Rationale**: Windows desktop apps are resized constantly. Hardcoded layouts break at non-design
resolutions and prevent future tablet or split-view adaptations.

### V. Immutable State Management

All Cubit states MUST be immutable value types:

- States MUST be defined using `Freezed` with `@freezed` annotation
- Every state change MUST produce a new state instance — in-place mutation is forbidden
- States MUST be explicit and named (e.g., `ScannerInitial`, `ScannerScanning`, `ScannerDone`,
  `ScannerError`) — generic `loading/loaded/error` wrappers are insufficient
- A Cubit MUST represent exactly one feature screen or coherent interaction flow
- State classes live alongside their cubit in `modules/<module>/`

**Rationale**: Immutable state prevents hidden bugs from shared mutable references and makes state
transitions auditable and reproducible.

### VI. Data Safety & File Operations

All destructive file operations MUST use the system recycle bin:

- Files MUST NEVER be permanently deleted without explicit user confirmation
- Move-to-recycle-bin MUST be used as the default delete mechanism
- The app MUST display what will be deleted and require confirmation before acting
- ObjectBox MUST persist file metadata (`path`, `size`, `lastModified`, `partialHash`, `fullHash`)
  to avoid redundant I/O across sessions
- Cache entries MUST be invalidated when `lastModified` or `size` changes for a given path

**Rationale**: Accidental permanent deletion of legitimate files is unrecoverable and constitutes
a critical user-trust failure.

### VII. Offline-First & No External Dependencies

The application MUST function entirely without network access:

- No remote APIs, telemetry, analytics, or cloud sync
- All data storage is local via ObjectBox
- All computation is local (Dart + FFI)
- No feature may be gated on connectivity

**Rationale**: File management is a fundamentally local task; network dependency would introduce
latency, privacy concerns, and failure modes that degrade the core value proposition.

### VIII. Stitch Design System Integration (NON-NEGOTIABLE)

Whenever a Stitch URL is provided as part of a UI task, the `mcp_stitch_apply_design_system`
MCP tool MUST be invoked to generate the UI code. Manual re-implementation of Stitch-defined
components is forbidden.

- If a Stitch project URL is given, first call `mcp_stitch_get_project` / `mcp_stitch_list_screens`
  to inspect the design, then call `mcp_stitch_apply_design_system` to produce the Flutter code
- The generated code MUST be placed in the correct canonical folder per Principle I
- Generated screens MUST still comply with Principles III (widget modularity) and IV (responsive
  layout) — post-generation refactoring is required if the output violates these rules
- If no Stitch URL is provided, Stitch tooling MUST NOT be invoked speculatively
- Design tokens (colors, typography, spacing) produced by `mcp_stitch_apply_design_system`
  MUST be mapped into `ThemeData` before use (see Principle IX); they MUST NOT be inlined
  directly in widget code

**Rationale**: Stitch is the authoritative source of visual design for this project. Bypassing it
produces drift between design and implementation that is expensive to reconcile.

### IX. Theme-Driven Styling (NON-NEGOTIABLE)

All colors, text styles, and decorative constants MUST be consumed from `ThemeData` / the
app's `Theme`. Hardcoded values in widget trees are forbidden.

- Colors MUST come from `Theme.of(context).colorScheme.*` or named extension properties on
  `ThemeData` — never from `Colors.*` literals or hex strings inlined in widgets
- Text styles MUST come from `Theme.of(context).textTheme.*` — never from standalone
  `TextStyle(...)` calls with hardcoded sizes, weights, or colors
- If a value is not yet in `ThemeData`, it MUST be added there first, then referenced
- The single source of truth for the design system is `AppTheme` (or equivalent) in `lib/values/`
- Theme extensions (e.g., `ThemeExtension<T>`) SHOULD be used for domain-specific tokens
  (e.g., severity colors, scan-status indicators) that have no `ColorScheme` equivalent
- Stitch-generated tokens (from Principle VIII) MUST be registered in `ThemeData` before
  any widget references them

**Rationale**: Centralising styles in `ThemeData` enables single-point theme switching (dark
mode, accessibility overrides, branding updates) without touching individual widgets.

### X. Shell-Based Navigation Architecture (NON-NEGOTIABLE)

All primary app screens MUST be rendered inside a shared `ShellRoute` that owns the
persistent layout chrome (sidebar, header, footer). Individual screens MUST return only
their body content.

- `DashboardScreenContent` is the single shell builder; it derives the active navigation
  item from `GoRouterState.of(context).uri.path` via `NavigationItem.fromRoute()`
- Screen widgets (e.g., `HomeScreen`, `ResultsScreen`) MUST NOT wrap themselves in
  `DashboardScreenContent`, `AppShellWidget`, or any shell/sidebar/header/footer widget.
  They MUST return only the body content for their route
- Every `GoRoute` inside the `ShellRoute` MUST use `pageBuilder` with a
  `CustomTransitionPage` (e.g., `SharedAxisTransitionPage`) — never `builder`, which
  produces a default `MaterialPage` transition that conflicts with the shell
- Every `CustomTransitionPage` MUST receive `key: state.pageKey` so that Flutter's
  Navigator can detect page identity changes and run the transition animation.
  Omitting the key causes the Navigator to treat all pages as identical, silently
  suppressing transitions
- Route path constants MUST be defined in `lib/values/app_routes.dart`; custom
  transition pages MUST be defined in `lib/utils/routes/`
- `NavigationItem` enum MUST expose both `route` (item → path) and
  `fromRoute(String)` (path → item) for bidirectional mapping
- `const` MUST NOT be applied to widget children lists that contain ScreenUtil-scaled
  values (`.w`, `.h`, `.r`, `.sp`), as ScreenUtil values are resolved at runtime and
  cannot be compile-time constants

**Rationale**: A shared shell prevents per-screen duplication of sidebar/header/footer,
ensures consistent navigation state, and avoids the rebuild cost of reinstantiating the
entire layout chrome on every route change. The `pageKey` requirement prevents a class of
silent animation bugs that are difficult to diagnose.

### XI. Cubit Accumulator & Transient State Management

When a Cubit accumulates data across multiple user interactions (e.g., adding folders
one by one, building a selection set), it MUST follow these rules:

- The Cubit MAY maintain a **private mutable collection** (e.g., `final List<T> _items = []`)
  as an internal accumulator. All state emissions MUST wrap the accumulator with
  `List.unmodifiable(...)` — the state itself remains immutable per Principle V
- **All state variants** that can coexist with accumulated data MUST carry the accumulated
  data as a field (use `@Default([])` for transient variants like drag-hover or error).
  The UI MUST NOT lose visibility of accumulated data during transient state transitions
- A **Dart extension** on the Freezed state class SHOULD provide a cross-variant accessor
  (e.g., `allFolders`) using an exhaustive Dart 3 `switch` expression with destructuring.
  This eliminates repeated `is`-checks in the UI layer
- Transient state dismissal methods (e.g., `dismissTransient()`) MUST return to the correct
  resting state based on whether accumulated data exists — never unconditionally to `initial`
- `removeItem(int index)` or equivalent MUST emit `initial` when the accumulator becomes
  empty, and the data-carrying state otherwise

**Rationale**: Drag-and-drop and multi-step configuration flows require incremental data
accumulation. Losing accumulated context during hover, error, or rejection states creates
a confusing user experience and forces re-entry.

### XII. Ephemeral Form State & Cubit Migration Path

Configuration/form UI (checkboxes, sliders, toggles, text fields) that is local to a
single panel MAY use `StatefulWidget` with `setState()` during the **prototyping phase**
when the data is not yet wired to any Cubit or repository.

- Once the feature's data flow is connected (Cubit → Repository → scan execution),
  form state MUST be migrated into the Cubit so it participates in the unidirectional
  flow from Principle I
- `StatefulWidget` remains acceptable for **mouse-hover tracking**, **animation controllers**,
  and other purely visual ephemeral state that has no business-logic consequence
- Private helper widgets (`_FileTypeCheckbox`, `_ToggleRow`, etc.) used only within a
  single file are acceptable and SHOULD receive data via constructor parameters

**Rationale**: Local `setState()` is pragmatic for rapid UI iteration, but form state that
drives business logic (scan configuration, filter parameters) must eventually be centralized
in the Cubit to maintain testability and state auditability.

### XIII. Theme Color Modification Rules

Colors sourced from `Theme.of(context).colorScheme` MAY be modified with `.withAlpha()`
or `.withOpacity()` for transparency effects. This is NOT a violation of Principle IX.

- Modified theme colors (e.g., `colorScheme.primaryContainer.withAlpha(80)`) are acceptable
  because the base token still comes from `ThemeData`
- `Colors.*` literals modified with `.withAlpha()` or `.withOpacity()` remain FORBIDDEN
- If a specific alpha-modified color is used in **three or more places**, it SHOULD be
  extracted into a `ThemeExtension` token rather than repeated inline

**Rationale**: Transparency variants of theme colors are a natural part of layered UI design.
Forbidding them would force unnecessary theme extension boilerplate for one-off decorative use,
while still ensuring the palette remains centrally switchable.

### XIV. Worker Isolate Communication Protocol (NON-NEGOTIABLE)

All long-running operations (scanning, hashing, file comparison) execute in spawned Dart
isolates. Communication between the main isolate and worker isolates MUST follow these rules:

- **ObjectBox sharing**: Worker isolates MUST use `Store.attach(getObjectBoxModel(), storePath)`
  to access the ObjectBox store — never `Store(...)`. The main isolate holds the primary
  `Store` handle; opening a second independent `Store` on the same directory causes file-lock
  contention on Windows. The `storePath` MUST be passed as a `String` in the spawn message
- **Store cleanup**: Worker isolates MUST close their attached `Store` in a `finally` block,
  even on cancellation or error. Failing to close leaves file handles open (FR-017)
- **Cancel handshake**: Cancellation MUST use a two-phase handshake:
  1. The spawn message includes a `cancelHandshakePort: SendPort`
  2. The worker creates a local `ReceivePort`, listens for cancel signals on it, and sends
     its `SendPort` back via `cancelHandshakePort`
  3. The main isolate awaits the worker's `SendPort`, then wires
     `cancelToken.cancelFuture.then((_) => workerCancelSendPort.send('cancel'))`
     The Cubit MUST only call `cancelToken.cancel()` — it MUST NOT touch ports directly
- **Message format**: All worker→main messages MUST be `Map<String, dynamic>` with a `'type'`
  discriminator (e.g., `'progress'`, `'result'`, `'error'`, `'group'`). Non-serializable
  objects (native pointers, `Store`, `Box`, `File`) MUST NOT be sent across isolate boundaries
- **Semaphore-guarded I/O**: Concurrent file-I/O within a worker isolate MUST be bounded by
  a permit-based semaphore (configurable limit, default 4). Unbounded parallelism is forbidden
  (FR-010). Every `acquire()` MUST have a matching `release()` in a `finally` block

**Rationale**: Dart isolates do not share memory. Incorrect ObjectBox access causes file-lock
contention; missing cancel handshakes make scans unstoppable; unserialisable messages cause
silent failures. These patterns were established in spec 001 and must be followed by all
future worker isolate features (e.g., bulk delete, export, thumbnail generation).

### XV. Incremental Pipeline Results & Progress Mapping

Multi-stage background pipelines (e.g., duplicate detection) MUST expose both fine-grained
progress and incremental results to the UI layer:

- **Dual callback contract**: Repository `find()` methods MUST accept both
  `onProgress: void Function(ScanProgress)` for stage-level progress AND
  `onGroupFound: void Function(DuplicateGroup, List<int> sizes)` (or equivalent) for
  incremental result delivery. Results MUST NOT be withheld until pipeline completion
- **Weighted overall percentage**: The Cubit MUST compute a single `overallPercent` (0–100)
  by mapping each pipeline stage's ratio to a weighted band:
  - `scanning` (metadata): 0–10%
  - `partial` (partial hash): 10–50%
  - `full` (full hash): 50–90%
  - `compare` (byte-by-byte): 90–99%
  - `done`: 100%
    Stage weights are approximate and SHOULD be adjusted based on profiling, but every stage
    MUST have a non-zero allocation so the user sees continuous forward progress
- **Display-layer wrapper models**: The Cubit MUST create display-layer models
  (e.g., `ScanDuplicateEntryModel`) from domain models (e.g., `DuplicateGroup`). The UI
  MUST NOT perform path parsing (`p.basename`, `p.dirname`), size formatting, or any
  data transformation — all display-ready data MUST arrive via the Cubit state
- **Current file path**: Progress updates MUST include `currentPath` (the file actively being
  processed) so the UI can display real-time feedback. The path MUST be truncated with
  ellipsis in the UI; the full path lives in state
- **Scan configuration propagation**: Configuration flags that affect pipeline behavior
  (e.g., `byteByByteCompare`) MUST be captured from the current state BEFORE emitting
  the scanning state, and MUST be carried on ALL state variants (initial, scanning, done,
  error, cancelled) so the UI can always read the active configuration

**Rationale**: Users scanning large directories need continuous feedback that the app is
working. Incremental results build trust and let users evaluate partial findings before
completion. Display-layer model creation in the Cubit keeps widgets free of business logic
per Principle III. These patterns were established across specs 001 and 002.

### XVI. Dependency Injection & Service Registration (NON-NEGOTIABLE)

- `get_it` MUST be the canonical dependency-injection / service-locator for the project.
  All singleton and factory registrations MUST be centralised in a single composition
  root file: `lib/di/service_locator.dart` (or equivalent) and invoked once during
  app startup (in `main()` before `runApp()`).

- Register platform adapters by their interface type. Example registration (composition
  root):

  ```dart
  // lib/di/service_locator.dart
  import 'package:get_it/get_it.dart';
  import 'package:filesieve/utils/file_picker/fs_picker.dart';
  import 'package:filesieve/utils/file_picker/fs_picker_base.dart';

  final GetIt getIt = GetIt.instance;

  void setupServiceLocator() {
    getIt.registerLazySingleton<FsPickerBase>(() => FsPicker());
    // register other singletons and factories here
  }
  ```

-- Access rules:

- Constructor injection is MANDATORY for Cubits. Cubits MUST NOT be registered or
  resolved via `get_it`. Cubits must be created by the composition root (or the
  caller) and receive their dependencies (repositories, services, `FsPickerBase`,
  etc.) via constructor parameters. This preserves testability and explicit
  lifecycle management.
- Repositories and services (non-Cubit objects) MAY be registered in `get_it`
  as singletons or factories. When doing so, prefer registering interfaces/types
  (e.g., `FsPickerBase`) rather than concrete classes.
- If global access is unavoidable for tiny utilities, restrict `getIt()` calls to
  the composition root or thin helpers; do NOT call `getIt()` from widget build
  methods or deep business logic.

- Testing:
  - Tests MUST call `getIt.reset()` in `setUp()`/`tearDown()` and register test doubles
    as needed, e.g. `getIt.registerSingleton<FsPickerBase>(FakeFsPicker())`.

- Worker isolate rule: do NOT register non-serialisable objects (ObjectBox `Store`,
  `Box<T>`, `File`, native pointers) for use across isolates. Worker isolates MUST
  receive primitive parameters and attach their own resources per Principle XIV.

- Directory picker binding (mandatory):
  - The canonical abstraction for directory selection is `FsPickerBase`
    (`lib/utils/file_picker/fs_picker_base.dart`). The concrete implementation
    `FsPicker` (`lib/utils/file_picker/fs_picker.dart`) MUST be registered as a
    lazy singleton:

    ```dart
    getIt.registerLazySingleton<FsPickerBase>(() => FsPicker());
    ```

  - Consumers (Cubits / Services) that need directory selection MUST accept an
    `FsPickerBase` instance via constructor injection. UI widgets SHOULD call into
    Cubit methods which use the injected `FsPickerBase` rather than calling `getIt`
    or platform APIs directly.

  **Rationale**: Centralised registration improves testability, makes platform
  substitution straightforward, and avoids duplicated global state across the
  codebase.

## Tech Stack & Tooling Standards

The following technology choices are binding for this project. Substitutions require a
constitution amendment.

| Concern                 | Mandated Technology                                        |
| ----------------------- | ---------------------------------------------------------- |
| UI Framework            | Flutter (Desktop – Windows primary target)                 |
| State Management        | Bloc / Cubit (`flutter_bloc`)                              |
| Local Database          | ObjectBox                                                  |
| Data Models             | Freezed + JSON serialization (`json_serializable`)         |
| Native Integration      | Dart FFI (C/C++ for hashing)                               |
| Concurrency             | Dart Isolates                                              |
| Dependency Injection    | get_it (service-locator / DI composition)                  |
| Responsive Scaling      | `flutter_screenutil` (design size 1600×1000)               |
| Design System Codegen   | Stitch (`mcp_stitch_apply_design_system` MCP)              |
| Styling Source of Truth | `ThemeData` / `ColorScheme` / `TextTheme` in `lib/values/` |
| Routing                 | GoRouter (ShellRoute for persistent shell)                 |
| Route Transitions       | `animations` package (`SharedAxisTransition`)              |

**Dependency addition policy**: New packages MUST be justified against the performance and
maintainability goals. Packages that duplicate capabilities already provided by mandated
technologies MUST NOT be added.

## Development Workflow & Quality Gates

### Feature Implementation Order

Every feature MUST follow this sequence before being considered complete:

1. Define Freezed state model(s)
2. Implement repository layer (data operations only)
3. Implement Cubit (business logic, calls repository)
4. If a Stitch URL is provided: invoke `mcp_stitch_apply_design_system` → map tokens into
   `ThemeData` → place generated widgets in canonical folders
5. Build / refine UI (calls Cubit only; all styles via `ThemeData`; no repository access)
6. Verify responsiveness at 1024×768, 1600×1000, and 1920×1080

### Anti-Pattern Checklist (block merge if any are true)

- [ ] Screen file exceeds 500 lines without widget extraction
- [ ] Widget contains direct repository call
- [ ] State mutated in place (no new instance emitted)
- [ ] File deleted without recycle-bin intermediary
- [ ] CPU-bound work executing on the main isolate
- [ ] Hardcoded pixel dimensions used for container-level layout
- [ ] ScreenUtil `.w`/`.h` applied to an `Expanded` or `Flexible` child
- [ ] Stitch URL provided but `mcp_stitch_apply_design_system` was not invoked
- [ ] Color literal (`Colors.*` or hex) or inline `TextStyle` used directly in a widget tree
- [ ] Screen widget wraps itself in shell/sidebar/header/footer instead of returning body only
- [ ] `CustomTransitionPage` created without `key: state.pageKey`
- [ ] `const` applied to a children list containing ScreenUtil-scaled values
- [ ] Cubit emits accumulated data without `List.unmodifiable()` wrapping
- [ ] Transient state variant (drag-hover, error) drops accumulated data from its fields
- [ ] `dismissTransient()` / reset method unconditionally returns to `initial` when accumulated data exists
- [ ] Form state still in `StatefulWidget.setState()` after feature data flow is wired to Cubit
- [ ] `Colors.*` literal modified with `.withAlpha()` / `.withOpacity()` (must use theme-sourced color)
- [ ] Worker isolate opens ObjectBox via `Store(...)` instead of `Store.attach()` when main isolate holds a Store
- [ ] Worker isolate fails to close `Store` in a `finally` block
- [ ] Non-serializable object (native pointer, Store, Box, File) sent across isolate boundary
- [ ] Semaphore `acquire()` without matching `release()` in `finally` block
- [ ] Pipeline withholds all results until completion instead of streaming via `onGroupFound` callback
- [ ] UI widget performs path parsing, size formatting, or data transformation instead of receiving display-ready data from Cubit state

### Module Boundary Rules

- `modules/home/` — launch screen, directory selection, scan initiation, scan progress UI,
  live duplicate feed. Owns `HomeScreenCubit` which bridges to `DuplicateFinderRepository`
- `modules/scanner/` — standalone scan screen (alternative entry point), scan progress,
  real-time feedback. Owns `ScannerScreenCubit` with independent lifecycle
- `modules/results/` — duplicate display, selection, bulk actions, deletion via recycle bin
- `modules/settings/` — user preferences, scan configuration persistence
- `modules/history/` — past scan session browsing

Directory picker usage:

- Modules that require directory selection MUST rely on the `FsPickerBase` abstraction
  (`lib/utils/file_picker/fs_picker_base.dart`). The concrete `FsPicker`
  implementation (`lib/utils/file_picker/fs_picker.dart`) MUST be registered in the
  composition root (`lib/di/service_locator.dart`) as a lazy singleton and provided to
  Cubits/services via constructor injection. UI widgets SHOULD call Cubit methods that
  use the injected `FsPickerBase` instead of calling `getIt()` or platform APIs
  directly from build methods.

Cross-module navigation MUST go through GoRouter; modules MUST NOT import each other directly.
All primary modules MUST be registered as child routes inside the `ShellRoute` in `main.dart`.

## Governance

This constitution supersedes all other development guidelines and informal conventions for the
FileSieve project.

**Amendment procedure**:

1. Propose change with written rationale referencing the affected principle
2. Assess MAJOR / MINOR / PATCH version bump per semantic versioning rules:
   - MAJOR: removal or backward-incompatible redefinition of a principle
   - MINOR: addition of a new principle or materially expanded guidance
   - PATCH: clarifications, wording, typo fixes
3. Update `LAST_AMENDED_DATE` and `CONSTITUTION_VERSION`
4. Propagate changes to all dependent templates and update this Sync Impact Report comment

**Compliance**: All code reviews MUST verify absence of items on the Anti-Pattern Checklist.
Complexity deviating from these principles MUST be explicitly justified in the PR description.

**Runtime guidance**: See `.github/copilot-instructions.md` for detailed coding conventions and
responsive design usage examples.

**Version**: 1.5.0 | **Ratified**: 2026-04-09 | **Last Amended**: 2026-04-19
