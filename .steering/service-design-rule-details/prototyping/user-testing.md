# User Testing

**Assume the role** of a UX researcher

**Conditional execution.** MVP & UX Design を実施し、プロトタイプが利用可能な場合に実施。

## Prerequisites
- MVP & UX Design が完了していること
- プロトタイプが動作可能な状態であること
- 以下を読み込むこと:
  - `aidlc-docs/service-design/definition/persona-scenario.md`
  - `aidlc-docs/service-design/prototyping/mvp-ux-design.md`

## Execute IF
- MVP & UX Design を実施した場合
- プロトタイプが動作可能な状態の場合
- ユーザーが明示的にテスト計画を要求

## Skip IF
- MVP & UX Design をスキップした場合
- プロトタイプが未完成の場合

## Execution Steps

### Step 1: テスト計画の作成

| 項目 | 内容 |
|------|------|
| 目的 | プロトタイプのユーザビリティ検証 |
| 手法 | ユーザーテスト / 認知的ウォークスルー / A-Bテスト |
| 対象者 | ペルソナに合致する [N] 名 |
| テスト環境 | オンライン / 対面 |
| 所要時間 | 1セッション [N] 分 |
| 計測指標 | タスク完了率、エラー率、SUS（System Usability Scale） |

### Step 2: テストシナリオの作成

| # | タスク | 前提条件 | 成功基準 | 計測ポイント |
|---|--------|---------|---------|------------|
| 1 | [具体的な操作タスク] | | | |

### Step 3: 認知的ウォークスルー

プロトタイプの各ステップについて以下を評価:

| ステップ | ユーザーの目標 | 正しい操作 | ユーザーは気づくか | フィードバックは適切か |
|---------|-------------|-----------|-----------------|-------------------|
| 1 | | | Yes/No | Yes/No |

### Step 4: テスト結果の分析

#### 4.1 定量結果

| 指標 | 結果 | 目標値 | 達成 |
|------|------|--------|------|
| タスク完了率 | | | |
| エラー率 | | | |
| SUSスコア | | | |

#### 4.2 定性結果

| # | 発見事項 | 深刻度 | 影響画面 | 改善案 |
|---|---------|--------|---------|--------|
| 1 | | Critical/Major/Minor | | |

### Step 5: 改善提案

| 優先度 | 改善項目 | 現状 | 改善後 | 工数 |
|--------|---------|------|--------|------|
| P1 | | | | |

### Step 6: 成果物の作成

`aidlc-docs/service-design/prototyping/user-testing.md` を作成:
- テスト計画
- テストシナリオ
- 認知的ウォークスルー結果
- テスト結果（定量・定性）
- 改善提案

### Step 7: 完了メッセージ

```markdown
# User Testing Complete

ユーザーテストが完了しました:
- [主要な発見と改善提案を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/prototyping/user-testing.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Iterate** - プロトタイプを修正して再テスト
> **Approve & Continue** - 承認して **AI-DLC INCEPTION** へ接続
```
