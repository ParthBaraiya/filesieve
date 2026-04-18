# Skill: Freezed State Management & Cubit Patterns

**Applies when**: Creating or modifying Cubit classes, Freezed state models, or any business logic coordination in `modules/<module>/`.

**Constitution references**: Principle I (Layered Architecture), Principle V (Immutable State), Principle XI (Cubit Accumulator), Principle XII (Ephemeral Form State), Principle XV (Incremental Pipeline Results)

---

## Freezed State Class Template

Every state MUST be a `@freezed sealed class` with explicit named variants:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<feature>_screen_state.freezed.dart';

@freezed
sealed class FeatureScreenState with _$FeatureScreenState {
  const factory FeatureScreenState.initial({
    @Default(<String>[]) List<String> items,
    @Default(false) bool someFlag,
  }) = FeatureInitial;

  const factory FeatureScreenState.loading({
    required List<String> items,
    @Default(false) bool someFlag,
  }) = FeatureLoading;

  const factory FeatureScreenState.done({
    required List<String> items,
    @Default(false) bool someFlag,
  }) = FeatureDone;

  const factory FeatureScreenState.error({
    required String message,
    required List<String> items,
    @Default(false) bool someFlag,
  }) = FeatureError;
}
```

**Rules**:

- NEVER use generic `loading/loaded/error` wrappers — state names MUST be explicit and descriptive
- Fields shared across variants (accumulated data, config flags) MUST appear on ALL variants
- Use `@Default(...)` for optional fields with sensible defaults
- `part` directive for Freezed codegen is required

---

## Cross-Variant Field Access Extension

ALWAYS provide a Dart extension with exhaustive switch expression getters:

```dart
extension FeatureScreenStateX on FeatureScreenState {
  List<String> get allItems => switch (this) {
    FeatureInitial(:final items) => items,
    FeatureLoading(:final items) => items,
    FeatureDone(:final items) => items,
    FeatureError(:final items) => items,
  };

  bool get someFlag => switch (this) {
    FeatureInitial(:final someFlag) => someFlag,
    FeatureLoading(:final someFlag) => someFlag,
    FeatureDone(:final someFlag) => someFlag,
    FeatureError(:final someFlag) => someFlag,
  };
}
```

**Why**: Eliminates repeated `is`-checks and casts in UI code. The UI can always call `state.allItems` regardless of current variant.

---

## Cubit Structure Template

```dart
class FeatureScreenCubit extends Cubit<FeatureScreenState> {
  FeatureScreenCubit({
    required SomeRepository repository,
  }) : _repository = repository,
       super(const FeatureScreenState.initial());

  final SomeRepository _repository;

  // Private mutable accumulator (Principle XI)
  final List<SomeModel> _items = [];

  // Cancel token — refreshed per operation
  CancelToken _cancelToken = CancelToken();

  @override
  Future<void> close() {
    _cancelToken.cancel();
    return super.close();
  }

  // --- Public methods ---

  void addItem(SomeModel item) {
    if (state is! FeatureInitial) return; // guard clause
    _items.add(item);
    emit(FeatureScreenState.foldersAdded(
      items: List.unmodifiable(_items), // ALWAYS wrap
    ));
  }

  void removeItem(int index) {
    _items.removeAt(index);
    if (_items.isEmpty) {
      emit(const FeatureScreenState.initial());
    } else {
      emit(FeatureScreenState.foldersAdded(
        items: List.unmodifiable(_items),
      ));
    }
  }

  void reset() => emit(const FeatureScreenState.initial());
}
```

---

## Key Rules

### 1. Accumulated Data — `List.unmodifiable()` Always

```dart
// CORRECT
emit(HomeScreenState.foldersAdded(folders: List.unmodifiable(_folders)));

// WRONG — exposes the mutable internal list
emit(HomeScreenState.foldersAdded(folders: _folders));
```

### 2. Transient States Must Carry Accumulated Data

Transient states (drag-hover, error, rejection) MUST NOT drop data:

```dart
// CORRECT — error preserves accumulated folders
emit(HomeScreenState.error(
  message: 'Failed',
  folders: List.unmodifiable(state.allFolders),
));

// WRONG — returning to initial loses all accumulated data
emit(const HomeScreenState.initial());
```

### 3. Dismiss Transient — Context-Aware Reset

```dart
void dismissTransient() {
  final folders = state.allFolders;
  if (folders.isEmpty) {
    emit(const HomeScreenState.initial());
  } else {
    emit(HomeScreenState.foldersAdded(
      folders: List.unmodifiable(folders),
    ));
  }
}
```

### 4. Configuration Flags — Capture Before State Transition

```dart
Future<void> startScan(List<File> files) async {
  // Capture BEFORE emitting scanning — state changes after emit
  final byteCompare = state.byteByByteCompare;

  emit(FeatureScreenState.scanning(
    items: [],
    byteByByteCompare: byteCompare,
  ));

  // ... use byteCompare throughout ...
}
```

### 5. Toggle Flags Across Variants via copyWith

```dart
void setByteCompare(bool value) {
  if (state.byteByByteCompare == value) return;
  final s = state;
  emit(switch (s) {
    FeatureInitial() => s.copyWith(byteByByteCompare: value),
    FeatureLoading() => s.copyWith(byteByByteCompare: value),
    FeatureDone() => s.copyWith(byteByByteCompare: value),
    FeatureError() => s.copyWith(byteByByteCompare: value),
  });
}
```

---

## Progress Bridging Pattern

When the Cubit bridges a background operation's progress to the UI:

```dart
onProgress: (sp) {
  emit(
    (state as FeatureScanning).copyWith(
      progress: sp,
      currentFilePath: sp.currentPath,
      overallPercent: _computeOverallPercent(sp, ...),
    ),
  );
},
```

**Weighted overall percent mapping**:

```dart
double _computeOverallPercent(ScanProgress sp, double current) {
  final ratio = sp.stageTotal == 0
      ? 0.0
      : (sp.stageProcessed / sp.stageTotal).clamp(0.0, 1.0);
  return switch (sp.stage) {
    'scanning' => ratio * 10.0,
    'partial'  => 10.0 + ratio * 40.0,
    'full'     => 50.0 + ratio * 40.0,
    'compare'  => 90.0 + ratio * 9.0,
    'done'     => 100.0,
    _          => current,
  };
}
```

---

## Display-Layer Model Creation

The Cubit MUST transform domain models into display-ready models. The UI MUST NOT:

- Call `p.basename()` or `p.dirname()`
- Call `formatBytes()`
- Parse file extensions

```dart
// CORRECT — in the Cubit's onGroupFound callback:
onGroupFound: (group, sizes) {
  final newEntries = <ScanDuplicateEntryModel>[];
  for (int i = 1; i < group.paths.length; i++) {
    newEntries.add(ScanDuplicateEntryModel(
      path: group.paths[i],
      fileName: p.basename(group.paths[i]),
      parentPath: p.dirname(group.paths[i]),
      sizeBytes: sizes[i],
      matchPercent: 100,
    ));
  }
  emit((state as FeatureScanning).copyWith(
    liveEntries: List.unmodifiable([
      ...(state as FeatureScanning).liveEntries,
      ...newEntries,
    ]),
  ));
},
```

---

## Ephemeral Form State (Principle XII)

During prototyping, form UI MAY use `StatefulWidget` with `setState()`:

```dart
// Acceptable during prototyping only
class _FilterPanel extends StatefulWidget { /* ... */ }
class _FilterPanelState extends State<_FilterPanel> {
  bool _showImages = true;
  // ...
}
```

**Migration rule**: Once the data flow is wired (Cubit → Repository → execution), form state MUST move into the Cubit. `StatefulWidget` is ONLY acceptable for:

- Mouse-hover tracking
- Animation controllers
- Focus management

---

## Checklist

- [ ] State class is `@freezed sealed class` with explicit named variants
- [ ] All shared fields appear on every variant with `@Default`
- [ ] Extension provides cross-variant accessors via switch expressions
- [ ] Cubit wraps accumulated data with `List.unmodifiable()`
- [ ] Transient states carry accumulated data
- [ ] Config flags captured BEFORE emitting scanning state
- [ ] Display-layer models created in Cubit, not in widgets
- [ ] `close()` cancels any active `CancelToken`
