---
layout: default
---

# Unit Dependencies: Shoe Choo

## Dependency Matrix

| Unit | Depends On | Can Parallel With |
|------|-----------|-------------------|
| Unit 1: Core Editor Engine | — (no dependencies) | — |
| Unit 2: Document Management | Unit 1 | — |
| Unit 3: Focus & Immersion | Unit 1 | Unit 2, Unit 4, Unit 5 |
| Unit 4: Image & Media | Unit 1, Unit 2 | Unit 3, Unit 5 |
| Unit 5: Export & Polish | Unit 1, Unit 2 | Unit 3, Unit 4 |

## Dependency Graph

```
Unit 1: Core Editor Engine
    |
    +---> Unit 2: Document Management
    |         |
    |         +---> Unit 4: Image & Media
    |         |
    |         +---> Unit 5: Export & Polish
    |
    +---> Unit 3: Focus & Immersion
```

## Critical Path

```
Unit 1 --> Unit 2 --> Unit 5 --> Integration
```

Unit 1 (Core Editor Engine) is the sole blocker. Once Unit 1 is complete, Units 2-5 can be developed with moderate parallelism (Unit 3 needs only Unit 1; Units 4 and 5 need both Unit 1 and Unit 2).

## Integration Points

| From | To | Integration Type |
|------|----|-----------------|
| Unit 1 → Unit 2 | EditorViewModel uses MarkdownParser, EditorNodeModel, MarkdownRenderer | Direct code dependency |
| Unit 1 → Unit 3 | WYSIWYGTextView exposes focus/typewriter methods | Same class extension |
| Unit 2 → Unit 4 | MarkdownDocument provides assets directory; EditorViewModel inserts image references | Method calls via ViewModel |
| Unit 2 → Unit 5 | EditorViewModel triggers export; SidebarView reads NSDocumentController | Method calls + framework API |
| Unit 1 → Unit 5 | ExportService reuses MarkdownParser for HTML generation | Service reuse |

## Shared Components

| Component | Used By Units | Ownership |
|-----------|:---:|-----------|
| C-03 EditorViewModel | 1, 2, 3, 4 | Unit 2 (created), extended by others |
| C-04 EditorSettings | 2, 3, 5 | Unit 2 (created), read by others |
| C-08 WYSIWYGTextView | 1, 3, 4 | Unit 1 (created), extended by Unit 3, 4 |
| C-13 FileService | 2, 4 | Unit 2 (created), used by Unit 4 |
