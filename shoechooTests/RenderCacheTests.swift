import Testing
import Foundation
import AppKit
@testable import shoechoo

@Suite("RenderCache")
struct RenderCacheTests {

    /// Helper to create a RenderResult with a given block ID.
    private func makeResult(id: UUID, text: String = "test") -> RenderResult {
        RenderResult(
            blockID: id,
            attributedString: NSAttributedString(string: text),
            isActive: false
        )
    }

    // MARK: - Set and Get

    @Test("Set and get returns cached result")
    func setAndGet() {
        let cache = RenderCache()
        let id = UUID()
        let result = makeResult(id: id, text: "hello")

        cache.set(id, result: result)
        let retrieved = cache.get(id)

        #expect(retrieved != nil)
        #expect(retrieved?.blockID == id)
        #expect(retrieved?.attributedString.string == "hello")
    }

    @Test("Get returns nil for unknown ID")
    func getUnknownReturnsNil() {
        let cache = RenderCache()
        #expect(cache.get(UUID()) == nil)
    }

    @Test("Set overwrites existing entry")
    func setOverwrites() {
        let cache = RenderCache()
        let id = UUID()

        cache.set(id, result: makeResult(id: id, text: "first"))
        cache.set(id, result: makeResult(id: id, text: "second"))

        let retrieved = cache.get(id)
        #expect(retrieved?.attributedString.string == "second")
    }

    // MARK: - Invalidate Single

    @Test("Invalidate single removes entry")
    func invalidateSingle() {
        let cache = RenderCache()
        let id = UUID()
        cache.set(id, result: makeResult(id: id))

        cache.invalidate(id)
        #expect(cache.get(id) == nil)
    }

    @Test("Invalidate single does not affect other entries")
    func invalidateSingleLeavesOthers() {
        let cache = RenderCache()
        let id1 = UUID()
        let id2 = UUID()
        cache.set(id1, result: makeResult(id: id1, text: "one"))
        cache.set(id2, result: makeResult(id: id2, text: "two"))

        cache.invalidate(id1)
        #expect(cache.get(id1) == nil)
        #expect(cache.get(id2) != nil)
    }

    // MARK: - Invalidate Multiple

    @Test("Invalidate multiple removes specified entries")
    func invalidateMultiple() {
        let cache = RenderCache()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        cache.set(id1, result: makeResult(id: id1))
        cache.set(id2, result: makeResult(id: id2))
        cache.set(id3, result: makeResult(id: id3))

        cache.invalidate(Set([id1, id3]))
        #expect(cache.get(id1) == nil)
        #expect(cache.get(id2) != nil)
        #expect(cache.get(id3) == nil)
    }

    @Test("Invalidate empty set changes nothing")
    func invalidateEmptySet() {
        let cache = RenderCache()
        let id = UUID()
        cache.set(id, result: makeResult(id: id))

        cache.invalidate(Set<UUID>())
        #expect(cache.get(id) != nil)
    }

    // MARK: - Invalidate All

    @Test("Invalidate all clears all entries")
    func invalidateAll() {
        let cache = RenderCache()
        let id1 = UUID()
        let id2 = UUID()
        cache.set(id1, result: makeResult(id: id1))
        cache.set(id2, result: makeResult(id: id2))

        cache.invalidateAll()
        #expect(cache.get(id1) == nil)
        #expect(cache.get(id2) == nil)
    }

    @Test("Invalidate all on empty cache does not crash")
    func invalidateAllEmpty() {
        let cache = RenderCache()
        cache.invalidateAll()
        #expect(cache.get(UUID()) == nil)
    }
}
