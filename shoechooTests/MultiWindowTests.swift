import Testing
@testable import shoechoo

@Suite("Multi-Window Isolation (FR-02)")
@MainActor
struct MultiWindowTests {

    final class MockCommandHandler: EditorCommandHandler {
        var toggleFormattingCalls: [(prefix: String, suffix: String)] = []
        var insertFormattedTextCalls: [(text: String, cursorOffset: Int)] = []
        var setLinePrefixCalls: [String] = []
        var insertImageMarkdownCalls: [(markdown: String, position: Int)] = []
        var scrollToPositionCalls: [Int] = []

        func toggleFormatting(prefix: String, suffix: String) {
            toggleFormattingCalls.append((prefix, suffix))
        }
        func insertFormattedText(_ text: String, cursorOffset: Int) {
            insertFormattedTextCalls.append((text, cursorOffset))
        }
        func setLinePrefix(_ prefix: String) {
            setLinePrefixCalls.append(prefix)
        }
        func insertImageMarkdown(_ markdown: String, at position: Int) {
            insertImageMarkdownCalls.append((markdown, position))
        }
        func scrollToPosition(_ position: Int) {
            scrollToPositionCalls.append(position)
        }
    }

    @Test("Two ViewModels with separate handlers: bold on VM1 does not affect VM2")
    func boldIsolation() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()
        let handler1 = MockCommandHandler()
        let handler2 = MockCommandHandler()
        vm1.commandHandler = handler1
        vm2.commandHandler = handler2

        vm1.toggleBold()

        #expect(handler1.toggleFormattingCalls.count == 1)
        #expect(handler2.toggleFormattingCalls.count == 0)
    }

    @Test("Two ViewModels: heading on VM2 does not affect VM1")
    func headingIsolation() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()
        let handler1 = MockCommandHandler()
        let handler2 = MockCommandHandler()
        vm1.commandHandler = handler1
        vm2.commandHandler = handler2

        vm2.setHeading(level: 2)

        #expect(handler1.setLinePrefixCalls.count == 0)
        #expect(handler2.setLinePrefixCalls.count == 1)
        #expect(handler2.setLinePrefixCalls[0] == "## ")
    }

    @Test("Two ViewModels: image insert on VM1 does not affect VM2")
    func imageIsolation() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()
        let handler1 = MockCommandHandler()
        let handler2 = MockCommandHandler()
        vm1.commandHandler = handler1
        vm2.commandHandler = handler2

        vm1.insertImage(at: 10, relativePath: "assets/img.png")

        #expect(handler1.insertImageMarkdownCalls.count == 1)
        #expect(handler2.insertImageMarkdownCalls.count == 0)
    }

    @Test("Independent sourceText: editing VM1 does not change VM2")
    func sourceTextIsolation() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()
        vm1.sourceText = "Document 1"
        vm2.sourceText = "Document 2"

        #expect(vm1.sourceText == "Document 1")
        #expect(vm2.sourceText == "Document 2")
    }

    @Test("Independent focus mode: toggling VM1 does not affect VM2")
    func focusModeIsolation() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()

        vm1.toggleFocusMode()

        #expect(vm1.isFocusModeEnabled == true)
        #expect(vm2.isFocusModeEnabled == false)
    }
}
