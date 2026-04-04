# Domain Entities: Unit 4 — Image & Media

## ImageImportResult

The result of importing an image (via drag & drop or clipboard paste) into the document's assets directory.

```swift
struct ImageImportResult {
    let relativePath: String            // e.g., "MyDoc.assets/screenshot-20260402-143012.png"
    let format: ImageFormat
    let fileSize: UInt64                // Bytes written
    let dimensions: CGSize              // Width x Height in pixels
}
```

---

## ImageFormat

Supported image formats for import.

```swift
enum ImageFormat: String, CaseIterable {
    case png  = "png"
    case jpeg = "jpeg"
    case gif  = "gif"

    var utType: UTType {
        switch self {
        case .png:  return .png
        case .jpeg: return .jpeg
        case .gif:  return .gif
        }
    }

    var fileExtension: String { rawValue }

    /// Formats that can be read from a drag operation (file-based)
    static let droppable: Set<ImageFormat> = [.png, .jpeg, .gif]

    /// Formats that can be read from NSPasteboard (bitmap data)
    static let pasteable: Set<ImageFormat> = [.png]
}
```

---

## AssetReference

A validated reference to an image asset within the document's assets directory.

```swift
struct AssetReference: Equatable {
    let assetsDirectoryURL: URL         // Absolute URL to {filename}.assets/
    let filename: String                // e.g., "screenshot-20260402-143012.png"

    var relativeMarkdownPath: String {
        // "{docname}.assets/{filename}" — relative to the .md file's parent
        assetsDirectoryURL.lastPathComponent + "/" + filename
    }

    var absoluteURL: URL {
        assetsDirectoryURL.appendingPathComponent(filename)
    }
}
```

---

## DragDropPayload

Encapsulates the data extracted from an `NSDraggingInfo` sender during a drop operation.

```swift
struct DragDropPayload {
    let fileURLs: [URL]                 // File URLs from the pasteboard (filtered to supported image types)
    let dropLocation: Int               // Character offset in the text view where the drop occurred
}
```

---

## PasteboardImageData

Encapsulates image data extracted from the system clipboard for paste operations.

```swift
struct PasteboardImageData {
    let image: NSImage                  // The bitmap image from the pasteboard
    let sourceFormat: ImageFormat        // Always .png for pasteboard images (normalized)
    let originalUTType: UTType?          // The original UTType on the pasteboard, if available
}
```

---

## ImageImportError

Errors that can occur during image import operations.

```swift
enum ImageImportError: LocalizedError {
    case unsupportedFormat(String)               // File extension not in ImageFormat
    case documentNotSaved                        // Document has no file URL (untitled)
    case assetsDirectoryCreationFailed(Error)     // Could not create .assets/ directory
    case fileWriteFailed(URL, Error)             // Could not write image file
    case pathValidationFailed(String)            // Path violates SEC-01 rules
    case imageDataConversionFailed               // NSImage could not produce PNG data
    case fileSizeExceeded(UInt64)                // Image exceeds maximum allowed size
    case pasteboardReadFailed                    // Could not read image from pasteboard

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported image format: \(ext)"
        case .documentNotSaved:
            return "Please save the document before inserting images."
        case .assetsDirectoryCreationFailed(let error):
            return "Failed to create assets directory: \(error.localizedDescription)"
        case .fileWriteFailed(let url, let error):
            return "Failed to write image to \(url.lastPathComponent): \(error.localizedDescription)"
        case .pathValidationFailed(let reason):
            return "Invalid image path: \(reason)"
        case .imageDataConversionFailed:
            return "Failed to convert image to PNG format."
        case .fileSizeExceeded(let size):
            return "Image size (\(size) bytes) exceeds the maximum allowed."
        case .pasteboardReadFailed:
            return "No image data found on the clipboard."
        }
    }
}
```

---

## ImageInsertionContext

Provides the context needed to insert a Markdown image reference into the source text.

```swift
struct ImageInsertionContext {
    let position: Int                   // Character offset in source text
    let relativePath: String            // Validated relative path for Markdown reference
    let altText: String                 // Alt text (derived from filename, sans extension)

    var markdownSnippet: String {
        "![\(altText)](\(relativePath))"
    }
}
```
