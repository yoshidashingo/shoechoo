import AppKit

struct RenderResult: @unchecked Sendable {
    var blockID: EditorNode.ID
    var attributedString: NSAttributedString
    var isActive: Bool
}
