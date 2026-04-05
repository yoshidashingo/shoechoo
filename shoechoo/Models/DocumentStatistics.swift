import Foundation

/// Document statistics extracted from EditorViewModel (FR-07).
struct DocumentStatistics: Equatable, Sendable {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int

    init(from text: String) {
        wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        characterCount = text.count
        lineCount = text.isEmpty ? 0 : text.components(separatedBy: "\n").count
    }
}
