<h1 align="center">
  <img src="docs/icon.png" alt="shoechoo" width="128">
  <br>
  SHOE CHOO
  <br>
  <br>
</h1>

<p align="center">
  書くことに集中できる、macOS向けのシンプルなマークダウンエディタ。
</p>

<p align="center">
  <a href="https://github.com/yoshidashingo/shoechoo/releases/latest"><img src="https://img.shields.io/github/v/release/yoshidashingo/shoechoo?v=1" alt="release"></a>
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE"><img src="https://img.shields.io/github/license/yoshidashingo/shoechoo?v=1" alt="license"></a>
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
- **シンタックスハイライト** — Markdownの各要素を視覚的にわかりやすく、かつ邪魔にならない繊細なハイライト

### 書くことへの集中
- **フォーカスモード** — 現在の段落以外を薄く表示し、今書いている部分に意識を集中
- **タイプライタースクロール** — アクティブな行を画面中央に保ち、快適な書き心地を実現
- **フルスクリーン** — 没入感のあるフルスクリーン執筆環境

### Markdown
- **フルMarkdownサポート** — 見出し、リスト、テーブル、コードブロック、数式（LaTeX）、脚注など
- **画像対応** — ドラッグ＆ドロップやペーストで画像を直接ドキュメントに挿入
- **エクスポート** — Markdown、HTML、PDFとして保存

### 全般
- **ネイティブmacOSアプリ** — SwiftとSwiftUIで構築された高速・軽量なアプリ
- **ファイル管理** — macOS標準のファイル操作で `.md` ファイルを開く・編集・保存
- **ダークモード** — macOSのライト・ダーク両方の外観に完全対応
- **軽量設計** — 低メモリ使用量で瞬時に起動

## 動作環境

- macOS 14 (Sonoma) 以降

## インストール

1. **[Releases ページ](https://github.com/yoshidashingo/shoechoo/releases/latest)** から最新版をダウンロード
2. `.zip` または `.dmg` を開き、`shoechoo.app` をアプリケーションフォルダに移動
3. shoechooを起動

> **注意**: このアプリは公証（Notarization）されていません。初回起動時にmacOSによってブロックされます。以下のいずれかの方法で開いてください:
>
> **方法A**（ターミナル）:
> ```
> xattr -cr /Applications/shoechoo.app
> ```
> その後、通常通りアプリを起動してください。
>
> **方法B**（システム設定）:
> 1. `shoechoo.app` を開こうとする（ブロックされます）
> 2. **システム設定** → **プライバシーとセキュリティ** を開く
> 3. 下にスクロールしてブロックされたアプリのメッセージを見つけ、**このまま開く** をクリック

## 使い方

1. shoechooを起動すると、新しいエディタウィンドウが開きます
2. Markdownで書き始めると、入力と同時にフォーマットがライブレンダリングされます
3. **⌘N** — 新規ドキュメント作成
4. **⌘O** — 既存のMarkdownファイルを開く
5. **⌘S** — 現在のドキュメントを保存
6. **⌘⇧F** — フォーカスモードの切り替え
7. **⌘⇧E** — HTMLまたはPDFにエクスポート

### キーボードショートカット

| ショートカット | 動作 |
|--------------|------|
| ⌘N | 新規ドキュメント |
| ⌘O | ファイルを開く |
| ⌘S | 保存 |
| ⌘⇧S | 名前を付けて保存 |
| ⌘⇧F | フォーカスモード切替 |
| ⌘⇧E | エクスポート |
| ⌃⌘F | フルスクリーン切替 |

## ロードマップ

- [x] macOSアプリ
- [ ] iOS / iPadOSアプリ
- [ ] iCloudによるデバイス間同期

## ソースからビルド

```bash
git clone https://github.com/yoshidashingo/shoechoo.git
cd shoechoo
xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -configuration Release build
```

または `shoechoo.xcodeproj` をXcodeで開いて ⌘B でビルドしてください。

## ライセンス

MIT
