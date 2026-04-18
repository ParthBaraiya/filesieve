# 🧠 Copilot Instructions – Flutter Desktop Duplicate File Finder (Windows)

## 🎯 Project Goal

Build a high-performance **Windows desktop application** using Flutter that scans directories, detects duplicate files (exact + optional similar), and allows safe cleanup.

The app must be:

- Fast (parallel + cached operations)
- Scalable (large file systems)
- Maintainable (strict architecture)
- Offline-first

---

# 🏗️ Tech Stack

- Flutter (Desktop – Windows)
- State Management: Bloc (Cubit)
- Local DB: ObjectBox
- Serialization: Freezed + JSON
- Native Integration: FFI (C/C++ for hashing/comparison)
- Concurrency: Dart Isolates
- Responsive Utility: flutter_screenutil

---

# 📁 Folder Structure (STRICT)

```id="pvrbgc"
lib/
 ├── repository/
 ├── values/
 ├── utils/
 ├── modules/
 ├── views/
 ├── models/
```

---

# 📦 Folder Responsibilities

## 🔹 repository/

- Handles:
  - Database operations (ObjectBox)
  - Native (FFI) calls
  - File system interactions

- Must NOT contain UI logic

---

## 🔹 values/

- Constants, enums, strings, configs only
- No logic

---

## 🔹 utils/

- Extensions, helpers, mixins, utilities

---

## 🔹 modules/

- Feature-based modules organized by navigation

---

## 🔹 views/

- Reusable UI components ONLY

---

## 🔹 models/

- Freezed-based data models

---

# 🧾 Naming Conventions (STRICT)

```id="naming_all"
*_screen.dart
*_screen_cubit.dart
*_screen_state.dart
*_model.dart
*_repository.dart
```

---

# 🧠 Architecture Rules

## Unidirectional Flow

```id="flow_main"
UI → Cubit → Repository → Data Source
```

- UI never talks directly to repository

---

## Responsibilities

### Cubit

- State management
- Business logic coordination

### Repository

- Data operations
- FFI + DB + file system

---

# ⚡ Performance Rules

- Group by size first
- Partial hash → Full hash
- Use caching (ObjectBox)
- Use isolates
- Minimize FFI calls
- Lazy execution only

---

# 🧩 FFI Rules

- Only CPU-heavy work in C++
- Dart controls flow

---

# 🗄️ ObjectBox Rules

Store:

```id="objectbox_fields"
path
size
lastModified
partialHash
fullHash
```

---

# 🧪 State Rules

- Immutable (Freezed)
- Explicit states only

---

# 🎨 UI Rules

- Never block UI thread
- Always show progress
- Keep UI clean and minimal

---

# 🧱 Widget Structure Rules (CRITICAL)

## 1. Break Large Screens

- Any screen >200 lines must be split
- Divide UI into logical sections

---

## 2. Reusability First

- Reusable → `views/`
- Module-specific → `modules/<module>/widgets/`

---

## 3. Folder Structure for Widgets

```id="widget_structure"
modules/scanner/widgets/
views/
```

---

## 4. Widget Naming

```id="widget_naming"
*_widget.dart
```

---

## 5. Single Responsibility

Each widget:

- One purpose only
- Receives data via params
- No business logic

---

## 6. Avoid Deep Nesting

- Extract nested UI into smaller widgets

---

## 7. Prefer Stateless Widgets

- Use Cubit for state

---

# 📱 Responsive Design Rules (NEW – VERY IMPORTANT)

## 1. Design UI in Sections (Future-Proofing)

- Every screen must be divided into **independent layout sections**
- Each section should be a separate widget

Example:

```id="responsive_example"
HeaderSection
SidebarSection
ContentSection
FooterSection
```

👉 This ensures easy future conversion to:

- Tablet layout
- Different window sizes
- Split view / resizable UI

---

## 2. Avoid Hardcoded Layouts

❌ Do NOT:

- Hardcode widths/heights for entire screens
- Use fixed pixel-based layouts everywhere

✅ Instead:

- Use flexible layouts:
  - Expanded
  - Flexible
  - LayoutBuilder
  - MediaQuery (only when necessary)

---

## 3. Prepare for Window Resizing (Desktop)

- UI must adapt to:
  - Small window
  - Large window
  - Ultra-wide layouts

---

## 4. ScreenUtil Usage (MANDATORY)

Use `flutter_screenutil` for scaling:

### Initialization:

```id="screenutil_init"
ScreenUtilInit(
  designSize: Size(1600, 1000),
)
```

---

### Usage Rules:

- Width:

```id="w_usage"
100.w
```

- Height:

```id="h_usage"
50.h
```

- Font:

```id="sp_usage"
16.sp
```

- Radius:

```id="r_usage"
12.r
```

---

## 5. When NOT to Use ScreenUtil

- Do NOT use `.w/.h` for:
  - Flexible layouts (Expanded/Flex)
  - Dynamic constraints

👉 Use it only for:

- Padding
- Spacing
- Font sizes
- Fixed UI elements

---

## 6. Layout Abstraction

- Separate layout logic from UI components
- If layout becomes complex → create layout widgets

---

## 7. Future Responsive Scaling Strategy

Ensure:

- Widgets can be rearranged easily
- Layouts are composable
- No tight coupling between sections

---

# 🔁 Reusability Rules

- UI reused twice → move to `views/`
- Logic reused → `utils/`

---

# 🚫 Anti-Patterns

- Large monolithic screens
- Hardcoded layouts
- Business logic in UI
- Blocking UI thread
- Deep nested widgets

---

# 🚀 Feature Guidelines

## Duplicate Detection

- Exact: size + hash

## File Safety

- Use recycle bin

---

# 🧭 Suggested Modules

```id="modules_list"
modules/
 ├── home/
 ├── scanner/
 ├── results/
 ├── settings/
```

---

# 🧩 Example Flow

```id="flow_example"
User selects folders
 → Scan files
 → Group by size
 → Hash (with cache)
 → Detect duplicates
 → Show results
```

---

# 📌 Final Notes

- Always design UI with future responsiveness in mind
- Keep widgets modular and composable
- Prefer scalable layouts over fixed ones
- Performance and maintainability are top priority

---
