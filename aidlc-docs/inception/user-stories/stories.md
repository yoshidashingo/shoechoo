# User Stories: Shoe Choo

## Epic 1: WYSIWYG Markdown Editing (Critical) — FR-01, FR-02

### Story 1.1: Inline Heading Rendering
**As** Haruka, **I want** headings to render with their styled appearance when my cursor leaves the heading line, **so that** I can see the visual hierarchy of my article while writing.

**Acceptance Criteria:**
- Given I type `## My Section Title` and move the cursor to another line, when I look at the heading line, then it displays as a styled level-2 heading (larger font, bold) with the `##` syntax hidden
- Given I click back on the rendered heading, when the cursor enters the line, then the `##` syntax characters become visible for editing
- Given I type headings h1-h6, when rendered, then each level has visually distinct sizing

### Story 1.2: Inline Text Formatting
**As** Haruka, **I want** bold, italic, and strikethrough text to render inline when I move away from the formatted text, **so that** I can see how my prose looks without leaving the editor.

**Acceptance Criteria:**
- Given I type `**bold text**` and move the cursor away, when rendered, then "bold text" appears bold with asterisks hidden
- Given I type `*italic*` and move the cursor away, when rendered, then "italic" appears italicized
- Given I type `~~strikethrough~~` and move the cursor away, when rendered, then text appears with strikethrough
- Given I click on rendered formatted text, when the cursor enters, then the syntax characters become visible

### Story 1.3: Link Rendering
**As** Haruka, **I want** links to render as clickable styled text when my cursor is not on them, **so that** I can verify my links look correct.

**Acceptance Criteria:**
- Given I type `[text](url)` and move the cursor away, when rendered, then "text" appears as a styled link
- Given I Cmd+click a rendered link, when clicked, then the URL opens in the default browser
- Given I click on a rendered link without Cmd, when the cursor enters, then the full Markdown syntax becomes visible

### Story 1.4: Code Block Rendering
**As** Kenji, **I want** fenced code blocks to display with syntax highlighting, **so that** I can verify code examples look correct in my documentation.

**Acceptance Criteria:**
- Given I type a fenced code block with ` ```swift `, when the cursor leaves the block, then the code displays with Swift syntax highlighting
- Given the cursor is inside a code block, when typing, then raw text is displayed in a monospace font without Markdown rendering
- Given a code block has no language specified, when rendered, then it displays as plain monospace text

### Story 1.5: List Rendering
**As** Haruka, **I want** ordered and unordered lists to render with proper indentation and markers, **so that** I can organize my thoughts visually.

**Acceptance Criteria:**
- Given I type `- item` or `* item`, when rendered, then a bullet marker is displayed
- Given I type `1. item`, when rendered, then a numbered marker is displayed
- Given I press Tab within a list, when indented, then a nested sub-list level is created
- Given I press Enter at the end of a list item, when a new line is created, then it continues the list

### Story 1.6: Task List Rendering
**As** Kenji, **I want** GFM task lists to render with interactive checkboxes, **so that** I can track TODO items in my documentation.

**Acceptance Criteria:**
- Given I type `- [ ] task`, when rendered, then an unchecked checkbox is displayed
- Given I type `- [x] task`, when rendered, then a checked checkbox is displayed
- Given I click a rendered checkbox, when toggled, then the underlying Markdown updates (`[ ]` ↔ `[x]`)

### Story 1.7: Table Rendering
**As** Kenji, **I want** GFM tables to render as formatted tables, **so that** I can review data presentation in my docs.

**Acceptance Criteria:**
- Given I type a GFM pipe table and move the cursor away, when rendered, then a visually formatted table is displayed with borders and alignment
- Given I click into a rendered table, when the cursor enters, then the raw pipe syntax becomes visible for editing

### Story 1.8: Blockquote and Horizontal Rule Rendering
**As** Haruka, **I want** blockquotes and horizontal rules to render with visual styling, **so that** I can structure my articles clearly.

**Acceptance Criteria:**
- Given I type `> quote text`, when rendered, then the text appears with a left border indent style
- Given I type `---` on its own line, when rendered, then a horizontal divider line is displayed

### Story 1.9: Image Inline Display
**As** Haruka, **I want** images to display inline in the editor, **so that** I can see how photos and diagrams look within my article.

**Acceptance Criteria:**
- Given I type `![alt](path)` referencing a valid image, when rendered, then the image displays inline
- Given the referenced image file does not exist, when rendered, then an "image not found" placeholder is shown
- Given I click on a rendered image, when selected, then I can resize or delete it

### Story 1.10: IME and Text System Integration
**As** Haruka, **I want** Japanese input (IME) to work correctly in the editor, **so that** I can write in Japanese without input issues.

**Acceptance Criteria:**
- Given I am composing Japanese text with IME, when mid-composition, then the editor does not attempt to render Markdown syntax
- Given IME composition is committed, when the text is finalized, then Markdown parsing resumes normally
- Given I use macOS spell check, when available, then it functions in the editor text

---

## Epic 2: Focus Mode & Typewriter Scrolling (High) — FR-03, FR-04

### Story 2.1: Focus Mode Toggle
**As** Haruka, **I want** to toggle focus mode to dim non-active paragraphs, **so that** I can concentrate on what I'm currently writing.

**Acceptance Criteria:**
- Given focus mode is off, when I press Cmd+Shift+F, then focus mode activates and all paragraphs except the current one are dimmed
- Given focus mode is on, when I press Cmd+Shift+F again, then focus mode deactivates and all paragraphs return to full opacity
- Given focus mode is on and I move the cursor to a different paragraph, when the cursor settles, then the new paragraph becomes fully visible and the previous one dims

### Story 2.2: Focus Mode Persistence
**As** Haruka, **I want** my focus mode preference to persist across app restarts, **so that** I don't have to re-enable it every time I open the app.

**Acceptance Criteria:**
- Given I enable focus mode and quit the app, when I relaunch, then focus mode is still enabled
- Given I have focus mode enabled globally, when I open a new document, then focus mode is active

### Story 2.3: Typewriter Scrolling
**As** Haruka, **I want** the active line to stay centered on screen as I type, **so that** I maintain a comfortable eye position during long writing sessions.

**Acceptance Criteria:**
- Given typewriter scrolling is enabled, when I type and the cursor moves to a new line, then the view scrolls smoothly to keep the cursor line vertically centered
- Given typewriter scrolling is enabled and I'm at the top of a short document, when the content doesn't fill the screen, then the view does not force-center (no excessive top padding)
- Given typewriter scrolling is off, when I type, then normal scroll behavior applies

---

## Epic 3: Document Management (High) — FR-05

### Story 3.1: New Document
**As** Miki, **I want** to create a new blank document when I launch the app, **so that** I can start writing immediately.

**Acceptance Criteria:**
- Given I launch the app with no file argument, when the app opens, then a blank untitled document is displayed
- Given I press Cmd+N, when triggered, then a new blank document opens in a new tab or window

### Story 3.2: Open and Save Files
**As** Kenji, **I want** to open existing `.md` files and save my changes, **so that** I can edit documentation files from my projects.

**Acceptance Criteria:**
- Given I press Cmd+O, when the file dialog appears, then I can select a `.md` file to open
- Given I have unsaved changes and press Cmd+S, when saving, then the file is written to disk
- Given I press Cmd+Shift+S, when the Save As dialog appears, then I can save to a new location

### Story 3.3: Auto-Save and Versions
**As** Haruka, **I want** my document to auto-save automatically, **so that** I never lose work if the app crashes or I forget to save.

**Acceptance Criteria:**
- Given I am editing a saved document, when a few seconds pass after the last edit, then changes are auto-saved (NSDocument standard behavior)
- Given I want to revert to a previous version, when I access File > Revert To, then macOS Versions shows the document history

### Story 3.4: Tabbed Windows
**As** Kenji, **I want** to open multiple documents in tabs within a single window, **so that** I can quickly switch between related files.

**Acceptance Criteria:**
- Given I have one document open and open another, when macOS tab preference is set, then the new document opens as a tab in the same window
- Given I have multiple tabs, when I click a tab, then the corresponding document is displayed

### Story 3.5: Recent Files
**As** Haruka, **I want** to see recently opened files, **so that** I can quickly resume working on my latest article.

**Acceptance Criteria:**
- Given I have previously opened files, when I check File > Open Recent, then a list of recent files is shown
- Given I click a recent file entry, when selected, then the file opens in the editor

---

## Epic 4: Export (Medium) — FR-08

### Story 4.1: Export to HTML
**As** Haruka, **I want** to export my document as HTML, **so that** I can paste it into my blog CMS.

**Acceptance Criteria:**
- Given I have a document open, when I press Cmd+Shift+E and select HTML, then a well-formatted HTML file is saved
- Given the document contains images, when exported, then image references are preserved with relative paths

### Story 4.2: Export to PDF
**As** Haruka, **I want** to export my document as PDF, **so that** I can send a formatted document to clients.

**Acceptance Criteria:**
- Given I have a document open, when I export to PDF, then a PDF is generated via macOS native rendering
- Given the document has styling (headings, code blocks, images), when exported, then the PDF preserves the visual appearance consistent with the editor view

---

## Epic 5: Sidebar (Medium) — FR-06

### Story 5.1: Recent Files Sidebar
**As** Haruka, **I want** a sidebar showing my recently opened files, **so that** I can quickly switch between documents I'm working on.

**Acceptance Criteria:**
- Given I have opened files previously, when I toggle the sidebar, then a list of recent files is displayed
- Given I click a file in the sidebar, when selected, then it opens in the editor
- Given I want to hide the sidebar, when I toggle it, then the sidebar collapses and the editor takes full width

---

## Epic 6: Image Support (Medium) — FR-07

### Story 6.1: Drag & Drop Images
**As** Haruka, **I want** to drag images from Finder into my document, **so that** I can quickly add photos to my articles.

**Acceptance Criteria:**
- Given I drag a PNG/JPEG/GIF from Finder into the editor, when dropped, then the image is copied to `{filename}.assets/` and a Markdown image reference is inserted
- Given the document is untitled (not yet saved), when I drop an image, then I am prompted to save the document first (to establish the assets folder location)

### Story 6.2: Paste Images from Clipboard
**As** Kenji, **I want** to paste screenshots from the clipboard, **so that** I can quickly capture and insert screenshots into documentation.

**Acceptance Criteria:**
- Given I have an image in the clipboard (e.g., screenshot), when I press Cmd+V, then the image is saved to `{filename}.assets/` as a PNG and a Markdown reference is inserted
- Given the pasted image is saved, when I check the assets folder, then the file exists with a timestamped filename

---

## Epic 7: Full-Screen & Dark Mode (Medium) — FR-09, FR-10

### Story 7.1: Full-Screen Writing
**As** Haruka, **I want** to enter full-screen mode for immersive writing, **so that** nothing on my screen distracts me.

**Acceptance Criteria:**
- Given I press Ctrl+Cmd+F or use the green traffic light button, when activated, then the app enters macOS native full-screen mode
- Given I'm in full-screen, when writing, then the toolbar and sidebar are hidden (auto-hide on mouse move to top)

### Story 7.2: Dark Mode Support
**As** Miki, **I want** the app to support dark mode, **so that** I can write comfortably during late-night study sessions.

**Acceptance Criteria:**
- Given macOS is set to dark appearance, when the app is open, then all UI elements (editor background, sidebar, toolbar, syntax highlighting) adapt to dark colors
- Given macOS is set to light appearance, when the app is open, then all UI elements use light colors
- Given the app has an appearance preference, when set to override system setting, then the app uses the selected appearance

---

## Epic 8: Typography (Low) — FR-11

### Story 8.1: Font and Spacing Configuration
**As** Haruka, **I want** to change the editor font and line spacing, **so that** I can customize the reading experience to my preference.

**Acceptance Criteria:**
- Given I open Preferences, when I change the font, then the editor text updates to the selected font
- Given I adjust line spacing, when changed, then the editor text reflowes with the new spacing
- Given sensible defaults are set, when opening the app for the first time, then the font and spacing provide comfortable reading

---

## Story Summary

| Epic | Stories | Priority | Persona |
|------|:---:|:---:|---------|
| 1. WYSIWYG Editing | 10 | Critical | Haruka, Kenji, Miki |
| 2. Focus & Typewriter | 3 | High | Haruka |
| 3. Document Management | 5 | High | Haruka, Kenji, Miki |
| 4. Export | 2 | Medium | Haruka |
| 5. Sidebar | 1 | Medium | Haruka |
| 6. Image Support | 2 | Medium | Haruka, Kenji |
| 7. Full-Screen & Dark Mode | 2 | Medium | Haruka, Miki |
| 8. Typography | 1 | Low | Haruka |
| **Total** | **26** | | |

## INVEST Compliance

All stories verified against INVEST criteria:
- **Independent**: Each story can be implemented and tested independently
- **Negotiable**: Acceptance criteria define "what" not "how"
- **Valuable**: Each story delivers user-facing value
- **Estimable**: Scope is clear enough to estimate effort
- **Small**: Each story is implementable within a few days
- **Testable**: All acceptance criteria are verifiable with concrete given/when/then
