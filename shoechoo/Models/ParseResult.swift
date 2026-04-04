import Foundation

struct ParseResult: Sendable {
    var revision: UInt64
    var blocks: [EditorNode]
}

