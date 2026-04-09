<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0 (MINOR — two new principles added)
Added principles:
  - VIII. Stitch Design System Integration
  - IX. Theme-Driven Styling (NON-NEGOTIABLE)
Modified sections:
  - Tech Stack & Tooling Standards — added Stitch row
  - Development Workflow: Feature Implementation Order — added Stitch step
  - Development Workflow: Anti-Pattern Checklist — added 2 new block items
Templates updated:
  - .specify/templates/constitution-template.md  ✅ source (no change required)
  - .specify/templates/plan-template.md          ✅ Constitution Check gates updated
  - .specify/templates/spec-template.md          ✅ aligned (no mandatory section changes)
  - .specify/templates/tasks-template.md         ✅ aligned (no mandatory section changes)
Deferred TODOs: none
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
- `flutter_screenutil` MUST be initialised with `designSize: Size(1440, 900)` as the reference
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
| Responsive Scaling      | `flutter_screenutil` (design size 1440×900)                |
| Design System Codegen   | Stitch (`mcp_stitch_apply_design_system` MCP)              |
| Styling Source of Truth | `ThemeData` / `ColorScheme` / `TextTheme` in `lib/values/` |

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
6. Verify responsiveness at 1024×768, 1440×900, and 1920×1080

### Anti-Pattern Checklist (block merge if any are true)

- [ ] Screen file exceeds 200 lines without widget extraction
- [ ] Widget contains direct repository call
- [ ] State mutated in place (no new instance emitted)
- [ ] File deleted without recycle-bin intermediary
- [ ] CPU-bound work executing on the main isolate
- [ ] Hardcoded pixel dimensions used for container-level layout
- [ ] ScreenUtil `.w`/`.h` applied to an `Expanded` or `Flexible` child
- [ ] Stitch URL provided but `mcp_stitch_apply_design_system` was not invoked
- [ ] Color literal (`Colors.*` or hex) or inline `TextStyle` used directly in a widget tree

### Module Boundary Rules

- `modules/home/` — launch screen, directory selection
- `modules/scanner/` — scan progress, real-time feedback
- `modules/results/` — duplicate display, selection, bulk actions
- `modules/settings/` — user preferences, scan configuration

Cross-module navigation MUST go through a routing layer; modules MUST NOT import each other directly.

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

**Version**: 1.1.0 | **Ratified**: 2026-04-09 | **Last Amended**: 2026-04-09
