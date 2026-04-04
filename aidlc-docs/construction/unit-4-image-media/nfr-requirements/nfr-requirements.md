# NFR Requirements: Unit 4 — Image & Media

## Performance

### PERF-01: Image Import Latency
- **Target**: < 500ms from user action (drop/paste) to image visible in editor for images up to 10MB
- **Measurement**: Wall-clock time from `NSDraggingInfo` drop event (or paste command) to `NSTextAttachment` rendered in editor
- **Breakdown**: File validation (~10ms) + copy to assets directory (~200ms for 10MB) + Markdown insertion (~1ms) + image load/display (~100ms)
- **Mitigation**: Async file copy via FileService actor; placeholder shown immediately while copy completes

### PERF-02: Drag & Drop Feedback
- **Target**: Immediate visual feedback < 16ms (single frame at 60fps) from drag entering the editor area
- **Measurement**: Time from `draggingEntered(_:)` callback to drop zone highlight rendered
- **Mitigation**: Drop zone overlay is pre-allocated; only visibility toggle on drag enter/exit

### PERF-03: Image Display in Editor
- **Target**: Image rendering MUST NOT block the main thread; lazy loading for off-screen images
- **Measurement**: Main thread hang detection via Instruments (no hangs > 50ms attributed to image loading)
- **Mitigation**: Load images asynchronously on background actor; display placeholder until loaded; cache loaded NSImage instances

---

## Reliability

### REL-01: Atomic File Write
- **Requirement**: Image files MUST be written atomically to the assets directory; no partial or corrupt files on crash or interruption
- **Implementation**: Write to temporary file first, then `FileManager.replaceItemAt(_:withItemAt:)` to atomically move into place
- **Verification**: Interrupt test (kill process during write) must not leave partial files in assets directory

### REL-02: Concurrent Image Imports
- **Requirement**: Multiple simultaneous drag & drop or paste operations MUST be processed safely without data races or lost imports
- **Implementation**: ImageService actor serializes import requests; each import gets a unique filename; FileService actor serializes disk writes
- **Verification**: Concurrent import stress test (10 simultaneous drops) must complete all imports without error

### REL-03: Disk Space Handling
- **Requirement**: Image import MUST fail gracefully when disk space is insufficient
- **Implementation**: Check available disk space before copy; if insufficient, cancel import and show user-friendly error
- **Error handling**: Catch `NSFileWriteOutOfSpaceError` and any POSIX `ENOSPC`; clean up partial files on failure

---

## Usability / Accessibility

### USA-01: Drag & Drop Visual Feedback
- **Requirement**: Editor MUST show a visible drop zone highlight when a valid image file is dragged over the editor area
- **Implementation**: Semi-transparent overlay with border on `draggingEntered`; remove on `draggingExited` or `performDragOperation`
- **Accessibility**: Drop zone state announced via VoiceOver (`NSAccessibilityNotificationName.valueChanged`)

### USA-02: Error Messages for Failed Imports
- **Requirement**: Failed image imports MUST show a user-friendly error message describing the issue and suggested action
- **Implementation**: NSAlert or inline banner with messages like "Image could not be imported: file format not supported" or "Not enough disk space to save image"
- **Localization**: All error messages localizable via `.strings` files

---

## Security (Baseline Extension — Applicable Rules)

### SEC-01: SECURITY-05 — Path Validation
- **Requirement**: All image destination paths MUST be validated to prevent directory traversal and writes outside the sandbox
- **Validation**: Reject filenames containing `..`, `/`, or null bytes; resolve symlinks and verify final path is within the document's assets directory
- **Implementation**: `URL.standardizedFileURL` + prefix check against allowed assets directory

### SEC-02: SECURITY-04 — Image File Validation
- **Requirement**: Imported files MUST be validated as actual image data, not just by file extension
- **Validation**: Use `NSImage(contentsOf:)` or `CGImageSource` to verify the file contains valid image data; reject files that fail to decode
- **Supported formats**: PNG, JPEG, GIF, WebP, HEIC, TIFF
- **Rejection**: Files with image extension but non-image content MUST be rejected with a user-facing error

### SEC-03: SECURITY-15 — File I/O Error Handling with Resource Cleanup
- **Requirement**: All file I/O operations in image import MUST have explicit error handling with guaranteed resource cleanup
- **Implementation**: `defer` blocks for file handle cleanup; `try`/`catch` around all FileManager operations; temporary files removed on failure
- **Verification**: No leaked file handles or orphaned temporary files after any error path

### SEC-04: Image Metadata Safety
- **Requirement**: Image import MUST NOT execute arbitrary code from image metadata (EXIF, XMP, ICC profiles)
- **Implementation**: Use system frameworks (NSImage, CGImageSource) which handle metadata safely; do not parse metadata manually or execute embedded scripts
- **Verification**: Import test with crafted EXIF/XMP payloads must not trigger code execution

---

## Testability

### TEST-01: ImageService Testability
- **Requirement**: ImageService MUST be testable with a mock FileService injected via protocol
- **Test approach**: Define `FileServiceProtocol`; inject mock that records operations and returns controlled results; assert ImageService behavior without disk I/O

### TEST-02: Path Validation Testability
- **Requirement**: Path validation logic MUST be testable independently as a pure function
- **Test approach**: Input filename string + base directory URL -> assert accepted/rejected; cover traversal attacks (`../`, symlinks, null bytes)

### TEST-03: Filename Generation Testability
- **Requirement**: Filename generation MUST be deterministic and testable
- **Test approach**: Inject a fixed timestamp or content hash seed; assert generated filename matches expected pattern; verify uniqueness for different inputs
