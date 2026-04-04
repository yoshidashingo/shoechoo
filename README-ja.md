<h1 align="center">
  <img src="docs/icon.png" alt="Shoe Choo" width="128">
  <br>
  集中エディタ (Shoe Choo Editor)
  <br>
  <br>
</h1>

<p align="center">
  書くことに集中できる、macOS向けのシンプルなMarkdownエディタ。
</p>

<p align="center">
  <a href="https://github.com/yoshidashingo/shoechoo/releases/latest"><img src="https://img.shields.io/github/v/release/yoshidashingo/shoechoo" alt="release"></a>
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE"><img src="https://img.shields.io/github/license/yoshidashingo/shoechoo" alt="license"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="platform">
  <img src="https://img.shields.io/badge/swift-6-orange" alt="swift">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README-ja.md">日本語</a>
</p>

## 特徴

### シームレスな編集体験
- **ライブプレビュー** — 入力と同時にMarkdown記法がその場でレンダリングされる、Typoraライクな見たまま編集
- **クリーンなインターフェース** — 余計なUIを排除し、文章に集中できるミニマルなデザイン
- **シンタックスハイライト** — Markdownの各要素とコードブロック（Highlightr使用）を視覚的にわかりやすく、かつ邪魔にならない繊細なハイライト

### 書くことへの集中
- **フォーカスモード** — 現在の段落以外を薄く表示し、今書いている部分に意識を集中
- **タイプライタースクロール** — アクティブな行を画面中央に保ち、快適な書き心地を実現
- **フルスクリーン** — 没入感のあるフルスクリーン執筆環境

### Markdown
- **GFMサポート** — 見出し、太字、斜体、取り消し線、リスト、タスクリスト、テーブル、コードブロック、引用、水平線、リンク、画像
- **画像対応** — ドラッグ＆ドロップやペーストで画像を直接ドキュメントに挿入（`{filename}.assets/` に自動保存）
- **エクスポート** — HTMLまたはPDFとして書き出し

### 全般
- **ネイティブmacOSアプリ** — Swift 6 + SwiftUI + AppKit（TextKit 2）で構築された高速・軽量なアプリ
- **ファイル管理** — macOS標準のファイル操作で `.md` ファイルを開く・編集・保存（自動保存・バージョン管理対応）
- **ダークモード** — macOSのライト・ダーク両方の外観に完全対応（オーバーライド設定あり）
- **サイドバー** — 最近使ったファイルにすばやくアクセス
- **設定** — フォント、フォントサイズ、行間、外観のカスタマイズ

## 動作環境

- macOS 14 (Sonoma) 以降

## インストール

1. **[Releases ページ](https://github.com/yoshidashingo/shoechoo/releases/latest)** から最新版をダウンロード
2. `.zip` または `.dmg` を開き、`shoechoo.app` をアプリケーションフォルダに移動
3. Shoe Choo を起動

> **注意**: このアプリは公証（Notarization）されていません。初回起動時にmacOSによってブロックされます。以下のいずれかの方法で開いてください:
>
> **方法A**（ターミナル）:
> ```
> xattr -cr "/Applications/shoechoo.app"
> ```
> その後、通常通りアプリを起動してください。
>
> **方法B**（システム設定）:
> 1. `shoechoo.app` を開こうとする（ブロックされます）
> 2. **システム設定** → **プライバシーとセキュリティ** を開く
> 3. 下にスクロールしてブロックされたアプリのメッセージを見つけ、**このまま開く** をクリック

## 使い方

1. Shoe Choo を起動すると、新しいエディタウィンドウが開きます
2. Markdownで書き始めると、入力と同時にフォーマットがライブレンダリングされます
3. **⌘N** — 新規ドキュメント作成
4. **⌘O** — 既存のMarkdownファイルを開く
5. **⌘S** — 現在のドキュメントを保存
6. **⇧⌘F** — フォーカスモードの切り替え
7. **⇧⌘E** — HTMLにエクスポート

### キーボードショートカット

| ショートカット | 動作 |
|--------------|------|
| ⌘N | 新規ドキュメント |
| ⌘O | ファイルを開く |
| ⌘S | 保存 |
| ⇧⌘S | 名前を付けて保存 |
| ⌘B | 太字 |
| ⌘I | 斜体 |
| ⌘K | リンク挿入 |
| ⇧⌘K | インラインコード |
| ⌘1〜6 | 見出しレベル設定 |
| ⇧⌘F | フォーカスモード切替 |
| ⇧⌘T | タイプライタースクロール切替 |
| ⇧⌘E | HTMLエクスポート |
| ⇧⌥⌘E | PDFエクスポート |
| ⌃⌘F | フルスクリーン切替 |

## ロードマップ

- [x] macOSアプリ
- [ ] iOS / iPadOSアプリ
- [ ] iCloudによるデバイス間同期

## ソースからビルド

Xcode 16以上と [XcodeGen](https://github.com/yonaskolb/XcodeGen) が必要です。

```bash
git clone https://github.com/yoshidashingo/shoechoo.git
cd shoechoo
brew install xcodegen
xcodegen generate
xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -configuration Release CODE_SIGN_IDENTITY="-" build
```

または `xcodegen generate` を実行後、`shoechoo.xcodeproj` をXcodeで開いて ⌘B でビルドしてください。

## ライセンス

[MIT](LICENSE)
