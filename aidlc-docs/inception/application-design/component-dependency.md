# Component Dependencies: Shoe Choo

## Dependency Matrix

| Component | Depends On | Depended By |
|-----------|-----------|-------------|
| C-01 ShoechooApp | C-02, C-04, C-09, C-10 | — (entry point) |
| C-02 MarkdownDocument | C-03, C-13 | C-01 |
| C-03 EditorViewModel | C-04, C-05, C-06, C-07, C-11, C-12 | C-02, C-08, C-09 |
| C-04 EditorSettings | — | C-01, C-03, C-07, C-09 |
| C-05 MarkdownParser | — (swift-markdown) | C-03, C-06 |
| C-06 EditorNodeModel | — | C-03, C-07 |
| C-07 MarkdownRenderer | C-04, C-06 | C-03 |
| C-08 WYSIWYGTextView | C-03, C-04 | C-09 |
| C-09 EditorView | C-03, C-04, C-08 | C-01 |
| C-10 SidebarView | — | C-01 |
| C-11 ExportService | — (swift-markdown, WebKit) | C-03 |
| C-12 ImageService | C-13 | C-03, C-08 |
| C-13 FileService | — | C-02, C-12 |

## Dependency Graph

```
+----------------+
|  ShoechooApp   |
+-------+--------+
        |
        +---> EditorSettings (shared singleton)
        |
        +---> MarkdownDocument ---> FileService
        |         |
        |         +---> EditorViewModel
        |                   |
        +---> EditorView    +---> MarkdownParser (swift-markdown)
        |         |         |
        |         +-------->+---> EditorNodeModel
        |         |         |         |
        |         +---> WYSIWYGTextView
        |                   |    +---> MarkdownRenderer
        |                   |              |
        |                   +---> ImageService ---> FileService
        |                   |
        |                   +---> ExportService
        |
        +---> SidebarView (independent)
```

## Data Flow

### Editing Flow (primary)
```
User types
    |
    v
WYSIWYGTextView (NSTextView delegate)
    |
    v
EditorViewModel.textDidChange()
    |
    v
MarkdownParser.parse() or parseBlock()
    |
    v
EditorNodeModel.updateBlocks()
    |
    v
MarkdownRenderer.renderFullDocument()
    |
    v
WYSIWYGTextView displays NSAttributedString
```

### Cursor Movement Flow
```
User moves cursor
    |
    v
WYSIWYGTextView detects cursor position
    |
    v
EditorViewModel.cursorDidMove()
    |
    v
EditorNodeModel.setActiveBlock()
    (previous block: render styled)
    (new active block: render raw syntax)
    |
    v
MarkdownRenderer re-renders affected blocks
    |
    v
WYSIWYGTextView updates display
```

### Image Drop Flow
```
User drops image on editor
    |
    v
WYSIWYGTextView.performDragOperation()
    |
    v
ImageService.importDroppedImage()
    |
    +---> FileService.createDirectoryIfNeeded() (assets/)
    +---> Copy image to assets/
    +---> Return relative path
    |
    v
EditorViewModel.insertImage()
    |
    v
Source text updated with ![](path)
    |
    v
Normal editing flow (re-parse, re-render)
```

### Export Flow
```
User triggers Cmd+Shift+E
    |
    v
EditorViewModel.exportHTML() / exportPDF()
    |
    v
ExportService.generateHTML(from: sourceText)
    |
    +---> (for PDF) ExportService.generatePDF(from: html)
    |
    v
Save dialog -> write to disk
```

## Communication Patterns

| Pattern | Used By | Mechanism |
|---------|---------|-----------|
| Observation | EditorViewModel → EditorView | @Observable / SwiftUI binding |
| Delegation | WYSIWYGTextView → EditorViewModel | NSTextViewDelegate + Coordinator |
| Direct call | EditorViewModel → MarkdownParser | Synchronous method call |
| Direct call | EditorViewModel → EditorNodeModel | Synchronous method call |
| Direct call | EditorViewModel → MarkdownRenderer | Synchronous method call |
| Async call | EditorViewModel → ExportService | async/await |
| Async call | WYSIWYGTextView → ImageService | async/await |
| Shared ref | ShoechooApp → EditorSettings | @Observable singleton via @Environment |
