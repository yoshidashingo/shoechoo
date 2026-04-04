import Foundation

// MARK: - BlockKind
enum BlockKind: Equatable, Sendable {
    case paragraph
    case heading(level: Int)          // 1-6
    case codeBlock(language: String?) // Fenced code block
    case unorderedList
    case orderedList
    case listItem(marker: ListMarker)
    case taskListItem(isChecked: Bool)
    case blockquote
    case table
    case tableRow
    case horizontalRule
    case image(src: String, alt: String)
}

enum ListMarker: Equatable, Sendable {
    case bullet
    case ordered(start: Int)
}

// MARK: - ActivationScope
enum ActivationScope: Sendable {
    case selfOnly       // paragraph, heading, horizontal rule
    case wholeBlock     // code block, table
    case currentItem    // list item
    case innerChild     // blockquote
}

// MARK: - InlineRun
struct InlineRun: Equatable, Sendable {
    var type: InlineType
    /// UTF-16 range relative to the owning block's sourceText.
    var range: NSRange
}

enum InlineType: Equatable, Sendable {
    case text
    case bold
    case italic
    case boldItalic
    case strikethrough
    case inlineCode
    case link(url: String)
    case image(src: String, alt: String)
    case lineBreak
}

// MARK: - EditorNode
struct EditorNode: Identifiable, Equatable, Sendable {
    let id: UUID
    var kind: BlockKind
    /// UTF-16 range in the full source document.
    var sourceRange: NSRange
    var contentHash: Int
    var inlineRuns: [InlineRun]
    var isActive: Bool
    var activationScope: ActivationScope
    /// Raw source text for this block.
    var sourceText: String
    /// Children for nested structures (list items in list, rows in table, blocks in blockquote).
    var children: [EditorNode]

    init(
        id: UUID = UUID(),
        kind: BlockKind,
        sourceRange: NSRange,
        sourceText: String,
        inlineRuns: [InlineRun] = [],
        children: [EditorNode] = []
    ) {
        self.id = id
        self.kind = kind
        self.sourceRange = sourceRange
        self.contentHash = sourceText.hashValue
        self.inlineRuns = inlineRuns
        self.isActive = false
        self.activationScope = Self.defaultScope(for: kind)
        self.sourceText = sourceText
        self.children = children
    }

    static func defaultScope(for kind: BlockKind) -> ActivationScope {
        switch kind {
        case .paragraph, .heading, .horizontalRule, .image:
            return .selfOnly
        case .codeBlock, .table:
            return .wholeBlock
        case .listItem, .taskListItem:
            return .currentItem
        case .blockquote:
            return .innerChild
        case .unorderedList, .orderedList, .tableRow:
            return .selfOnly
        }
    }
}
