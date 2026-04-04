import Foundation

final class RenderCache {
    private var cache: [EditorNode.ID: RenderResult] = [:]

    func get(_ id: EditorNode.ID) -> RenderResult? {
        cache[id]
    }

    func set(_ id: EditorNode.ID, result: RenderResult) {
        cache[id] = result
    }

    func invalidate(_ id: EditorNode.ID) {
        cache.removeValue(forKey: id)
    }

    func invalidateAll() {
        cache.removeAll()
    }

    func invalidate(_ ids: Set<EditorNode.ID>) {
        for id in ids {
            cache.removeValue(forKey: id)
        }
    }
}
