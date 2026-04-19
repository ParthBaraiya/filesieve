# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

Verify against [FileSieve Constitution v1.5.0](.specify/memory/constitution.md):

- [ ] **I. Layered Architecture** — Feature follows `UI → Cubit → Repository → Data Source`;
      new files placed in correct canonical folder; naming conventions applied
- [ ] **II. Performance Engineering** — Scan/hash work runs in isolates; staged filtering strategy
      (size → partial hash → full hash) is respected; ObjectBox cache is used before re-hashing
- [ ] **III. Widget Modularity** — No screen exceeds 200 lines; each widget has single responsibility;
      no repository calls from widgets; widgets in correct folder (`views/` vs `modules/<x>/widgets/`)
- [ ] **IV. Responsive Layout** — Screen divided into named section widgets; `ScreenUtil` applied
      correctly (spacing/fonts only, not on `Expanded`/`Flexible`); layout adapts to varied window sizes
- [ ] **V. Immutable State** — All states use `@freezed`; new instance emitted per transition;
      state names are explicit and descriptive
- [ ] **VI. Data Safety** — All deletions route through recycle bin; ObjectBox cache fields updated;
      user confirmation required before destructive operations
- [ ] **VII. Offline-First** — No network calls introduced; all data operations local
- [ ] **VIII. Stitch Integration** — If a Stitch URL was provided, `mcp_stitch_apply_design_system`
      was invoked; generated tokens are registered in `ThemeData` before widget use
- [ ] **IX. Theme-Driven Styling** — No `Colors.*` literals, hex strings, or inline `TextStyle`
      calls in widget trees; all styles sourced from `Theme.of(context)`

**Anti-Pattern Block** (reject feature plan if ANY apply):

- Screen file exceeds 200 lines without extraction
- Widget contains direct repository call
- State mutated in place
- File deleted without recycle-bin
- CPU-bound work on main isolate
- Hardcoded pixel dimensions for containers
- ScreenUtil `.w`/`.h` on `Expanded`/`Flexible` child
- Stitch URL provided but `mcp_stitch_apply_design_system` not invoked
- `Colors.*` literal or inline `TextStyle` used directly in a widget tree

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |
