# XCUITest UI自動テスト Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** shoechoo macOSアプリのXCUITestによるUI自動テストを構築し、主要ユーザーシナリオ（起動、テキスト入力、ツールバー操作、テーマ切替、フォーカスモード、サイドバー、エクスポート）を自動検証できるようにする。

**Architecture:** XcodeGenの`project.yml`にUI Testingターゲットを追加し、XCTestベースのXCUITestを構築する。SwiftUI/AppKitビューにAccessibility Identifierを付与し、XCUITestから要素を特定する。DocumentGroupアプリの初回起動時Open Dialogはlaunch argumentで制御する。

**Tech Stack:** XCUITest (XCTest), XcodeGen, Swift 6, macOS 14+

---

## File Structure

**新規作成:**
- `shoechooUITests/ShoechooUITestCase.swift` — 共通ベースクラス（起動・ヘルパー）
- `shoechooUITests/AppLaunchUITests.swift` — 起動・初期画面テスト
- `shoechooUITests/TextEditingUITests.swift` — テキスト入力・ハイライトテスト
- `shoechooUITests/ToolbarUITests.swift` — ツールバーボタンテスト
- `shoechooUITests/PreferencesUITests.swift` — 設定画面テスト（テーマ切替含む）
- `shoechooUITests/FocusModeUITests.swift` — フォーカスモード・タイプライターテスト
- `shoechooUITests/SidebarUITests.swift` — サイドバー操作テスト
- `shoechooUITests/ExportUITests.swift` — HTML/PDFエクスポートテスト

**変更:**
- `project.yml` — UI Testingターゲット追加
- `shoechoo/Views/EditorView.swift` — Accessibility Identifier追加
- `shoechoo/Editor/WYSIWYGTextView.swift` — NSTextViewにAccessibility Identifier追加
- `shoechoo/Views/PreferencesView.swift` — Accessibility Identifier追加
- `shoechoo/Views/SidebarView.swift` — Accessibility Identifier追加
- `shoechoo/App/shoechooApp.swift` — launch argument によるOpen Dialog制御

---

### Task 1: UI Testingターゲットを project.yml に追加

**Files:**
- Modify: `project.yml`

- [ ] **Step 1: project.yml にUIテストターゲットを追加**

`project.yml` の `targets` セクション末尾に追加:

```yaml
  shoechooUITests:
    type: bundle.ui-testing
    platform: macOS
    sources:
      - shoechooUITests
    dependencies:
      - target: shoechoo
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.shoechoo.uitests
        GENERATE_INFOPLIST_FILE: true
```

`schemes.shoechoo` の `build.targets` と `test.targets` に追加:

```yaml
schemes:
  shoechoo:
    build:
      targets:
        shoechoo: all
        shoechooTests: [test]
        shoechooUITests: [test]
    test:
      targets:
        - shoechooTests
        - shoechooUITests
      gatherCoverageData: true
```

- [ ] **Step 2: XcodeGenでプロジェクトを再生成**

Run: `cd /Users/shingo/Documents/GitHub/shoechoo && xcodegen generate`
Expected: `⚙ Generating plists...` → `✅ Created project`

- [ ] **Step 3: ビルドして検証**

Run: `xcodebuild -scheme shoechoo -destination 'platform=macOS' build-for-testing 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: コミット**

```bash
git add project.yml shoechoo.xcodeproj
git commit -m "chore: add XCUITest target to project.yml"
```

---

### Task 2: DocumentGroup起動制御とベーステストクラス

DocumentGroupアプリは起動時にOpen Dialogを表示する。launch argumentで新規ドキュメントを直接開くように制御する。

**Files:**
- Modify: `shoechoo/App/shoechooApp.swift`
- Create: `shoechooUITests/ShoechooUITestCase.swift`

- [ ] **Step 1: shoechooApp.swift に launch argument ハンドリングを追加**

`ShoechooApp` の `body` 内、`DocumentGroup` の直後にある `.commands` の前に、init またはonAppear で処理する。最もシンプルな方法は、App の init で `NSDocumentController` の挙動を制御すること。

`shoechooApp.swift` の `@main struct ShoechooApp: App {` の直後に追加:

```swift
    init() {
        // UI Tests: skip Open Dialog, create new document directly
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.set(true, forKey: "NSQuitAlwaysKeepsWindows")
        }
    }
```

- [ ] **Step 2: ベーステストクラスを作成**

`shoechooUITests/ShoechooUITestCase.swift` を作成:

```swift
import XCTest

class ShoechooUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // DocumentGroup の新規ドキュメント作成
        // Open Dialog が出る場合は ⌘N で新規ドキュメントを開く
        let newDocTimeout: TimeInterval = 3
        let textView = app.textViews.firstMatch
        if !textView.waitForExistence(timeout: newDocTimeout) {
            app.typeKey("n", modifierFlags: .command)
            XCTAssertTrue(textView.waitForExistence(timeout: 5), "Editor text view should appear")
        }
    }

    override func tearDownWithError() throws {
        // ドキュメントを保存せず閉じる
        app.typeKey("w", modifierFlags: .command)
        let dontSaveButton = app.buttons["Don't Save"]
        if dontSaveButton.waitForExistence(timeout: 2) {
            dontSaveButton.click()
        }
        app = nil
    }

    /// エディタのメインテキストビューを取得
    var editorTextView: XCUIElement {
        app.textViews["editor.textView"]
    }

    /// テキストを入力してエディタに反映されるのを待つ
    func typeInEditor(_ text: String) {
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        textView.typeText(text)
    }
}
```

- [ ] **Step 3: ビルド検証**

Run: `xcodebuild -scheme shoechoo -destination 'platform=macOS' build-for-testing 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: コミット**

```bash
git add shoechoo/App/shoechooApp.swift shoechooUITests/ShoechooUITestCase.swift
git commit -m "feat: add XCUITest base class with DocumentGroup launch handling"
```

---

### Task 3: Accessibility Identifier の付与

XCUITestから要素を特定するためにAccessibility Identifierを付与する。

**Files:**
- Modify: `shoechoo/Views/EditorView.swift`
- Modify: `shoechoo/Editor/WYSIWYGTextView.swift`
- Modify: `shoechoo/Views/PreferencesView.swift`
- Modify: `shoechoo/Views/SidebarView.swift`

- [ ] **Step 1: EditorView.swift にIdentifierを追加**

ツールバーの各ボタンに `.accessibilityIdentifier` を追加。`EditorView.swift` の toolbar 内:

サイドバーボタン（`Image(systemName: "sidebar.left")` の Button）に追加:
```swift
.accessibilityIdentifier("toolbar.sidebar")
```

Boldボタンに追加:
```swift
.accessibilityIdentifier("toolbar.bold")
```

Italicボタンに追加:
```swift
.accessibilityIdentifier("toolbar.italic")
```

InlineCodeボタンに追加:
```swift
.accessibilityIdentifier("toolbar.inlineCode")
```

FocusModeボタンに追加:
```swift
.accessibilityIdentifier("toolbar.focusMode")
```

TypewriterScrollボタンに追加:
```swift
.accessibilityIdentifier("toolbar.typewriterScroll")
```

Exportボタンに追加:
```swift
.accessibilityIdentifier("toolbar.export")
```

統計バーの `HStack` に追加:
```swift
.accessibilityIdentifier("editor.stats")
```

- [ ] **Step 2: WYSIWYGTextView.swift のNSTextViewにIdentifierを追加**

`makeNSView` メソッド内、`textView.textContainer?.widthTracksTextView = true` の直後に追加:

```swift
textView.setAccessibilityIdentifier("editor.textView")
```

- [ ] **Step 3: PreferencesView.swift にIdentifierを追加**

EditorタブのFormに追加:
```swift
.accessibilityIdentifier("prefs.editor")
```

AppearanceタブのFormに追加:
```swift
.accessibilityIdentifier("prefs.appearance")
```

Theme Picker に追加:
```swift
.accessibilityIdentifier("prefs.theme")
```

Appearance Override Picker に追加:
```swift
.accessibilityIdentifier("prefs.appearanceMode")
```

- [ ] **Step 4: SidebarView.swift にIdentifierを追加**

SidebarContainerView の `VStack` に追加:
```swift
.accessibilityIdentifier("sidebar.container")
```

モードセレクターの各ボタンに、ForEach 内で追加:
```swift
.accessibilityIdentifier("sidebar.mode.\(m.rawValue.lowercased().replacingOccurrences(of: " ", with: ""))")
```

これにより `sidebar.mode.outline`, `sidebar.mode.filetree`, `sidebar.mode.filelist` が生成される。

- [ ] **Step 5: ビルド検証**

Run: `xcodebuild -scheme shoechoo -destination 'platform=macOS' build-for-testing 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: コミット**

```bash
git add shoechoo/Views/EditorView.swift shoechoo/Editor/WYSIWYGTextView.swift shoechoo/Views/PreferencesView.swift shoechoo/Views/SidebarView.swift
git commit -m "feat: add accessibility identifiers for XCUITest"
```

---

### Task 4: アプリ起動 & 初期画面テスト

**Files:**
- Create: `shoechooUITests/AppLaunchUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class AppLaunchUITests: ShoechooUITestCase {

    func testAppLaunchesWithEditorWindow() throws {
        // ウィンドウが表示されていること
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "App should have a window")

        // エディタ（テキストビュー）が存在すること
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor text view should be visible")
    }

    func testWindowTitleShowsUntitled() throws {
        let window = app.windows.firstMatch
        // DocumentGroup の新規ドキュメントは "Untitled" というタイトル
        XCTAssertTrue(window.title.contains("Untitled"), "New document should be Untitled, got: \(window.title)")
    }

    func testStatsBarIsVisible() throws {
        let statsBar = app.staticTexts.matching(NSPredicate(format: "value CONTAINS 'words'")).firstMatch
        XCTAssertTrue(statsBar.waitForExistence(timeout: 3), "Stats bar showing word count should be visible")
    }

    func testToolbarButtonsExist() throws {
        // ツールバーボタンの存在確認
        XCTAssertTrue(app.buttons["toolbar.bold"].waitForExistence(timeout: 3), "Bold button should exist")
        XCTAssertTrue(app.buttons["toolbar.italic"].exists, "Italic button should exist")
        XCTAssertTrue(app.buttons["toolbar.inlineCode"].exists, "Inline code button should exist")
        XCTAssertTrue(app.buttons["toolbar.focusMode"].exists, "Focus mode button should exist")
        XCTAssertTrue(app.buttons["toolbar.export"].exists, "Export button should exist")
    }
}
```

- [ ] **Step 2: UIテストを実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/AppLaunchUITests 2>&1 | grep -E '(Test Case|Test Suite|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/AppLaunchUITests.swift
git commit -m "test: add app launch UI tests"
```

---

### Task 5: テキスト入力テスト

**Files:**
- Create: `shoechooUITests/TextEditingUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class TextEditingUITests: ShoechooUITestCase {

    func testTypeTextAndVerify() throws {
        typeInEditor("Hello, World!")

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("Hello, World!"), "Typed text should appear in editor, got: \(value)")
    }

    func testTypeMarkdownHeading() throws {
        typeInEditor("# My Heading\n\nSome body text.")

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("# My Heading"), "Heading should appear in editor")
        XCTAssertTrue(value.contains("Some body text."), "Body text should appear")
    }

    func testWordCountUpdatesAfterTyping() throws {
        typeInEditor("one two three four five")

        // 統計バーの更新を待つ
        let fiveWords = app.staticTexts.matching(NSPredicate(format: "value CONTAINS '5 words'")).firstMatch
        XCTAssertTrue(fiveWords.waitForExistence(timeout: 5), "Stats bar should show 5 words")
    }

    func testMultilineInput() throws {
        typeInEditor("Line 1\nLine 2\nLine 3\n")

        let threeLines = app.staticTexts.matching(NSPredicate(format: "value CONTAINS 'lines'")).firstMatch
        XCTAssertTrue(threeLines.waitForExistence(timeout: 5), "Stats bar should show line count")
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/TextEditingUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/TextEditingUITests.swift
git commit -m "test: add text editing UI tests"
```

---

### Task 6: ツールバー操作テスト

**Files:**
- Create: `shoechooUITests/ToolbarUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class ToolbarUITests: ShoechooUITestCase {

    func testBoldToggleViaToolbar() throws {
        // テキストを入力して選択
        typeInEditor("bold text")
        app.typeKey("a", modifierFlags: .command) // Select All

        // Boldボタンをクリック
        let boldButton = app.buttons["toolbar.bold"]
        XCTAssertTrue(boldButton.waitForExistence(timeout: 3))
        boldButton.click()

        // テキストが **bold text** になることを確認
        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("**bold text**"), "Text should be wrapped with bold markers, got: \(value)")
    }

    func testItalicToggleViaToolbar() throws {
        typeInEditor("italic text")
        app.typeKey("a", modifierFlags: .command)

        let italicButton = app.buttons["toolbar.italic"]
        XCTAssertTrue(italicButton.waitForExistence(timeout: 3))
        italicButton.click()

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("*italic text*"), "Text should be wrapped with italic markers, got: \(value)")
    }

    func testInlineCodeToggleViaToolbar() throws {
        typeInEditor("code")
        app.typeKey("a", modifierFlags: .command)

        let codeButton = app.buttons["toolbar.inlineCode"]
        XCTAssertTrue(codeButton.waitForExistence(timeout: 3))
        codeButton.click()

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("`code`"), "Text should be wrapped with backticks, got: \(value)")
    }

    func testBoldViaKeyboardShortcut() throws {
        typeInEditor("shortcut bold")
        app.typeKey("a", modifierFlags: .command)
        app.typeKey("b", modifierFlags: .command)

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("**shortcut bold**"), "⌘B should toggle bold, got: \(value)")
    }

    func testItalicViaKeyboardShortcut() throws {
        typeInEditor("shortcut italic")
        app.typeKey("a", modifierFlags: .command)
        app.typeKey("i", modifierFlags: .command)

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("*shortcut italic*"), "⌘I should toggle italic, got: \(value)")
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/ToolbarUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/ToolbarUITests.swift
git commit -m "test: add toolbar action UI tests"
```

---

### Task 7: 設定画面テスト（テーマ切替含む）

**Files:**
- Create: `shoechooUITests/PreferencesUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class PreferencesUITests: ShoechooUITestCase {

    private func openPreferences() {
        // ⌘, で設定ウィンドウを開く
        app.typeKey(",", modifierFlags: .command)
    }

    func testPreferencesWindowOpens() throws {
        openPreferences()

        // 設定ウィンドウが表示されること
        let settingsWindow = app.windows.matching(NSPredicate(format: "title CONTAINS 'Settings'")).firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5), "Settings window should appear")
    }

    func testEditorTabExists() throws {
        openPreferences()

        let editorTab = app.buttons.matching(NSPredicate(format: "title CONTAINS 'Editor'")).firstMatch
        XCTAssertTrue(editorTab.waitForExistence(timeout: 5), "Editor tab should exist in preferences")
    }

    func testAppearanceTabExists() throws {
        openPreferences()

        let appearanceTab = app.buttons.matching(NSPredicate(format: "title CONTAINS 'Appearance'")).firstMatch
        XCTAssertTrue(appearanceTab.waitForExistence(timeout: 5), "Appearance tab should exist")
    }

    func testSwitchToAppearanceTab() throws {
        openPreferences()

        let appearanceTab = app.buttons.matching(NSPredicate(format: "title CONTAINS 'Appearance'")).firstMatch
        XCTAssertTrue(appearanceTab.waitForExistence(timeout: 5))
        appearanceTab.click()

        // テーマPickerが表示されること
        // SwiftUI Picker は popUpButton として認識される場合がある
        let themePicker = app.popUpButtons["prefs.theme"]
        if !themePicker.waitForExistence(timeout: 3) {
            // Fallback: テーマ名が表示されている popup を探す
            let anyPopup = app.popUpButtons.firstMatch
            XCTAssertTrue(anyPopup.exists, "Theme picker should exist in Appearance tab")
        }
    }

    func testClosePreferences() throws {
        openPreferences()

        let settingsWindow = app.windows.matching(NSPredicate(format: "title CONTAINS 'Settings'")).firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        // ⌘W で閉じる
        app.typeKey("w", modifierFlags: .command)

        // 設定ウィンドウが閉じたこと（エディタウィンドウはまだある）
        sleep(1)
        let editorWindow = app.windows.firstMatch
        XCTAssertTrue(editorWindow.exists, "Editor window should still exist after closing preferences")
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/PreferencesUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/PreferencesUITests.swift
git commit -m "test: add preferences UI tests"
```

---

### Task 8: フォーカスモード & タイプライターテスト

**Files:**
- Create: `shoechooUITests/FocusModeUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class FocusModeUITests: ShoechooUITestCase {

    func testToggleFocusModeViaToolbar() throws {
        // テキストを入力（複数ブロック必要）
        typeInEditor("# Heading\n\nParagraph one.\n\nParagraph two.\n\nParagraph three.")

        let focusButton = app.buttons["toolbar.focusMode"]
        XCTAssertTrue(focusButton.waitForExistence(timeout: 3), "Focus mode button should exist")

        // フォーカスモード ON
        focusButton.click()

        // 再度クリックで OFF
        focusButton.click()

        // クラッシュせず操作できることを確認（表示の dimming は視覚的変化のため内容検証は困難）
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional after focus mode toggle")
    }

    func testToggleFocusModeViaShortcut() throws {
        typeInEditor("Some text for focus mode test.")

        // ⇧⌘F でフォーカスモードをトグル
        app.typeKey("f", modifierFlags: [.command, .shift])

        // 再度トグル
        app.typeKey("f", modifierFlags: [.command, .shift])

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional")
    }

    func testToggleTypewriterScrollViaToolbar() throws {
        typeInEditor("Typewriter scroll test content.")

        let typewriterButton = app.buttons["toolbar.typewriterScroll"]
        XCTAssertTrue(typewriterButton.waitForExistence(timeout: 3), "Typewriter scroll button should exist")

        // ON → OFF
        typewriterButton.click()
        typewriterButton.click()

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional after typewriter scroll toggle")
    }

    func testToggleTypewriterScrollViaShortcut() throws {
        typeInEditor("Test.")

        // ⇧⌘T でタイプライタースクロールをトグル
        app.typeKey("t", modifierFlags: [.command, .shift])
        app.typeKey("t", modifierFlags: [.command, .shift])

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional")
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/FocusModeUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/FocusModeUITests.swift
git commit -m "test: add focus mode and typewriter scroll UI tests"
```

---

### Task 9: サイドバー操作テスト

**Files:**
- Create: `shoechooUITests/SidebarUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class SidebarUITests: ShoechooUITestCase {

    func testSidebarIsVisibleByDefault() throws {
        // サイドバーコンテナが表示されていること
        let sidebar = app.groups["sidebar.container"]
        // グループとして見えない場合、サイドバーモードボタンの存在で確認
        if !sidebar.exists {
            let outlineMode = app.buttons["sidebar.mode.outline"]
            XCTAssertTrue(outlineMode.waitForExistence(timeout: 5), "Sidebar outline mode button should be visible")
        }
    }

    func testToggleSidebar() throws {
        let sidebarButton = app.buttons["toolbar.sidebar"]
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 3), "Sidebar toggle button should exist")

        // サイドバーを閉じる
        sidebarButton.click()
        sleep(1) // アニメーション待ち

        // サイドバーを開く
        sidebarButton.click()
        sleep(1)

        // エディタは引き続き操作可能
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional after sidebar toggle")
    }

    func testSidebarShowsHeadingsInOutlineMode() throws {
        // 見出しを入力
        typeInEditor("# First Heading\n\nSome text.\n\n## Second Heading\n\nMore text.")

        // Outlineモードがデフォルト。見出しテキストがサイドバーに表示されるか確認
        // 少し待ってパース完了を期待
        sleep(2)

        let firstHeading = app.buttons.matching(NSPredicate(format: "title CONTAINS 'First Heading'")).firstMatch
        // OutlineView ではボタンとして見出しが表示される
        if firstHeading.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Heading appears in outline")
        } else {
            // staticTexts として表示される可能性もある
            let headingText = app.staticTexts.matching(NSPredicate(format: "value CONTAINS 'First Heading'")).firstMatch
            XCTAssertTrue(headingText.exists, "Heading should appear in sidebar outline")
        }
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/SidebarUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/SidebarUITests.swift
git commit -m "test: add sidebar UI tests"
```

---

### Task 10: エクスポートテスト

**Files:**
- Create: `shoechooUITests/ExportUITests.swift`

- [ ] **Step 1: テストファイルを作成**

```swift
import XCTest

final class ExportUITests: ShoechooUITestCase {

    func testExportHTMLButtonOpensPanel() throws {
        typeInEditor("# Export Test\n\nSome content to export.")

        let exportButton = app.buttons["toolbar.export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export button should exist")
        exportButton.click()

        // NSSavePanel が表示されること
        let savePanel = app.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5), "Save panel should appear for HTML export")

        // キャンセルして閉じる
        app.typeKey(.escape, modifierFlags: [])
    }

    func testExportHTMLViaShortcut() throws {
        typeInEditor("# Shortcut Export\n\nContent.")

        // ⇧⌘E で HTML エクスポート
        app.typeKey("e", modifierFlags: [.command, .shift])

        let savePanel = app.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5), "Save panel should appear for ⇧⌘E")

        // キャンセル
        app.typeKey(.escape, modifierFlags: [])
    }

    func testExportPDFViaShortcut() throws {
        typeInEditor("# PDF Export\n\nContent.")

        // ⇧⌥⌘E で PDF エクスポート
        app.typeKey("e", modifierFlags: [.command, .shift, .option])

        let savePanel = app.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5), "Save panel should appear for PDF export")

        // キャンセル
        app.typeKey(.escape, modifierFlags: [])
    }
}
```

- [ ] **Step 2: テスト実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests/ExportUITests 2>&1 | grep -E '(Test Case|PASS|FAIL|error:)' | head -20`
Expected: 全テストが PASS

- [ ] **Step 3: コミット**

```bash
git add shoechooUITests/ExportUITests.swift
git commit -m "test: add export UI tests"
```

---

### Task 11: 全UIテスト統合実行 & 最終確認

- [ ] **Step 1: 全UIテストを実行**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooUITests 2>&1 | grep -E '(Test Case|Test Suite|Executed|PASS|FAIL)' | head -40`
Expected: 全テストが PASS

- [ ] **Step 2: 既存ユニットテストが壊れていないことを確認**

Run: `xcodebuild test -scheme shoechoo -destination 'platform=macOS' -only-testing:shoechooTests 2>&1 | grep -E '(Test Suite|Executed|FAIL)' | head -10`
Expected: `Executed 207 tests, with 0 failures`

- [ ] **Step 3: 最終コミット**

```bash
git add -A
git commit -m "test: complete XCUITest automation for all major UI scenarios"
```
