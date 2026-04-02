# Domain Entities: Unit 1 — Core Editor Engine

## EditorNode (Block-Level)

The fundamental unit of the intermediate editing model. Each EditorNode represents one structural block in the Markdown document.

```swift
struct EditorNode: Identifiable, Equatable {
    let id: UUID
    var kind: BlockKind
    var sourceRange: Range<String.Index>
    var contentHash: Int                    // For diff-based incremental re-rendering
    var inlineRuns: [InlineRun]
    var isActive: Bool                      // Cursor is in this block
    var activationScope: ActivationScope    // Rule for what "active" means
}
```

### BlockKind

```swift
enum BlockKind: Equatable {
    case paragraph
    case heading(level: Int)                // 1-6
    case codeBlock(language: String?)       // Fenced code block
    case unorderedList
    case orderedList
    case listItem(marker: ListMarker)
    case taskListItem(isChecked: Bool)
    case blockquote
    case table
    case tableRow
    case horizontalRule
    case image(src: String, alt: String)
}

enum ListMarker: Equatable {
    case bullet                             // -, *, +
    case ordered(start: Int)                // 1., 2., etc.
}
```

### ActivationScope

Defines what portion of the document shows raw syntax when the cursor is inside a block.

```swift
enum ActivationScope {
    case selfOnly           // paragraph, heading, horizontal rule
    case wholeBlock         // code block (fence + content), table (all rows)
    case currentItem        // list item (not entire list)
    case innerChild         // blockquote → activate only the child block containing cursor
}
```

**Scope Rules by BlockKind:**

| BlockKind | ActivationScope | Rationale |
|-----------|:---:|-----------|
| paragraph | selfOnly | Single block, no children |
| heading | selfOnly | Single line, no children |
| codeBlock | wholeBlock | Fence syntax + content must be visible together |
| table | wholeBlock | Pipe syntax across rows must be visible together |
| listItem | currentItem | Show only current item raw, not entire list |
| taskListItem | currentItem | Same as listItem |
| blockquote | innerChild | Show only the child block (paragraph/list) containing cursor |
| horizontalRule | selfOnly | Single line |
| image | selfOnly | Show `![alt](src)` syntax |

---

## InlineRun

Represents an inline formatting span within a block.

```swift
struct InlineRun: Equatable {
    var type: InlineType
    var range: Range<String.Index>      // Range within the block's source text
}

enum InlineType: Equatable {
    case text                           // Plain text (no formatting)
    case bold                           // **text** or __text__
    case italic                         // *text* or _text_
    case boldItalic                     // ***text***
    case strikethrough                  // ~~text~~
    case inlineCode                     // `code`
    case link(url: String)              // [text](url)
    case image(src: String, alt: String)// ![alt](src)
    case lineBreak                      // Hard line break
}
```

---

## EditorNodeModel

The per-document intermediate model holding the ordered list of blocks.

```swift
class EditorNodeModel {
    var blocks: [EditorNode]
    var documentRevision: UInt64        // Monotonic counter, incremented on each edit

    // Metrics
    var blockCount: Int { blocks.count }
    var activeBlockID: EditorNode.ID?
}
```

---

## RenderResult

Output of the rendering pipeline for a single block.

```swift
struct RenderResult {
    var blockID: EditorNode.ID
    var attributedString: NSAttributedString
    var isActive: Bool                  // Raw syntax vs styled
}
```

---

## ParseResult

Output of a full-document parse, used for diffing.

```swift
struct ParseResult {
    var revision: UInt64
    var blocks: [EditorNode]            // New block list from fresh parse
}
```

---

## DocumentRevision

Used to discard stale parse results when a newer edit has occurred.

```swift
struct DocumentRevision: Comparable {
    let value: UInt64
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.value < rhs.value }
}
```
