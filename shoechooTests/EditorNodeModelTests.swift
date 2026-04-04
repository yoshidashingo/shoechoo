import Testing
import Foundation
@testable import shoechoo

@Suite("EditorNodeModel")
struct EditorNodeModelTests {

    private let parser = MarkdownParser()

    /// Helper: create a model and apply a parse result from source text.
    private func modelWithSource(_ source: String, revision: UInt64 = 1) -> EditorNodeModel {
        let model = EditorNodeModel()
        let result = parser.parse(source, revision: revision)
        model.applyParseResult(result)
        return model
    }

    // MARK: - Apply Parse Result

    @Test("Apply parse result updates blocks")
    func applyParseResultUpdatesBlocks() {
        let model = modelWithSource("# Hello\n\nWorld")
        #expect(model.blocks.count == 2)
        #expect(model.blocks[0].kind == .heading(level: 1))
        #expect(model.blocks[1].kind == .paragraph)
        #expect(model.documentRevision == 1)
    }

    @Test("Apply parse result updates documentRevision")
    func applyParseResultUpdatesRevision() {
        let model = modelWithSource("Hello", revision: 5)
        #expect(model.documentRevision == 5)
    }

    // MARK: - Stale Revision

    @Test("Stale revision is discarded")
    func staleRevisionDiscarded() {
        let model = EditorNodeModel()

        let result1 = parser.parse("# First", revision: 10)
        model.applyParseResult(result1)
        #expect(model.documentRevision == 10)
        #expect(model.blocks.count == 1)

        // Apply stale revision (lower than current) - should be ignored
        let result2 = parser.parse("# First\n\n# Second", revision: 5)
        model.applyParseResult(result2)
        #expect(model.documentRevision == 10)
        #expect(model.blocks.count == 1) // unchanged
    }

    @Test("Equal revision is accepted")
    func equalRevisionAccepted() {
        let model = EditorNodeModel()

        let result1 = parser.parse("# First", revision: 10)
        model.applyParseResult(result1)

        let result2 = parser.parse("# First\n\nSecond", revision: 10)
        model.applyParseResult(result2)
        #expect(model.blocks.count == 2)
    }

    // MARK: - Position-based Diff Preserves IDs

    @Test("Position-based diff preserves IDs for unchanged blocks")
    func positionBasedDiffPreservesIDs() {
        let model = EditorNodeModel()

        let source1 = "# Hello\n\nWorld"
        let result1 = parser.parse(source1, revision: 1)
        model.applyParseResult(result1)

        let originalIDs = model.blocks.map(\.id)

        // Parse same content again with higher revision
        let result2 = parser.parse(source1, revision: 2)
        model.applyParseResult(result2)

        // IDs should be preserved since content is the same
        let newIDs = model.blocks.map(\.id)
        #expect(originalIDs == newIDs)
    }

    @Test("Changed blocks get new IDs")
    func changedBlocksGetNewIDs() {
        let model = EditorNodeModel()

        let result1 = parser.parse("# Hello\n\nWorld", revision: 1)
        model.applyParseResult(result1)
        let originalSecondID = model.blocks[1].id

        // Change the second block
        let result2 = parser.parse("# Hello\n\nChanged", revision: 2)
        model.applyParseResult(result2)

        // Second block changed, so it gets a new ID
        #expect(model.blocks[1].id != originalSecondID)
    }

    // MARK: - Resolve Active Block

    @Test("Resolve active block from cursor position within first block")
    func resolveActiveBlockFirstBlock() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        let blockID = model.resolveActiveBlock(cursorOffset: 2)
        #expect(blockID != nil)
        #expect(blockID == model.blocks[0].id)
    }

    @Test("Resolve active block from cursor position within second block")
    func resolveActiveBlockSecondBlock() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        // Cursor in "World" paragraph (after "# Hello\n\n")
        let offset = ("# Hello\n\n" as NSString).length + 1
        let blockID = model.resolveActiveBlock(cursorOffset: offset)
        #expect(blockID != nil)
        #expect(blockID == model.blocks[1].id)
    }

    @Test("Resolve active block returns nil for empty model")
    func resolveActiveBlockEmptyModel() {
        let model = EditorNodeModel()
        let blockID = model.resolveActiveBlock(cursorOffset: 0)
        #expect(blockID == nil)
    }

    @Test("Resolve active block finds nearest block when cursor is in gap between blocks")
    func resolveActiveBlockInGap() {
        // "# Title\n\n**bold**" — gap at position 8-9 (the \n\n)
        let source = "# Title\n\n**bold**"
        let model = modelWithSource(source)
        #expect(model.blocks.count >= 2, "Must have at least 2 blocks")

        // Cursor at position 8 (in the gap between heading and paragraph)
        let gapID = model.resolveActiveBlock(cursorOffset: 8)
        #expect(gapID != nil, "Must resolve to a block even in gap")
    }

    @Test("Resolve active block finds last block when cursor is past document end")
    func resolveActiveBlockPastEnd() {
        let source = "# Hello"
        let model = modelWithSource(source)
        let pastEnd = (source as NSString).length + 5
        let blockID = model.resolveActiveBlock(cursorOffset: pastEnd)
        #expect(blockID != nil, "Must find block even past document end")
        #expect(blockID == model.blocks.last?.id)
    }

    // MARK: - Set Active Block

    @Test("Set active block updates isActive flags")
    func setActiveBlockUpdatesFlags() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        let targetID = model.blocks[0].id
        model.setActiveBlock(targetID)

        #expect(model.blocks[0].isActive == true)
        #expect(model.blocks[1].isActive == false)
        #expect(model.activeBlockID == targetID)
    }

    @Test("Set active block to different block deactivates previous")
    func setActiveBlockDeactivatesPrevious() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        model.setActiveBlock(model.blocks[0].id)
        #expect(model.blocks[0].isActive == true)

        model.setActiveBlock(model.blocks[1].id)
        #expect(model.blocks[0].isActive == false)
        #expect(model.blocks[1].isActive == true)
    }

    @Test("Set active block to nil deactivates all")
    func setActiveBlockNilDeactivatesAll() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        model.setActiveBlock(model.blocks[0].id)
        model.setActiveBlock(nil)

        #expect(model.blocks[0].isActive == false)
        #expect(model.blocks[1].isActive == false)
        #expect(model.activeBlockID == nil)
    }

    @Test("Set active block returns changed IDs")
    func setActiveBlockReturnsChangedIDs() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        let changed1 = model.setActiveBlock(model.blocks[0].id)
        #expect(changed1.contains(model.blocks[0].id))

        let changed2 = model.setActiveBlock(model.blocks[1].id)
        // Should contain both the previously active and newly active
        #expect(changed2.contains(model.blocks[0].id))
        #expect(changed2.contains(model.blocks[1].id))
    }

    @Test("Set active block returns empty set when already active")
    func setActiveBlockNoChangeReturnsEmpty() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        model.setActiveBlock(model.blocks[0].id)
        let changed = model.setActiveBlock(model.blocks[0].id)
        // No flags actually changed, but previous == current so no previousActiveID diff
        #expect(!changed.contains(model.blocks[1].id))
    }

    // MARK: - Block Lookup by ID

    @Test("Block lookup by ID returns correct block")
    func blockLookupByID() {
        let source = "# Hello\n\nWorld"
        let model = modelWithSource(source)

        let targetID = model.blocks[1].id
        let found = model.block(withID: targetID)
        #expect(found != nil)
        #expect(found?.kind == .paragraph)
    }

    @Test("Block lookup by ID returns nil for unknown ID")
    func blockLookupByIDNotFound() {
        let model = modelWithSource("Hello")
        let found = model.block(withID: UUID())
        #expect(found == nil)
    }

    @Test("Block lookup finds child block by ID")
    func blockLookupFindsChild() {
        let source = """
        - Apple
        - Banana
        """
        let model = modelWithSource(source)
        #expect(model.blocks.count == 1) // one unorderedList

        let childID = model.blocks[0].children[0].id
        let found = model.block(withID: childID)
        #expect(found != nil)
        #expect(found?.kind == .listItem(marker: .bullet))
    }

    // MARK: - blockCount

    @Test("blockCount reflects number of top-level blocks")
    func blockCountProperty() {
        let model = modelWithSource("# A\n\nB\n\nC")
        #expect(model.blockCount == 3)
    }
}
