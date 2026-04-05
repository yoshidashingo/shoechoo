import Testing
@testable import shoechoo

@Suite("EditorCommandHandler")
@MainActor
struct EditorCommandHandlerTests {

    // Mock implementation to capture calls
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

    @Test("toggleBold dispatches to commandHandler with ** prefix/suffix")
    func toggleBold() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.toggleBold()

        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "**")
        #expect(mock.toggleFormattingCalls[0].suffix == "**")
    }

    @Test("toggleItalic dispatches to commandHandler with * prefix/suffix")
    func toggleItalic() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.toggleItalic()

        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "*")
        #expect(mock.toggleFormattingCalls[0].suffix == "*")
    }

    @Test("toggleInlineCode dispatches with backtick")
    func toggleInlineCode() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.toggleInlineCode()

        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "`")
    }

    @Test("insertLink dispatches insertFormattedText with link template")
    func insertLink() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.insertLink()

        #expect(mock.insertFormattedTextCalls.count == 1)
        #expect(mock.insertFormattedTextCalls[0].text == "[](url)")
        #expect(mock.insertFormattedTextCalls[0].cursorOffset == 1)
    }

    @Test("setHeading dispatches setLinePrefix with correct # prefix")
    func setHeading() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.setHeading(level: 3)

        #expect(mock.setLinePrefixCalls.count == 1)
        #expect(mock.setLinePrefixCalls[0] == "### ")
    }

    @Test("insertImage dispatches insertImageMarkdown")
    func insertImage() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.insertImage(at: 42, relativePath: "assets/photo.png")

        #expect(mock.insertImageMarkdownCalls.count == 1)
        #expect(mock.insertImageMarkdownCalls[0].markdown == "![](assets/photo.png)")
        #expect(mock.insertImageMarkdownCalls[0].position == 42)
    }

    @Test("commands do nothing when commandHandler is nil (no crash)")
    func nilCommandHandler() {
        let vm = EditorViewModel()
        // commandHandler is nil by default
        vm.toggleBold()
        vm.toggleItalic()
        vm.insertLink()
        vm.setHeading(level: 1)
        vm.insertImage(at: 0, relativePath: "test.png")
        // No crash = pass
    }

    @Test("scrollToPosition dispatches directly via commandHandler")
    func scrollToPosition() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock

        vm.commandHandler?.scrollToPosition(42)

        #expect(mock.scrollToPositionCalls.count == 1)
        #expect(mock.scrollToPositionCalls[0] == 42)
    }

    @Test("multiple viewModels with separate handlers don't interfere")
    func multipleViewModels() {
        let vm1 = EditorViewModel()
        let vm2 = EditorViewModel()
        let mock1 = MockCommandHandler()
        let mock2 = MockCommandHandler()
        vm1.commandHandler = mock1
        vm2.commandHandler = mock2

        vm1.toggleBold()
        vm2.toggleItalic()

        #expect(mock1.toggleFormattingCalls.count == 1)
        #expect(mock1.toggleFormattingCalls[0].prefix == "**")
        #expect(mock2.toggleFormattingCalls.count == 1)
        #expect(mock2.toggleFormattingCalls[0].prefix == "*")
    }
}
