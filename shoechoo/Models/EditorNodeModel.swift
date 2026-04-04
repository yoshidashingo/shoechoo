import Foundation

@Observable
final class EditorNodeModel: @unchecked Sendable {
    var blocks: [EditorNode] = []
    var documentRevision: UInt64 = 0
    var activeBlockID: EditorNode.ID?

    var blockCount: Int { blocks.count }

    // Apply a new parse result with diff & merge
    func applyParseResult(_ result: ParseResult) {
        guard result.revision >= documentRevision else { return } // stale

        var newBlocks = result.blocks

        // Position-based diff: preserve IDs for unchanged blocks
        for i in 0..<min(blocks.count, newBlocks.count) {
            if blocks[i].contentHash == newBlocks[i].contentHash
                && blocks[i].kind == newBlocks[i].kind {
                // Unchanged - preserve ID
                newBlocks[i] = EditorNode(
                    id: blocks[i].id,
                    kind: newBlocks[i].kind,
                    sourceRange: newBlocks[i].sourceRange,
                    sourceText: newBlocks[i].sourceText,
                    inlineRuns: newBlocks[i].inlineRuns,
                    children: newBlocks[i].children
                )
                newBlocks[i].isActive = blocks[i].isActive
            }
        }

        blocks = newBlocks
        documentRevision = result.revision
    }

    // Resolve active block from cursor position
    func resolveActiveBlock(cursorOffset: Int, in sourceText: String) -> EditorNode.ID? {
        let cursorIndex = sourceText.index(
            sourceText.startIndex,
            offsetBy: min(cursorOffset, sourceText.count)
        )

        // Find innermost block containing cursor
        var candidate: EditorNode.ID?

        for block in blocks {
            if block.sourceRange.contains(cursorIndex)
                || (cursorIndex == block.sourceRange.upperBound && cursorIndex == sourceText.endIndex) {
                candidate = block.id
                // Check children for deeper match
                for child in block.children {
                    if child.sourceRange.contains(cursorIndex) {
                        candidate = child.id
                    }
                }
            }
        }

        return candidate
    }

    // Set active block, updating isActive flags. Returns IDs that changed.
    @discardableResult
    func setActiveBlock(_ blockID: EditorNode.ID?) -> Set<EditorNode.ID> {
        var changedIDs = Set<EditorNode.ID>()
        let previousActiveID = activeBlockID
        activeBlockID = blockID

        for i in blocks.indices {
            let shouldBeActive = blocks[i].id == blockID
            if blocks[i].isActive != shouldBeActive {
                blocks[i].isActive = shouldBeActive
                changedIDs.insert(blocks[i].id)
            }
            // Also handle children
            for j in blocks[i].children.indices {
                let childShouldBeActive = blocks[i].children[j].id == blockID
                if blocks[i].children[j].isActive != childShouldBeActive {
                    blocks[i].children[j].isActive = childShouldBeActive
                    changedIDs.insert(blocks[i].children[j].id)
                }
            }
        }

        if let prev = previousActiveID, prev != blockID {
            changedIDs.insert(prev)
        }

        return changedIDs
    }

    // Find block by ID
    func block(withID id: EditorNode.ID) -> EditorNode? {
        for block in blocks {
            if block.id == id { return block }
            for child in block.children {
                if child.id == id { return child }
            }
        }
        return nil
    }
}
