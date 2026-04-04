import AppKit
import UniformTypeIdentifiers

enum ImageServiceError: LocalizedError {
    case fileTooLarge(filename: String, size: Int, limit: Int)

    var errorDescription: String? {
        switch self {
        case let .fileTooLarge(filename, size, limit):
            let sizeMB = size / (1024 * 1024)
            let limitMB = limit / (1024 * 1024)
            return "File \"\(filename)\" is \(sizeMB) MB, which exceeds the \(limitMB) MB limit."
        }
    }
}

actor ImageService {
    static let shared = ImageService()
    private let fileService = FileService.shared

    private static let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "webp"]

    // MARK: - Public API

    private static let maxFileSize: Int = 50 * 1024 * 1024 // 50 MB

    func importDroppedImage(from urls: [URL], to assetsDir: URL) async throws -> [String] {
        guard !urls.isEmpty else { return [] }

        try await fileService.createDirectoryIfNeeded(at: assetsDir)

        var relativePaths: [String] = []
        for url in urls {
            let ext = url.pathExtension.lowercased()
            guard Self.supportedExtensions.contains(ext) else { continue }

            let filename = generateFilename(originalName: url.lastPathComponent)

            guard validateImagePath(filename) else { continue }

            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize, fileSize > Self.maxFileSize {
                throw ImageServiceError.fileTooLarge(
                    filename: url.lastPathComponent,
                    size: fileSize,
                    limit: Self.maxFileSize
                )
            }

            let destURL = assetsDir.appendingPathComponent(filename)

            let data = try Data(contentsOf: url)
            try await fileService.safeWrite(data, to: destURL)

            relativePaths.append(filename)
        }
        return relativePaths
    }

    func importPastedImage(from imageData: Data, to assetsDir: URL) async throws -> String {
        try await fileService.createDirectoryIfNeeded(at: assetsDir)

        let filename = generateFilename(originalName: nil)
        let destURL = assetsDir.appendingPathComponent(filename)

        try await fileService.safeWrite(imageData, to: destURL)
        return filename
    }

    // MARK: - Helpers

    func generateFilename(originalName: String?) -> String {
        let timestamp = ISO8601DateFormatter.string(
            from: Date(),
            timeZone: .current,
            formatOptions: [.withYear, .withMonth, .withDay, .withTime, .withColonSeparatorInTime]
        ).replacingOccurrences(of: ":", with: "-")

        if let original = originalName {
            let ext = (original as NSString).pathExtension.lowercased()
            let validExt = Self.supportedExtensions.contains(ext) ? ext : "png"
            let baseName = (original as NSString).deletingPathExtension
                .replacingOccurrences(of: " ", with: "_")
            return "\(timestamp)_\(baseName)_\(UUID().uuidString.prefix(6)).\(validExt)"
        }
        return "\(timestamp)_pasted_\(UUID().uuidString.prefix(6)).png"
    }

    func validateImagePath(_ path: String) -> Bool {
        // Reject path traversal
        if path.contains("../") || path.contains("..\\") {
            return false
        }
        // Reject absolute paths
        if path.hasPrefix("/") || path.contains(":\\") {
            return false
        }
        // Must have a supported extension
        let ext = (path as NSString).pathExtension.lowercased()
        return Self.supportedExtensions.contains(ext)
    }
}
