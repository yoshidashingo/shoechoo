# Business Logic Model: Unit 4 — Image & Media

## Pipeline Overview

```
Image arrives (drop or paste)
    |
    v
[1] Input Acquisition
    | Drop: extract file URLs from NSDraggingInfo pasteboard
    | Paste: extract NSImage from NSPasteboard
    v
[2] Document Readiness Check
    | Verify document is saved (has fileURL)
    | If untitled → prompt user to save first
    v
[3] Asset Directory Management
    | Resolve {filename}.assets/ path from MarkdownDocument.assetsDirectoryURL
    | FileService.createDirectoryIfNeeded()
    v
[4] Image Import & Write
    | Drop: copy source file to assets directory
    | Paste: convert NSImage → PNG data, write to assets directory
    | Generate unique filename (timestamp-based)
    | FileService.safeWrite()
    v
[5] Path Validation
    | Validate relative path against SEC-01 rules
    | No absolute paths, no ../ traversal, only relative
    v
[6] Markdown Insertion
    | EditorViewModel.insertImage(at:relativePath:)
    | Insert ![alt](relative/path) at cursor/drop position
    | Normal parse/render flow picks up the new image block
```

---

## [1] Input Acquisition

### Drag & Drop Path

**Trigger**: `ShoechooTextView.performDragOperation(_:)` called by AppKit

**Logic**:
1. Read pasteboard items from `NSDraggingInfo.draggingPasteboard`
2. Extract file URLs using `NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly`
3. Filter URLs to those whose `pathExtension` matches `ImageFormat.droppable`
4. If no valid image URLs remain, return `false` (decline the drop)
5. Determine drop position: convert drop point to character offset via `characterIndexForInsertion(at:)`
6. Construct `DragDropPayload(fileURLs:, dropLocation:)`
7. Forward to `EditorViewModel` for async processing

### Clipboard Paste Path

**Trigger**: `ShoechooTextView.paste(_:)` override, when pasteboard contains image data but not text

**Logic**:
1. Check `NSPasteboard.general` for image types: `NSPasteboard.PasteboardType.tiff`, `.png`
2. If text is also present, prefer text (standard paste behavior) — only intercept when image-only
3. Read `NSImage(pasteboard:)` from general pasteboard
4. If image is nil, fall through to default paste behavior
5. Construct `PasteboardImageData(image:, sourceFormat: .png, originalUTType:)`
6. Forward to `EditorViewModel` at current cursor position

---

## [2] Document Readiness Check

**Input**: `MarkdownDocument` (from `EditorViewModel`)

**Logic**:
1. Check `document.fileURL != nil`
2. If `fileURL` is nil (untitled document):
   - Set `EditorViewModel.pendingImageImport` to hold the payload
   - Trigger save prompt via `EditorViewModel.showSaveBeforeImageInsert = true`
   - When save completes successfully, resume import from `pendingImageImport`
   - If save is cancelled, discard `pendingImageImport` and show no error
3. If `fileURL` is present, proceed to step [3]

---

## [3] Asset Directory Management

**Input**: `MarkdownDocument.assetsDirectoryURL` (computed as `{filename}.assets/` sibling to the .md file)

**Logic**:
1. Resolve `assetsDirectoryURL` from document: `documentURL.deletingPathExtension().appendingPathExtension("assets")`
2. Call `FileService.createDirectoryIfNeeded(at: assetsDirectoryURL)`
   - If directory exists: no-op
   - If directory does not exist: create with `FileManager.createDirectory(at:withIntermediateDirectories:true)`
   - On failure: throw `ImageImportError.assetsDirectoryCreationFailed`

---

## [4] Image Import & Write

### Drop Path: `ImageService.importDroppedImage(_:to:)`

**Input**: Source file URL, assets directory URL

**Logic**:
1. Validate source file exists and is readable
2. Determine `ImageFormat` from file extension
3. Generate target filename:
   - Use original filename if no conflict exists
   - If conflict: append `-1`, `-2`, etc. before extension
4. Construct target URL: `assetsDirectoryURL.appendingPathComponent(targetFilename)`
5. Call `FileService.safeWrite()` — copy file data to target
6. Compute file size and image dimensions from the written file
7. Return `ImageImportResult(relativePath:, format:, fileSize:, dimensions:)`

### Paste Path: `ImageService.importPastedImage(from:to:)`

**Input**: `NSPasteboard`, assets directory URL

**Logic**:
1. Read `NSImage` from pasteboard
2. Convert to PNG data via `NSBitmapImageRep` → `representation(using: .png, properties: [:])`
3. If conversion fails: throw `ImageImportError.imageDataConversionFailed`
4. Generate timestamped filename: `ImageService.generateFilename(for:)` → e.g., `paste-20260402-143012.png`
5. If filename conflicts: append `-1`, `-2`, etc.
6. Construct target URL: `assetsDirectoryURL.appendingPathComponent(filename)`
7. Call `FileService.safeWrite(data, to: targetURL)`
8. Return `ImageImportResult`

### Filename Generation: `ImageService.generateFilename(for:)`

**Logic**:
1. Format: `paste-{yyyyMMdd}-{HHmmss}.png`
2. Use `DateFormatter` with `en_US_POSIX` locale, UTC timezone
3. If a file with that name already exists, append sequential suffix: `paste-20260402-143012-1.png`

---

## [5] Path Validation

**Input**: Relative path string (e.g., `MyDoc.assets/screenshot.png`)

**Logic** (SEC-01 compliance):
1. Reject if path starts with `/` (absolute path)
2. Reject if path contains `..` component (directory traversal)
3. Reject if path contains URL schemes other than implicit relative (no `http://`, `https://`, `ftp://`)
4. Reject if path contains characters outside safe set: alphanumeric, `-`, `_`, `.`, `/`
5. Validate the path resolves to a location within the document's parent directory
6. On failure: throw `ImageImportError.pathValidationFailed(reason)`

---

## [6] Markdown Insertion

**Input**: `position: Int`, `relativePath: String`

**Logic** (`EditorViewModel.insertImage(at:relativePath:)`):
1. Derive alt text from filename: strip extension, replace `-` and `_` with spaces
2. Construct Markdown snippet: `![alt text](relative/path)`
3. Determine insertion behavior:
   - If position is at the start of a line: insert snippet + newline
   - If position is mid-line: insert newline + snippet + newline
4. Modify `sourceText` by inserting the snippet at the resolved position
5. Normal text change flow triggers: parse → diff → re-render
6. The new image block renders per BR-02.7 (Unit 1): inline image display when inactive, `![alt](src)` syntax when active

---

## FileService Extensions

### `createDirectoryIfNeeded(at:)`

```swift
actor FileService {
    func createDirectoryIfNeeded(at url: URL) async throws {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return // Already exists
        }
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
```

### `safeWrite(_:to:)`

```swift
actor FileService {
    func safeWrite(_ data: Data, to url: URL) async throws {
        // 1. Write to temporary file in same directory (atomic prerequisite)
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        do {
            try data.write(to: tempURL, options: .atomic)
            // 2. Move temporary file to final destination
            let fm = FileManager.default
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
            try fm.moveItem(at: tempURL, to: url)
        } catch {
            // SEC-04: Clean up temporary file on failure
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }
}
```

---

## Error Handling Strategy (SEC-04)

| Operation | Error | Recovery |
|-----------|-------|----------|
| Directory creation | Permission denied, disk full | Show alert, do not insert image |
| File copy/write | I/O error, disk full | Clean up temp files, show alert |
| PNG conversion | Corrupt image data | Show alert "Could not convert image" |
| Path validation | SEC-01 violation | Reject silently (should not occur in normal flow) |
| Untitled document | No fileURL | Prompt save, resume on success |
