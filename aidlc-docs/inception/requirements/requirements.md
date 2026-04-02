# Requirements Document: Shoe Choo (集中)

## Intent Analysis

| Item | Detail |
|------|--------|
| **User Request** | Build a Typora-inspired distraction-free WYSIWYG Markdown editor for macOS |
| **Request Type** | New Project (Greenfield) |
| **Scope Estimate** | System-wide — new macOS application with editor engine, document management, and export |
| **Complexity Estimate** | Complex — custom WYSIWYG rendering with TextKit 2, GFM support, native macOS integration |
| **Depth Level** | Comprehensive |

---

## 1. Functional Requirements

### FR-01: WYSIWYG Markdown Editing (Priority: Critical)
- **FR-01.1**: The editor MUST render Markdown syntax inline as the user types (headings, bold, italic, links, images, lists, blockquotes, code blocks, horizontal rules)
- **FR-01.2**: The editor MUST use TextKit 2 (NSTextView + custom rendering) for native macOS text system integration
- **FR-01.3**: The editor MUST support seamless switching between Markdown source and rendered output without mode toggles
- **FR-01.4**: The editor MUST properly handle IME input (Japanese, Chinese, Korean) via native AppKit text system
- **FR-01.5**: The editor MUST support standard macOS text behaviors (Undo/Redo, spell check, text substitutions, dictation)

### FR-02: GFM (GitHub Flavored Markdown) Support (Priority: Critical)
- **FR-02.1**: The parser MUST support all basic Markdown: headings (h1-h6), bold, italic, links, images, ordered/unordered lists, blockquotes, inline code, code blocks, horizontal rules
- **FR-02.2**: The parser MUST support GFM extensions: tables, task lists (checkboxes), strikethrough, fenced code blocks with language specification
- **FR-02.3**: The parser MUST use Apple's swift-markdown library (which internally uses cmark-gfm for GFM spec compliance)
- **FR-02.4**: Code blocks MUST have syntax highlighting for common programming languages

### FR-03: Focus Mode (Priority: High)
- **FR-03.1**: Focus mode MUST dim all paragraphs except the currently active paragraph
- **FR-03.2**: Focus mode MUST be toggleable via keyboard shortcut (Cmd+Shift+F) and menu item
- **FR-03.3**: The active paragraph MUST be visually distinct (full opacity) from dimmed paragraphs
- **FR-03.4**: Focus mode state MUST persist across app restarts (per-document or global preference)

### FR-04: Typewriter Scrolling (Priority: High)
- **FR-04.1**: When enabled, the active editing line MUST remain vertically centered in the editor viewport
- **FR-04.2**: Typewriter scrolling MUST be toggleable independently of focus mode
- **FR-04.3**: Scrolling MUST animate smoothly when the cursor moves to a new line

### FR-05: Document Management (Priority: High)
- **FR-05.1**: The app MUST use NSDocument-based architecture for standard macOS document handling
- **FR-05.2**: The app MUST support: New, Open, Save, Save As, Revert, Duplicate, Rename, Move To
- **FR-05.3**: The app MUST support macOS auto-save and Versions (document versioning)
- **FR-05.4**: The app MUST support tabbed windows (macOS native tab merging)
- **FR-05.5**: The app MUST track and display recently opened files
- **FR-05.6**: Documents MUST be saved as standard `.md` files (fully portable)

### FR-06: Sidebar (Priority: Medium)
- **FR-06.1**: The app MUST provide a minimal sidebar showing recently opened files
- **FR-06.2**: Clicking a sidebar item MUST open the document in the current window/tab
- **FR-06.3**: The sidebar MUST be collapsible/toggleable
- **FR-06.4**: Full folder tree navigation is OUT OF SCOPE for MVP (planned for future)

### FR-07: Image Support (Priority: Medium)
- **FR-07.1**: The editor MUST accept images via drag & drop and clipboard paste
- **FR-07.2**: Dropped/pasted images MUST be copied to a `{filename}.assets/` subfolder adjacent to the `.md` file
- **FR-07.3**: The Markdown image reference MUST use a relative path to the assets folder
- **FR-07.4**: Images MUST be displayed inline in the WYSIWYG editor
- **FR-07.5**: Supported formats: PNG, JPEG, GIF, WebP, SVG

### FR-08: Export (Priority: Medium)
- **FR-08.1**: The app MUST export to HTML format
- **FR-08.2**: The app MUST export to PDF format (via macOS native PDF rendering)
- **FR-08.3**: Exported documents MUST preserve styling consistent with the editor's rendered view
- **FR-08.4**: Export MUST be accessible via menu and keyboard shortcut (Cmd+Shift+E)

### FR-09: Full-Screen Writing (Priority: Medium)
- **FR-09.1**: The app MUST support macOS native full-screen mode
- **FR-09.2**: In full-screen, the editor MUST present a clean, distraction-free writing surface
- **FR-09.3**: Toolbar and sidebar MUST be auto-hideable in full-screen mode

### FR-10: Dark Mode (Priority: Medium)
- **FR-10.1**: The app MUST fully support macOS light and dark appearances
- **FR-10.2**: Editor rendering (syntax highlighting, background, text colors) MUST adapt to the active appearance
- **FR-10.3**: The app MUST follow the system appearance setting by default, with optional per-app override

### FR-11: Typography (Priority: Low)
- **FR-11.1**: The user MUST be able to configure the editor font and font size
- **FR-11.2**: The user MUST be able to configure line spacing
- **FR-11.3**: The app SHOULD provide sensible default typography for comfortable reading

---

## 2. Non-Functional Requirements

### NFR-01: Performance
- **NFR-01.1**: Cold launch MUST complete in under 1 second
- **NFR-01.2**: Memory usage MUST remain under 50MB for documents up to 10,000 lines
- **NFR-01.3**: Keystroke-to-render latency MUST be under 16ms (60fps) for typical documents
- **NFR-01.4**: Opening a 1MB Markdown file MUST complete in under 500ms

### NFR-02: Reliability
- **NFR-02.1**: Auto-save MUST prevent data loss on unexpected quit (leveraging NSDocument)
- **NFR-02.2**: The editor MUST handle malformed Markdown gracefully without crashes
- **NFR-02.3**: Image operations (copy, reference) MUST handle file system errors gracefully

### NFR-03: Usability
- **NFR-03.1**: The app MUST conform to macOS Human Interface Guidelines
- **NFR-03.2**: All features MUST be accessible via keyboard shortcuts
- **NFR-03.3**: The app MUST support macOS VoiceOver accessibility

### NFR-04: Maintainability
- **NFR-04.1**: Architecture MUST follow MVVM with SwiftUI + AppKit integration
- **NFR-04.2**: Code MUST have unit test coverage for parser, document model, and export services
- **NFR-04.3**: The WYSIWYG rendering engine MUST be separated from business logic for independent testing

### NFR-05: Security (Extension Enabled)
- **NFR-05.1**: The app MUST use App Sandbox (entitlements for user-selected file access)
- **NFR-05.2**: The app MUST use Hardened Runtime
- **NFR-05.3**: File I/O MUST use explicit error handling with resource cleanup (SECURITY-15)
- **NFR-05.4**: Dependencies MUST use exact versions via SPM Package.resolved (SECURITY-10)
- **NFR-05.5**: No hardcoded credentials or secrets in source code (SECURITY-12 — N/A for auth, applicable for signing)
- **NFR-05.6**: Error messages displayed to users MUST be generic (SECURITY-09, SECURITY-15)

### NFR-06: Distribution
- **NFR-06.1**: The app MUST be signed with Developer ID certificate
- **NFR-06.2**: The app MUST be notarized with Apple for Gatekeeper compatibility
- **NFR-06.3**: Distribution via GitHub Releases (DMG + ZIP)
- **NFR-06.4**: Mac App Store distribution is OUT OF SCOPE for MVP

---

## 3. Security Compliance Summary (Baseline Extension)

| Rule | Applicability | Notes |
|------|:---:|-------|
| SECURITY-01: Encryption at Rest/Transit | N/A | No data stores or network communication |
| SECURITY-02: Access Logging | N/A | No network intermediaries |
| SECURITY-03: Application Logging | Applicable | Structured logging for crash diagnostics |
| SECURITY-04: HTTP Security Headers | N/A | No web-serving endpoints |
| SECURITY-05: Input Validation | Applicable | File path validation, Markdown input handling |
| SECURITY-06: Least-Privilege Access | Applicable | App Sandbox entitlements, minimal file access |
| SECURITY-07: Network Configuration | N/A | No network access in core functionality |
| SECURITY-08: Application Access Control | N/A | No user authentication |
| SECURITY-09: Security Hardening | Applicable | Hardened Runtime, generic error messages |
| SECURITY-10: Supply Chain Security | Applicable | SPM lock file, dependency pinning |
| SECURITY-11: Secure Design | Applicable | Sandbox isolation, defense in depth for file I/O |
| SECURITY-12: Auth & Credential Mgmt | N/A | No user authentication |
| SECURITY-13: Integrity Verification | Applicable | Notarization, code signing |
| SECURITY-14: Alerting & Monitoring | N/A | Desktop app, no server-side monitoring |
| SECURITY-15: Exception Handling | Applicable | Fail-safe file I/O, global error handling |

---

## 4. Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rendering Engine | TextKit 2 (NSTextView) | Native IME, accessibility, Undo, spell check |
| Document Architecture | NSDocument | Standard macOS auto-save, tabs, versions |
| Markdown Parser | swift-markdown (Apple) | Typed AST, internal cmark-gfm, maintained |
| Image Handling | Copy to `{filename}.assets/` | Portability, self-contained documents |
| Distribution | GitHub Releases + Notarization | Gatekeeper compatibility |
| Markdown Scope | GFM (GitHub Flavored) | Tables, task lists, strikethrough, code fences |
| Security | Baseline enabled | App Sandbox + Hardened Runtime |

---

## 5. Feature Priority (MVP)

| Priority | Feature | Status |
|:---:|---------|--------|
| 1 | WYSIWYG Markdown Editing (TextKit 2) | MVP |
| 2 | Focus Mode | MVP |
| 3 | Export (HTML, PDF) | MVP |
| 4 | Sidebar (Recent Files) | MVP |
| 5 | Dark Mode | MVP |
| — | Full File Tree Sidebar | Post-MVP |
| — | iOS / iPadOS app | Post-MVP |
| — | iCloud Sync | Post-MVP |
| — | LaTeX Math Rendering | Post-MVP |
| — | Mermaid Diagrams | Post-MVP |

---

## 6. Out of Scope (v1)

- iOS / iPadOS app
- iCloud sync
- Collaboration / real-time editing
- Plugin / extension system
- Table editing GUI (inline table editing)
- LaTeX math rendering
- Mermaid / diagram rendering
- Version history / change tracking
- Vim / Emacs keybindings
- Mac App Store distribution
- Full folder tree sidebar
