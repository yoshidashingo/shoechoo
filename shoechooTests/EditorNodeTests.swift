import Testing
import Foundation
@testable import shoechoo

@Suite("EditorNode")
struct EditorNodeTests {

    /// Helper: create a minimal EditorNode with given kind and sourceText.
    private func makeNode(
        kind: BlockKind,
        sourceText: String = "test"
    ) -> EditorNode {
        let range = sourceText.startIndex..<sourceText.endIndex
        return EditorNode(
            kind: kind,
            sourceRange: range,
            sourceText: sourceText
        )
    }

    // MARK: - Default Activation Scope

    @Test("Paragraph has selfOnly scope")
    func paragraphScope() {
        let node = makeNode(kind: .paragraph)
        #expect(node.activationScope == .selfOnly)
    }

    @Test("Heading has selfOnly scope")
    func headingScope() {
        let node = makeNode(kind: .heading(level: 1))
        #expect(node.activationScope == .selfOnly)
    }

    @Test("HorizontalRule has selfOnly scope")
    func horizontalRuleScope() {
        let node = makeNode(kind: .horizontalRule)
        #expect(node.activationScope == .selfOnly)
    }

    @Test("Image has selfOnly scope")
    func imageScope() {
        let node = makeNode(kind: .image(src: "a.png", alt: "alt"))
        #expect(node.activationScope == .selfOnly)
    }

    @Test("CodeBlock has wholeBlock scope")
    func codeBlockScope() {
        let node = makeNode(kind: .codeBlock(language: "swift"))
        #expect(node.activationScope == .wholeBlock)
    }

    @Test("Table has wholeBlock scope")
    func tableScope() {
        let node = makeNode(kind: .table)
        #expect(node.activationScope == .wholeBlock)
    }

    @Test("ListItem (bullet) has currentItem scope")
    func listItemBulletScope() {
        let node = makeNode(kind: .listItem(marker: .bullet))
        #expect(node.activationScope == .currentItem)
    }

    @Test("ListItem (ordered) has currentItem scope")
    func listItemOrderedScope() {
        let node = makeNode(kind: .listItem(marker: .ordered(start: 1)))
        #expect(node.activationScope == .currentItem)
    }

    @Test("TaskListItem has currentItem scope")
    func taskListItemScope() {
        let node = makeNode(kind: .taskListItem(isChecked: false))
        #expect(node.activationScope == .currentItem)
    }

    @Test("Blockquote has innerChild scope")
    func blockquoteScope() {
        let node = makeNode(kind: .blockquote)
        #expect(node.activationScope == .innerChild)
    }

    @Test("UnorderedList has selfOnly scope")
    func unorderedListScope() {
        let node = makeNode(kind: .unorderedList)
        #expect(node.activationScope == .selfOnly)
    }

    @Test("OrderedList has selfOnly scope")
    func orderedListScope() {
        let node = makeNode(kind: .orderedList)
        #expect(node.activationScope == .selfOnly)
    }

    @Test("TableRow has selfOnly scope")
    func tableRowScope() {
        let node = makeNode(kind: .tableRow)
        #expect(node.activationScope == .selfOnly)
    }

    // MARK: - Equality

    @Test("EditorNode equality compares all fields")
    func nodeEquality() {
        let text = "Hello"
        let range = text.startIndex..<text.endIndex
        let id = UUID()

        var node1 = EditorNode(
            id: id,
            kind: .paragraph,
            sourceRange: range,
            sourceText: text
        )
        var node2 = EditorNode(
            id: id,
            kind: .paragraph,
            sourceRange: range,
            sourceText: text
        )

        #expect(node1 == node2)

        // Differ by isActive
        node1.isActive = true
        node2.isActive = false
        #expect(node1 != node2)
    }

    @Test("EditorNodes with different IDs are not equal")
    func nodesWithDifferentIDsNotEqual() {
        let text = "Hello"
        let range = text.startIndex..<text.endIndex

        let node1 = EditorNode(kind: .paragraph, sourceRange: range, sourceText: text)
        let node2 = EditorNode(kind: .paragraph, sourceRange: range, sourceText: text)

        // Different auto-generated UUIDs
        #expect(node1 != node2)
    }

    @Test("EditorNodes with different kinds are not equal")
    func nodesWithDifferentKindsNotEqual() {
        let text = "Hello"
        let range = text.startIndex..<text.endIndex
        let id = UUID()

        let node1 = EditorNode(id: id, kind: .paragraph, sourceRange: range, sourceText: text)
        let node2 = EditorNode(id: id, kind: .heading(level: 1), sourceRange: range, sourceText: text)

        #expect(node1 != node2)
    }

    // MARK: - ContentHash

    @Test("ContentHash changes when sourceText changes")
    func contentHashChangesWithText() {
        let node1 = makeNode(kind: .paragraph, sourceText: "Hello")
        let node2 = makeNode(kind: .paragraph, sourceText: "World")

        #expect(node1.contentHash != node2.contentHash)
    }

    @Test("ContentHash is the same for identical sourceText")
    func contentHashSameForIdenticalText() {
        let node1 = makeNode(kind: .paragraph, sourceText: "Hello")
        let node2 = makeNode(kind: .paragraph, sourceText: "Hello")

        #expect(node1.contentHash == node2.contentHash)
    }

    // MARK: - Initial State

    @Test("isActive is false by default")
    func isActiveDefaultFalse() {
        let node = makeNode(kind: .paragraph)
        #expect(node.isActive == false)
    }

    @Test("children is empty by default")
    func childrenDefaultEmpty() {
        let node = makeNode(kind: .paragraph)
        #expect(node.children.isEmpty)
    }

    @Test("inlineRuns is empty by default")
    func inlineRunsDefaultEmpty() {
        let node = makeNode(kind: .paragraph)
        #expect(node.inlineRuns.isEmpty)
    }
}
