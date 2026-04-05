import Testing
@testable import shoechoo

@Suite("EditorViewModel")
@MainActor
struct EditorViewModelTests {

    // MARK: - Headings

    @Test("Empty text produces no headings")
    func headingsEmpty() {
        let vm = EditorViewModel()
        vm.sourceText = ""
        #expect(vm.headings.isEmpty)
    }

    @Test("Single H1 heading is extracted")
    func headingsH1() {
        let vm = EditorViewModel()
        vm.sourceText = "# Title"
        let headings = vm.headings
        #expect(headings.count == 1)
        #expect(headings[0].level == 1)
        #expect(headings[0].title == "Title")
        #expect(headings[0].position == 0)
    }

    @Test("H2 through H6 are extracted with correct levels")
    func headingsH2toH6() {
        let vm = EditorViewModel()
        vm.sourceText = "## Two\n### Three\n#### Four\n##### Five\n###### Six"
        let headings = vm.headings
        #expect(headings.count == 5)
        #expect(headings[0].level == 2)
        #expect(headings[0].title == "Two")
        #expect(headings[1].level == 3)
        #expect(headings[2].level == 4)
        #expect(headings[3].level == 5)
        #expect(headings[4].level == 6)
    }

    @Test("Multiple headings have correct positions")
    func headingsPositions() {
        let vm = EditorViewModel()
        vm.sourceText = "# First\nsome text\n## Second"
        let headings = vm.headings
        #expect(headings.count == 2)
        #expect(headings[0].position == 0)
        // "# First\n" = 8 chars, "some text\n" = 10 chars → offset 18
        #expect(headings[1].position == 18)
    }

    @Test("Line with only hashes and no title is excluded")
    func headingsNoTitle() {
        let vm = EditorViewModel()
        vm.sourceText = "## \n# Real Title"
        let headings = vm.headings
        #expect(headings.count == 1)
        #expect(headings[0].title == "Real Title")
    }

    @Test("More than 6 hashes are ignored")
    func headingsTooManyHashes() {
        let vm = EditorViewModel()
        vm.sourceText = "####### Not a heading"
        #expect(vm.headings.isEmpty)
    }

    @Test("Headings with leading whitespace are detected")
    func headingsLeadingWhitespace() {
        let vm = EditorViewModel()
        vm.sourceText = "  # Indented"
        let headings = vm.headings
        #expect(headings.count == 1)
        #expect(headings[0].title == "Indented")
    }

    @Test("Non-heading lines are not extracted")
    func headingsNonHeading() {
        let vm = EditorViewModel()
        vm.sourceText = "plain text\nanother line"
        #expect(vm.headings.isEmpty)
    }

    // MARK: - Statistics delegation

    @Test("Statistics match DocumentStatistics for same text")
    func statisticsDelegation() {
        let vm = EditorViewModel()
        vm.sourceText = "Hello world\nSecond line"
        let expected = DocumentStatistics(from: "Hello world\nSecond line")
        #expect(vm.statistics == expected)
    }

    @Test("Statistics for empty text are all zero")
    func statisticsEmpty() {
        let vm = EditorViewModel()
        vm.sourceText = ""
        #expect(vm.statistics.wordCount == 0)
        #expect(vm.statistics.characterCount == 0)
        #expect(vm.statistics.lineCount == 0)
    }

    // MARK: - Focus mode / Typewriter scroll

    @Test("toggleFocusMode flips the flag")
    func toggleFocusMode() {
        let vm = EditorViewModel()
        let initial = vm.isFocusModeEnabled
        vm.toggleFocusMode()
        #expect(vm.isFocusModeEnabled == !initial)
        vm.toggleFocusMode()
        #expect(vm.isFocusModeEnabled == initial)
    }

    @Test("toggleTypewriterScroll flips the flag")
    func toggleTypewriterScroll() {
        let vm = EditorViewModel()
        let initial = vm.isTypewriterScrollEnabled
        vm.toggleTypewriterScroll()
        #expect(vm.isTypewriterScrollEnabled == !initial)
        vm.toggleTypewriterScroll()
        #expect(vm.isTypewriterScrollEnabled == initial)
    }

    // MARK: - Error handling

    @Test("clearError resets lastError to nil")
    func clearError() {
        let vm = EditorViewModel()
        vm.lastError = "Something went wrong"
        #expect(vm.lastError != nil)
        vm.clearError()
        #expect(vm.lastError == nil)
    }

    // MARK: - Command delegation with mock

    @Test("toggleBold delegates to commandHandler")
    func toggleBoldDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.toggleBold()
        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "**")
        #expect(mock.toggleFormattingCalls[0].suffix == "**")
    }

    @Test("toggleItalic delegates to commandHandler")
    func toggleItalicDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.toggleItalic()
        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "*")
        #expect(mock.toggleFormattingCalls[0].suffix == "*")
    }

    @Test("toggleInlineCode delegates to commandHandler")
    func toggleInlineCodeDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.toggleInlineCode()
        #expect(mock.toggleFormattingCalls.count == 1)
        #expect(mock.toggleFormattingCalls[0].prefix == "`")
        #expect(mock.toggleFormattingCalls[0].suffix == "`")
    }

    @Test("insertLink delegates to commandHandler")
    func insertLinkDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.insertLink()
        #expect(mock.insertFormattedTextCalls.count == 1)
        #expect(mock.insertFormattedTextCalls[0].text == "[](url)")
        #expect(mock.insertFormattedTextCalls[0].cursorOffset == 1)
    }

    @Test("setHeading delegates correct prefix to commandHandler")
    func setHeadingDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.setHeading(level: 3)
        #expect(mock.setLinePrefixCalls.count == 1)
        #expect(mock.setLinePrefixCalls[0] == "### ")
    }

    @Test("insertImage delegates to commandHandler")
    func insertImageDelegation() {
        let vm = EditorViewModel()
        let mock = MockCommandHandler()
        vm.commandHandler = mock
        vm.insertImage(at: 5, relativePath: "assets/img.png")
        #expect(mock.insertImageMarkdownCalls.count == 1)
        #expect(mock.insertImageMarkdownCalls[0].markdown == "![](assets/img.png)")
        #expect(mock.insertImageMarkdownCalls[0].position == 5)
    }

    @Test("Commands are no-op when commandHandler is nil")
    func commandHandlerNil() {
        let vm = EditorViewModel()
        // Should not crash
        vm.toggleBold()
        vm.toggleItalic()
        vm.toggleInlineCode()
        vm.insertLink()
        vm.setHeading(level: 1)
        vm.insertImage(at: 0, relativePath: "test.png")
    }
}

// MARK: - Mock

@MainActor
private final class MockCommandHandler: EditorCommandHandler {
    struct ToggleFormattingCall {
        let prefix: String
        let suffix: String
    }
    struct InsertFormattedTextCall {
        let text: String
        let cursorOffset: Int
    }
    struct InsertImageMarkdownCall {
        let markdown: String
        let position: Int
    }

    var toggleFormattingCalls: [ToggleFormattingCall] = []
    var insertFormattedTextCalls: [InsertFormattedTextCall] = []
    var setLinePrefixCalls: [String] = []
    var insertImageMarkdownCalls: [InsertImageMarkdownCall] = []
    var scrollToPositionCalls: [Int] = []

    func toggleFormatting(prefix: String, suffix: String) {
        toggleFormattingCalls.append(ToggleFormattingCall(prefix: prefix, suffix: suffix))
    }

    func insertFormattedText(_ text: String, cursorOffset: Int) {
        insertFormattedTextCalls.append(InsertFormattedTextCall(text: text, cursorOffset: cursorOffset))
    }

    func setLinePrefix(_ prefix: String) {
        setLinePrefixCalls.append(prefix)
    }

    func insertImageMarkdown(_ markdown: String, at position: Int) {
        insertImageMarkdownCalls.append(InsertImageMarkdownCall(markdown: markdown, position: position))
    }

    func scrollToPosition(_ position: Int) {
        scrollToPositionCalls.append(position)
    }
}
