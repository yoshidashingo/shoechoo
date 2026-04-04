import Foundation

@Observable @MainActor
final class EditorNodeModel {
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

    // Resolve active block from cursor position (UTF-16 offset)
    func resolveActiveBlock(cursorOffset: Int) -> EditorNode.ID? {
        var candidate: EditorNode.ID?

        for block in blocks {
            let blockEnd = block.sourceRange.location + block.sourceRange.length
            if cursorOffset >= block.sourceRange.location && cursorOffset <= blockEnd {
                candidate = block.id
                for child in block.children {
                    let childEnd = child.sourceRange.location + child.sourceRange.length
                    if cursorOffset >= child.sourceRange.location && cursorOffset <= childEnd {
                        candidate = child.id
                    }
                }
            }
        }

        // If cursor is in a gap between blocks, find the nearest block (#43)
        if candidate == nil && !blocks.isEmpty {
            var bestBlock = blocks[0]
            var bestDistance = Int.max
            for block in blocks {
                let blockEnd = block.sourceRange.location + block.sourceRange.length
                let distToStart = abs(cursorOffset - block.sourceRange.location)
                let distToEnd = abs(cursorOffset - blockEnd)
                let dist = min(distToStart, distToEnd)
                if dist < bestDistance {
                    bestDistance = dist
                    bestBlock = block
                }
            }
            candidate = bestBlock.id
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
