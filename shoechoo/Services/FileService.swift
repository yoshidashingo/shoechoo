import Foundation

actor FileService {
    static let shared = FileService()

    func createDirectoryIfNeeded(at url: URL) async throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func safeWrite(_ data: Data, to url: URL) async throws {
        let tempURL = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL, options: .atomic)
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try fm.moveItem(at: tempURL, to: url)
    }
}
