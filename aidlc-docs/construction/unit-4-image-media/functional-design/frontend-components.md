# Frontend Components: Unit 4 — Image & Media

## ShoechooTextView: Drag & Drop

### Drag Registration

```swift
class ShoechooTextView: NSTextView {
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForDraggedTypes([.fileURL])
    }
}
```

### Drag Validation

```swift
extension ShoechooTextView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 1. Read file URLs from pasteboard
        // 2. Filter to supported image extensions (png, jpeg, jpg, gif)
        // 3. Return .copy if at least one valid image URL, .none otherwise
        guard hasValidImageURLs(sender.draggingPasteboard) else {
            return .none
        }
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Show insertion cursor at drop point
        let point = convert(sender.draggingLocation, from: nil)
        let charIndex = characterIndexForInsertion(at: point)
        setSelectedRange(NSRange(location: charIndex, length: 0))
        return .copy
    }

    private func hasValidImageURLs(_ pasteboard: NSPasteboard) -> Bool {
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else { return false }

        let supported: Set<String> = ["png", "jpeg", "jpg", "gif"]
        return urls.contains { supported.contains($0.pathExtension.lowercased()) }
    }
}
```

### Drop Handling

```swift
extension ShoechooTextView {
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // 1. Extract valid image URLs from pasteboard
        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else { return false }

        let supported: Set<String> = ["png", "jpeg", "jpg", "gif"]
        let imageURLs = urls.filter { supported.contains($0.pathExtension.lowercased()) }
        guard !imageURLs.isEmpty else { return false }

        // 2. Determine drop position
        let point = convert(sender.draggingLocation, from: nil)
        let dropPosition = characterIndexForInsertion(at: point)

        // 3. Forward to delegate (Coordinator → EditorViewModel)
        imageDropDelegate?.handleImageDrop(
            fileURLs: imageURLs,
            at: dropPosition
        )

        return true
    }
}
```

---

## ShoechooTextView: Clipboard Paste Override

```swift
extension ShoechooTextView {
    override func paste(_ sender: Any?) {
        let pb = NSPasteboard.general

        // 1. If pasteboard has text, use standard paste (BR-02.2)
        if pb.string(forType: .string) != nil {
            super.paste(sender)
            return
        }

        // 2. If pasteboard has image data (no text), intercept for image import
        if let image = NSImage(pasteboard: pb) {
            let cursorPosition = selectedRange().location
            imageDropDelegate?.handleImagePaste(
                image: image,
                at: cursorPosition
            )
            return
        }

        // 3. Fallback: standard paste
        super.paste(sender)
    }
}
```

---

## ImageDropDelegate Protocol

Bridge between ShoechooTextView (AppKit) and EditorViewModel (async processing).

```swift
protocol ImageDropDelegate: AnyObject {
    func handleImageDrop(fileURLs: [URL], at position: Int)
    func handleImagePaste(image: NSImage, at position: Int)
}
```

The `WYSIWYGTextView.Coordinator` conforms to this protocol and forwards calls to `EditorViewModel`.

---

## WYSIWYGTextView Coordinator Extension

```swift
extension WYSIWYGTextView.Coordinator: ImageDropDelegate {
    func handleImageDrop(fileURLs: [URL], at position: Int) {
        Task { @MainActor in
            await parent.viewModel.handleDroppedImages(fileURLs: fileURLs, at: position)
        }
    }

    func handleImagePaste(image: NSImage, at position: Int) {
        Task { @MainActor in
            await parent.viewModel.handlePastedImage(image: image, at: position)
        }
    }
}
```

---

## EditorViewModel: Image Insertion

### State Properties

```swift
extension EditorViewModel {
    // Pending import (held while save dialog is active)
    var pendingImageImport: PendingImageImport?
    var showSaveBeforeImageInsert: Bool = false

    enum PendingImageImport {
        case drop(fileURLs: [URL], position: Int)
        case paste(image: NSImage, position: Int)
    }
}
```

### Drop Handler

```swift
extension EditorViewModel {
    func handleDroppedImages(fileURLs: [URL], at position: Int) async {
        // 1. Check document readiness
        guard let assetsDir = document.assetsDirectoryURL else {
            pendingImageImport = .drop(fileURLs: fileURLs, position: position)
            showSaveBeforeImageInsert = true
            return
        }

        // 2. Import each image sequentially
        var insertionOffset = position
        for url in fileURLs {
            do {
                let result = try await imageService.importDroppedImage(url, to: assetsDir)
                insertImage(at: insertionOffset, relativePath: result.relativePath)
                insertionOffset += result.relativePath.count + 6 // ![alt](path)\n overhead
            } catch {
                presentError(error)
            }
        }
    }
}
```

### Paste Handler

```swift
extension EditorViewModel {
    func handlePastedImage(image: NSImage, at position: Int) async {
        // 1. Check document readiness
        guard let assetsDir = document.assetsDirectoryURL else {
            pendingImageImport = .paste(image: image, position: position)
            showSaveBeforeImageInsert = true
            return
        }

        // 2. Import pasted image
        do {
            let result = try await imageService.importPastedImage(
                from: NSPasteboard.general,
                to: assetsDir
            )
            insertImage(at: position, relativePath: result.relativePath)
        } catch {
            presentError(error)
        }
    }
}
```

### Source Text Insertion

```swift
extension EditorViewModel {
    func insertImage(at position: Int, relativePath: String) {
        // 1. Derive alt text from filename
        let filename = URL(string: relativePath)?.lastPathComponent ?? relativePath
        let altText = filename
            .replacingOccurrences(of: ".\(filename.split(separator: ".").last ?? "")", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        // 2. Build Markdown snippet
        let snippet = "![\(altText)](\(relativePath))"

        // 3. Determine line context
        let index = sourceText.index(sourceText.startIndex, offsetBy: min(position, sourceText.count))
        let isStartOfLine = index == sourceText.startIndex
            || sourceText[sourceText.index(before: index)] == "\n"

        // 4. Insert with appropriate newlines
        var insertion = ""
        if !isStartOfLine { insertion += "\n" }
        insertion += snippet + "\n"

        sourceText.insert(contentsOf: insertion, at: index)
        // Normal text change flow triggers parse/render
    }
}
```

---

## User Interaction Flows

### Flow 1: Drag & Drop Image from Finder

```
1. User drags PNG/JPEG/GIF from Finder over editor
2. ShoechooTextView.draggingEntered() validates image type → .copy cursor
3. ShoechooTextView.draggingUpdated() shows insertion point as cursor moves
4. User drops image
5. ShoechooTextView.performDragOperation() extracts URLs + drop position
6. Coordinator.handleImageDrop() → EditorViewModel.handleDroppedImages()
7. EditorViewModel checks document.assetsDirectoryURL
8. ImageService.importDroppedImage() → FileService creates dir + copies file
9. EditorViewModel.insertImage() inserts ![alt](path) at drop position
10. Normal parse/render flow displays inline image (Unit 1 BR-02.7)
```

### Flow 2: Paste Image from Clipboard

```
1. User copies image (e.g., screenshot via Cmd+Shift+4, or copy from Preview)
2. User presses Cmd+V in editor
3. ShoechooTextView.paste() checks pasteboard: no text, has image → intercept
4. Coordinator.handleImagePaste() → EditorViewModel.handlePastedImage()
5. EditorViewModel checks document.assetsDirectoryURL
6. ImageService.importPastedImage() → converts to PNG, generates timestamped name
7. FileService.safeWrite() writes PNG to assets directory
8. EditorViewModel.insertImage() inserts ![alt](path) at cursor
9. Normal parse/render flow displays inline image
```

### Flow 3: Image Drop on Untitled Document

```
1. User drags image onto unsaved document
2. ShoechooTextView.performDragOperation() fires
3. EditorViewModel.handleDroppedImages() finds assetsDirectoryURL == nil
4. Payload saved to pendingImageImport
5. showSaveBeforeImageInsert = true → SwiftUI presents save dialog
6a. User saves → document gets fileURL → pendingImageImport resumes → normal import flow
6b. User cancels → pendingImageImport discarded, no error shown
```

### Flow 4: Paste Image on Untitled Document

```
1. User presses Cmd+V with image on clipboard, document is untitled
2. Same flow as Flow 3 but with PendingImageImport.paste variant
```

---

## Save Prompt (SwiftUI)

```swift
// In EditorView
.alert("Save Document", isPresented: $viewModel.showSaveBeforeImageInsert) {
    Button("Save") {
        Task {
            if await viewModel.saveDocument() {
                await viewModel.resumePendingImageImport()
            }
        }
    }
    Button("Cancel", role: .cancel) {
        viewModel.pendingImageImport = nil
    }
} message: {
    Text("Please save the document before inserting images. Images are stored in a folder next to the document file.")
}
```

---

## Error Presentation

```swift
// In EditorView
.alert("Image Import Error", isPresented: $viewModel.showImageImportError) {
    Button("OK", role: .cancel) {}
} message: {
    Text(viewModel.imageImportErrorMessage ?? "An unknown error occurred.")
}
```

Image import errors are caught in the ViewModel handlers and surfaced via `showImageImportError` / `imageImportErrorMessage` state properties bound to the SwiftUI alert.
