# Business Rules: Unit 1 — Core Editor Engine

## BR-01: Paragraph-Level Delayed Rendering

| Rule | Description |
|------|-------------|
| BR-01.1 | When the cursor is inside a structural block, that block MUST display raw Markdown syntax with syntax highlighting |
| BR-01.2 | When the cursor leaves a block, that block MUST render as styled output (formatted text, no visible syntax characters) |
| BR-01.3 | Block activation MUST follow ActivationScope rules (see domain-entities.md) |
| BR-01.4 | Only ONE block activation group may be active at a time |
| BR-01.5 | Switching active blocks MUST re-render both the deactivated and newly activated blocks |

---

## BR-02: GFM Element Rendering Rules

### BR-02.1: Headings (h1–h6)
- **Active**: Show `#` prefix characters, plain text, no size change
- **Inactive**: Hide `#` prefix, render text with heading font size (h1 largest → h6 smallest), bold weight

### BR-02.2: Bold
- **Active**: Show `**` or `__` delimiters around text
- **Inactive**: Hide delimiters, render text in bold weight

### BR-02.3: Italic
- **Active**: Show `*` or `_` delimiters
- **Inactive**: Hide delimiters, render text in italic style

### BR-02.4: Strikethrough
- **Active**: Show `~~` delimiters
- **Inactive**: Hide delimiters, render text with strikethrough line

### BR-02.5: Inline Code
- **Active**: Show `` ` `` delimiters
- **Inactive**: Hide delimiters, render in monospace font with background tint

### BR-02.6: Links
- **Active**: Show full `[text](url)` syntax
- **Inactive**: Show "text" as styled link (blue, underline). Cmd+click opens URL in default browser.

### BR-02.7: Images
- **Active**: Show `![alt](src)` syntax
- **Inactive**: Display the image inline (loaded from file path). If image not found, show "Image not found" placeholder with alt text.

### BR-02.8: Fenced Code Blocks
- **Active** (wholeBlock scope): Show opening/closing ` ``` ` fences + language tag + raw content in monospace
- **Inactive**: Hide fences, render content in monospace with syntax highlighting (via Highlightr if language specified). Show language label.

### BR-02.9: Unordered Lists
- **Active** (currentItem): Show `- ` or `* ` prefix for the active item
- **Inactive**: Replace prefix with bullet marker (•), proper indentation for nesting

### BR-02.10: Ordered Lists
- **Active** (currentItem): Show `1. ` prefix for the active item
- **Inactive**: Replace with rendered number + period, proper indentation

### BR-02.11: Task Lists
- **Active** (currentItem): Show `- [ ] ` or `- [x] ` prefix
- **Inactive**: Replace with interactive checkbox widget. Click toggles `[ ]` ↔ `[x]` in source.

### BR-02.12: Tables
- **Active** (wholeBlock scope): Show raw pipe `|` syntax for all rows and separator
- **Inactive**: Render as formatted table with borders, aligned columns, header row styled bold

### BR-02.13: Blockquotes
- **Active** (innerChild): Show `> ` prefix for the active child block only
- **Inactive**: Hide `> ` prefix, render with left border bar and indented styling

### BR-02.14: Horizontal Rules
- **Active**: Show `---` or `***` or `___` source
- **Inactive**: Render as a horizontal divider line

---

## BR-03: IME Composition Handling

| Rule | Description |
|------|-------------|
| BR-03.1 | During IME composition (marked text), the parsing pipeline MUST pause — no re-parse or active block switch |
| BR-03.2 | During IME composition, the active block MUST remain in raw syntax mode (no rendering switch) |
| BR-03.3 | When IME composition commits (marked text finalizes), immediately resume the parse pipeline |
| BR-03.4 | IME composition state is detected via `NSTextInputClient.hasMarkedText()` |

---

## BR-04: Unsupported Extension Fallback

| Rule | Description |
|------|-------------|
| BR-04.1 | LaTeX math (`$...$`, `$$...$$`) MUST be rendered as a fenced code block with language `math` |
| BR-04.2 | Mermaid diagrams (` ```mermaid `) are already fenced code blocks — render with language label "mermaid", no special rendering |
| BR-04.3 | Any fenced code block with an unrecognized language MUST render as plain monospace with the language label displayed |
| BR-04.4 | YAML frontmatter (`---` delimited at document start) MUST be rendered as a code block with language `yaml` |

---

## BR-05: Parse Pipeline Rules

| Rule | Description |
|------|-------------|
| BR-05.1 | Full document re-parse on every text change (after debounce) |
| BR-05.2 | Parse MUST run off main thread (background actor) |
| BR-05.3 | Parse results tagged with documentRevision; stale results (revision < current) MUST be discarded |
| BR-05.4 | Debounce: 50ms after last keystroke before triggering parse |
| BR-05.5 | Diff new parse result against current model; only re-render changed blocks |
| BR-05.6 | RenderCache MUST be invalidated when appearance (light/dark) changes or font settings change |

---

## BR-06: Keyboard Shortcuts

| Shortcut | Action | Implementation |
|----------|--------|---------------|
| Cmd+B | Toggle bold on selection | Wrap/unwrap with `**` |
| Cmd+I | Toggle italic on selection | Wrap/unwrap with `*` |
| Cmd+K | Insert/edit link | Wrap with `[]()`, place cursor in URL |
| Cmd+1 through Cmd+6 | Set heading level | Replace/add `#` prefix on current line |
| Cmd+Shift+K | Toggle inline code | Wrap/unwrap with `` ` `` |

**Toggle logic**: If selection is already wrapped with the formatting delimiter, remove the delimiters. If not, add them.

---

## BR-07: Syntax Highlighting (Active Block)

When a block is active (showing raw syntax), apply subtle coloring to syntax characters:

| Element | Color (Light) | Color (Dark) |
|---------|:---:|:---:|
| `#` heading prefix | Gray (secondary label) | Gray (secondary label) |
| `**` / `__` bold delimiters | Gray (secondary label) | Gray (secondary label) |
| `*` / `_` italic delimiters | Gray (secondary label) | Gray (secondary label) |
| `` ` `` code delimiters | Gray (secondary label) | Gray (secondary label) |
| `[` `]` `(` `)` link syntax | Blue (link color) | Blue (link color) |
| `>` blockquote prefix | Green (accent) | Green (accent) |
| `- ` / `* ` list prefix | Gray (secondary label) | Gray (secondary label) |
| ` ``` ` code fence | Orange (accent) | Orange (accent) |
| `|` table pipe | Gray (secondary label) | Gray (secondary label) |

Use `NSColor.secondaryLabelColor`, `NSColor.linkColor`, and system accent colors for automatic light/dark adaptation.
