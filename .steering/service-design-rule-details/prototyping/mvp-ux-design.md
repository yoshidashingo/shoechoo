# MVP & UX Design

**Assume the role** of a product designer / UX designer

**Conditional execution.** プロダクト/プラットフォーム型サービスで、UI/UXが差別化要因となる場合に実施。

## Prerequisites
- Technical Research が完了していること
- 以下を読み込むこと:
  - `aidlc-docs/service-design/definition/persona-scenario.md`
  - `aidlc-docs/service-design/validation/customer-journey.md`
  - `aidlc-docs/service-design/prototyping/technical-research.md`

## Execute IF
- プロダクト/プラットフォーム型サービスの場合
- UI/UXが差別化要因になる場合
- ユーザーが明示的にMVP設計を要求

## Skip IF
- コンサルティング/アドバイザリー型サービスの場合
- UIが不要または既存ツール活用の場合

## Execution Steps

### Step 1: ユーザーストーリーマップの作成

ペルソナの活動を軸にストーリーを整理:

```
活動:    [活動1]        [活動2]        [活動3]
         |              |              |
タスク:  [タスク1-1]    [タスク2-1]    [タスク3-1]
         [タスク1-2]    [タスク2-2]    [タスク3-2]
         [タスク1-3]    [タスク2-3]    [タスク3-3]
         --------MVP ライン--------
         [タスク1-4]    [タスク2-4]
```

### Step 2: MVP定義

#### 2.1 MVPに含める機能

| # | 機能 | 理由 | 優先度 |
|---|------|------|--------|
| 1 | | | Must |
| 2 | | | Must |
| 3 | | | Should |

#### 2.2 MVPに含めない機能（バックログ）

| # | 機能 | 理由 | 予定リリース |
|---|------|------|------------|
| 1 | | | v2 |

#### 2.3 MVPの成功基準

| 指標 | 目標値 | 計測方法 |
|------|--------|---------|
| | | |

### Step 3: 情報設計

#### 3.1 情報アーキテクチャ（IA）
- サイトマップ / ナビゲーション構造
- コンテンツの分類・階層

#### 3.2 UIフロー図 / 画面遷移図
- 主要なユーザーフローを図示
- 各画面の目的と遷移条件

### Step 4: ワイヤーフレーム

主要画面のワイヤーフレームを作成:
- ダッシュボード / ホーム
- 主要機能画面（2-3画面）
- 設定 / プロフィール

**注意**: ASCII図またはテキスト記述で表現。高忠実度モックアップはスコープ外。

### Step 5: プロトタイプ定義

プロトタイプの仕様を定義:
- **種別**: ペーパープロト / クリッカブルプロト / 動作プロト
- **ツール**: Figma / HTML / Streamlit / etc.
- **スコープ**: 検証するユーザーフロー
- **期間**: 作成に必要な期間

### Step 6: 成果物の作成

`aidlc-docs/service-design/prototyping/mvp-ux-design.md` を作成:
- ユーザーストーリーマップ
- MVP定義（含む/含まない機能）
- 情報設計
- ワイヤーフレーム
- プロトタイプ仕様

### Step 7: 完了メッセージ

```markdown
# MVP & UX Design Complete

MVP・UXデザインが完了しました:
- [主要な設計決定を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/prototyping/mvp-ux-design.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Add User Testing** - ユーザーテスト計画を追加
> **Approve & Continue** - 承認して **AI-DLC INCEPTION** へ接続
```
