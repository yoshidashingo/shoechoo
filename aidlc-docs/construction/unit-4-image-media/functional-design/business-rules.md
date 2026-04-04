# Business Rules: Unit 4 — Image & Media

## BR-01: Drag & Drop Image Import

| Rule | Description |
|------|-------------|
| BR-01.1 | ShoechooTextView MUST accept drag operations containing file URLs with extensions matching ImageFormat.droppable (png, jpeg, gif) |
| BR-01.2 | Non-image files in a mixed drop MUST be silently ignored; only valid image files are imported |
| BR-01.3 | Multiple images in a single drop MUST be imported sequentially, each producing a separate Markdown image reference |
| BR-01.4 | The Markdown reference MUST be inserted at the character position corresponding to the drop point |
| BR-01.5 | The original source file MUST NOT be modified or moved; a copy is placed in the assets directory |
| BR-01.6 | If the source file's name conflicts with an existing asset, a numeric suffix (-1, -2, ...) MUST be appended before the extension |
| BR-01.7 | Drop operations MUST be processed asynchronously to avoid blocking the main thread |

---

## BR-02: Clipboard Paste Image Import

| Rule | Description |
|------|-------------|
| BR-02.1 | When NSPasteboard contains image data (TIFF/PNG) but no text, Cmd+V MUST import the image rather than performing a standard paste |
| BR-02.2 | When NSPasteboard contains both text and image data, standard text paste MUST take priority |
| BR-02.3 | Pasted images MUST be converted to PNG format before saving to the assets directory |
| BR-02.4 | Pasted images MUST use a timestamped filename: `paste-{yyyyMMdd}-{HHmmss}.png` |
| BR-02.5 | The Markdown reference MUST be inserted at the current cursor position |
| BR-02.6 | If the generated filename conflicts with an existing asset, a numeric suffix MUST be appended |
| BR-02.7 | Paste operations MUST be processed asynchronously to avoid blocking the main thread |

---

## BR-03: Asset Directory Management

| Rule | Description |
|------|-------------|
| BR-03.1 | The assets directory MUST be named `{document-filename-without-extension}.assets` and located as a sibling to the .md file |
| BR-03.2 | The assets directory MUST be created automatically on first image import if it does not exist |
| BR-03.3 | If the assets directory cannot be created (permissions, disk full), the import MUST fail with a user-visible error |
| BR-03.4 | The assets directory path MUST be resolved from `MarkdownDocument.assetsDirectoryURL` |

---

## BR-04: Filename Generation

| Rule | Description |
|------|-------------|
| BR-04.1 | Dropped images MUST retain their original filename when no conflict exists |
| BR-04.2 | Pasted images MUST use the format `paste-{yyyyMMdd}-{HHmmss}.png` with `en_US_POSIX` locale |
| BR-04.3 | When a filename conflicts with an existing file in the assets directory, a numeric suffix MUST be appended: `name-1.ext`, `name-2.ext`, etc. |
| BR-04.4 | Filenames MUST contain only safe characters: alphanumeric, hyphen (`-`), underscore (`_`), period (`.`) |
| BR-04.5 | Filenames MUST NOT exceed 255 characters (macOS filesystem limit) |

---

## BR-05: Path Validation (SEC-01)

| Rule | Description |
|------|-------------|
| BR-05.1 | All image paths inserted into Markdown MUST be relative to the document's parent directory |
| BR-05.2 | Absolute paths (starting with `/`) MUST be rejected |
| BR-05.3 | Paths containing `..` components MUST be rejected (no directory traversal) |
| BR-05.4 | Paths containing URL schemes (`http://`, `https://`, `ftp://`) MUST be rejected |
| BR-05.5 | Path validation MUST occur before the Markdown reference is inserted into source text |
| BR-05.6 | The resolved absolute path MUST fall within the document's parent directory tree |

---

## BR-06: Untitled Document Handling

| Rule | Description |
|------|-------------|
| BR-06.1 | If the document has no fileURL (untitled/unsaved), image import MUST NOT proceed |
| BR-06.2 | The user MUST be prompted to save the document before image insertion can continue |
| BR-06.3 | The pending image payload (drop or paste data) MUST be preserved while the save dialog is active |
| BR-06.4 | If the user saves successfully, the pending import MUST resume automatically |
| BR-06.5 | If the user cancels the save dialog, the pending import MUST be discarded without error |

---

## BR-07: Supported Formats

| Rule | Description |
|------|-------------|
| BR-07.1 | Drag & drop MUST support: PNG, JPEG, GIF |
| BR-07.2 | Clipboard paste MUST produce: PNG (all pasteboard image data is normalized to PNG) |
| BR-07.3 | Unsupported file formats in a drop MUST be silently ignored (not cause an error) |
| BR-07.4 | Image format detection MUST be based on file extension for dropped files and UTType for pasteboard data |

---

## BR-08: File I/O Safety (SEC-04)

| Rule | Description |
|------|-------------|
| BR-08.1 | All file write operations MUST use atomic writes (write to temp file, then move) |
| BR-08.2 | If a write operation fails, any temporary files MUST be cleaned up |
| BR-08.3 | All file I/O errors MUST be caught and presented to the user as actionable alerts |
| BR-08.4 | File I/O operations MUST run off the main thread (within Swift actors) |
| BR-08.5 | FileService.safeWrite MUST NOT overwrite an existing file without conflict resolution (see BR-04.3) |

---

## BR-09: Markdown Reference Format

| Rule | Description |
|------|-------------|
| BR-09.1 | Inserted image references MUST use standard Markdown syntax: `![alt](path)` |
| BR-09.2 | The alt text MUST be derived from the filename: strip extension, replace `-` and `_` with spaces |
| BR-09.3 | The path MUST be relative, using the format `{docname}.assets/{filename}` |
| BR-09.4 | If insertion point is mid-line, a newline MUST be prepended to place the image on its own line |
| BR-09.5 | After insertion, a trailing newline MUST be appended to separate the image from subsequent content |
| BR-09.6 | After insertion, the normal parse/render flow (Unit 1 pipeline) handles display per BR-02.7 |
