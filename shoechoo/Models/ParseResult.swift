import Foundation

struct ParseResult: Sendable {
    var revision: UInt64
    var blocks: [EditorNode]
}

struct DocumentRevision: Comparable, Sendable {
    let value: UInt64
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.value < rhs.value }
}
