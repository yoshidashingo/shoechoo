# Business Logic Model: Unit 1 — Core Editor Engine

## Pipeline Overview

```
User types / edits text
    |
    v
[1] Text Change Detection
    | NSTextView delegate callback
    | Increment documentRevision
    v
[2] Full Document Parse (debounced, off-main-thread)
    | MarkdownParser.parse(sourceText) → Markup AST
    | Convert AST → [EditorNode] with stable IDs
    | Tag result with documentRevision
    v
[3] Diff & Merge
    | Compare new [EditorNode] vs current EditorNodeModel.blocks
    | Match by position + contentHash
    | Preserve stable IDs for unchanged blocks
    | Identify: added, removed, modified blocks
    v
[4] Active Block Resolution
    | Map cursor position → source offset
    | Find innermost EditorNode containing cursor
    | Apply ActivationScope rules
    | Mark resolved block as isActive = true
    v
[5] Selective Re-Rendering
    | For each changed or activation-changed block:
    |   if isActive → MarkdownRenderer.renderActiveBlock()
    |   else → MarkdownRenderer.render()
    | Unchanged blocks: reuse cached NSAttributedString
    v
[6] TextKit 2 Display Update
    | Replace affected text ranges in NSTextContentStorage
    | TextKit 2 handles layout invalidation for changed ranges only
```

---

## [1] Text Change Detection

**Trigger**: `NSTextStorageDelegate.textStorage(_:didProcessEditing:range:changeInLength:)` or `NSTextViewDelegate.textDidChange(_:)`

**Logic**:
1. Capture new `sourceText` from NSTextView's text storage
2. Increment `documentRevision` (monotonic UInt64)
3. Sync `sourceText` back to `EditorViewModel.sourceText` (for NSDocument persistence)
4. Schedule parse with debounce (see Business Rules)

---

## [2] Full Document Parse

**Input**: `sourceText: String`, `revision: DocumentRevision`

**Logic**:
1. Call `MarkdownParser.parse(sourceText)` → `Markup` (swift-markdown AST)
2. Walk AST depth-first, converting each block-level node to `EditorNode`:
   - `Heading` → `.heading(level:)`
   - `Paragraph` → `.paragraph`
   - `CodeBlock` → `.codeBlock(language:)`
   - `UnorderedList` → `.unorderedList` with child `.listItem` nodes
   - `OrderedList` → `.orderedList` with child `.listItem` nodes
   - `ListItem` with checkbox → `.taskListItem(isChecked:)`
   - `BlockQuote` → `.blockquote` with child blocks
   - `Table` → `.table` with child `.tableRow` nodes
   - `ThematicBreak` → `.horizontalRule`
   - `Image` at block level → `.image(src:, alt:)`
3. For each block, extract inline runs by walking child inline nodes:
   - `Strong` → `.bold`
   - `Emphasis` → `.italic`
   - `Strikethrough` → `.strikethrough`
   - `InlineCode` → `.inlineCode`
   - `Link` → `.link(url:)`
   - `Image` → `.image(src:, alt:)`
   - `Text` → `.text`
4. Compute `contentHash` for each block (hash of source text in range)
5. Set `activationScope` based on `BlockKind` (see domain-entities.md)
6. Return `ParseResult(revision: revision, blocks: newBlocks)`

**Concurrency**: Run on a background actor. Check `revision >= currentRevision` before applying result; discard if stale.

---

## [3] Diff & Merge

**Input**: `ParseResult` (new), `EditorNodeModel` (current)

**Logic**:
1. Guard: if `parseResult.revision < editorNodeModel.documentRevision`, discard (stale)
2. Walk both arrays in parallel (position-based diff):
   - **Same position, same contentHash**: Unchanged — preserve existing `EditorNode.id`, reuse cached render
   - **Same position, different contentHash**: Modified — preserve `id`, update content, mark for re-render
   - **New block at position**: Added — assign new UUID
   - **Block missing from new list**: Removed — discard
3. Update `editorNodeModel.blocks` with merged result
4. Update `editorNodeModel.documentRevision`

**Note**: Position-based diff is sufficient for MVP. Longest common subsequence (LCS) diff can be added post-MVP for better ID stability during block insertion/deletion.

---

## [4] Active Block Resolution

**Input**: `cursorPosition: Int` (UTF-16 offset in text storage), `EditorNodeModel`

**Logic**:
1. Convert `cursorPosition` (UTF-16) to `String.Index` in source text
2. Find all blocks whose `sourceRange` contains the cursor position
3. Select the **innermost** block (deepest nesting level):
   - e.g., cursor in a blockquote paragraph → select the paragraph, not the blockquote
4. Apply `ActivationScope` rule:
   - `.selfOnly`: activate only this block
   - `.wholeBlock`: activate this block AND all sibling blocks in the same container (e.g., all rows in a table)
   - `.currentItem`: activate only this list item
   - `.innerChild`: activate only this child within the container
5. Set `isActive = true` on resolved block(s), `false` on all others
6. If `activeBlockID` changed from previous value, mark both old and new blocks for re-rendering

---

## [5] Selective Re-Rendering

**Input**: List of block IDs that need re-rendering (from diff + activation change)

**Logic**:
1. For each block ID in the re-render list:
   - Fetch `EditorNode` from model
   - If `isActive`: call `MarkdownRenderer.renderActiveBlock(block, appearance)`
     - Returns NSAttributedString with raw Markdown syntax + subtle syntax highlighting
   - If not `isActive`: call `MarkdownRenderer.render(block, appearance)`
     - Returns NSAttributedString with styled output (bold rendered, headings sized, etc.)
2. Cache the `RenderResult` per block ID
3. For blocks NOT in re-render list: reuse cached `RenderResult`

---

## [6] TextKit 2 Display Update

**Input**: Changed `RenderResult` entries with their source ranges

**Logic**:
1. For each changed block:
   - Map `EditorNode.sourceRange` to `NSTextContentStorage` range
   - Replace attributed string content for that range
   - TextKit 2 automatically invalidates layout for affected text elements only
2. If focus mode is active: apply dimming (alpha reduction) on non-active block ranges
3. If typewriter scrolling is active: scroll to center the active line

---

## Debounce Strategy

| Event | Debounce | Rationale |
|-------|----------|-----------|
| Text edit → Parse | 50ms | Avoid parsing on every keystroke; 50ms is imperceptible |
| Cursor move → Active block switch | 0ms (immediate) | Active block must update instantly for responsive UX |
| IME composition start | Pause parsing | Do not re-parse or change active block during IME composition |
| IME composition end | Immediate parse | Resume normal pipeline |

---

## Render Cache Strategy

```swift
class RenderCache {
    private var cache: [EditorNode.ID: RenderResult] = [:]

    func get(_ id: EditorNode.ID) -> RenderResult?
    func set(_ id: EditorNode.ID, result: RenderResult)
    func invalidate(_ id: EditorNode.ID)
    func invalidateAll()
}
```

- Cache is per-document (owned by EditorViewModel)
- Invalidated on: block content change, appearance change (light↔dark), font/spacing change
- Full invalidation on: theme change, font change, document reload
