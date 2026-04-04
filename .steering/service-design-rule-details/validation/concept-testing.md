# Concept Testing

**Assume the role** of a UX researcher

**Conditional execution.** コンセプトの需要性が未検証の場合、またはピボットの判断が必要な場合に実施。

## Prerequisites
- Definition Phase が完了していること
- 以下を読み込むこと:
  - `aidlc-docs/service-design/definition/concept-design.md`
  - `aidlc-docs/service-design/definition/persona-scenario.md`
  - `aidlc-docs/service-design/definition/ideation.md`（実施した場合）

## Execute IF
- コンセプトの需要性が未検証
- ピボットの可能性がある
- ターゲット顧客へのアクセスが可能
- ユーザーが明示的にコンセプトテストを要求

## Skip IF
- 既存顧客からの明確なニーズが確認済み
- 既存サービスの拡張で需要が自明
- テスト実施のリソース/時間がない（ユーザー判断）

## Execution Steps

### Step 1: 調査計画書の作成

| 項目 | 内容 |
|------|------|
| 目的 | コンセプトの需要性を検証し、開発の手戻りを防ぐ |
| ゴール | コンセプトの方向性確定 / ピボット判断 |
| 調査種別 | 定性調査 / 定量調査 / 混合 |
| 手法 | 半構造化インタビュー / アンケート / プロトタイプテスト |
| 形式 | オンライン / オフライン |
| 対象者 | 各セグメント [N] 名 |
| 期間 | [期間] |

### Step 2: インタビュー設計

#### 2.1 インタビューガイド

**導入部（5分）**:
- 自己紹介、目的説明
- 同意取得（録音等）

**現状把握（10分）**:
- 現在の業務/課題について
- 現在使っているツール/サービスについて
- 不満点・改善要望

**コンセプト提示（15分）**:
- コンセプトの説明
- 第一印象の確認
- 価値の感じ方
- 利用意向

**深掘り（15分）**:
- 具体的な利用シーンの想定
- 価格感
- 懸念事項
- 改善提案

**クロージング（5分）**:
- その他のコメント
- フォローアップの可否

#### 2.2 検証すべき仮説

| # | 仮説 | 検証方法 | 成功基準 |
|---|------|---------|---------|
| 1 | | | |

### Step 3: テスト結果の分析

#### 3.1 定性分析
- 発言の分類・コーディング
- パターンの抽出
- インサイトの導出

#### 3.2 判定

| 判定 | 基準 |
|------|------|
| **Go** | 主要仮説が検証され、需要が確認できた |
| **Pivot** | 方向修正が必要（具体的な修正点を明記） |
| **Kill** | 需要が見込めず、撤退を推奨 |

### Step 4: 成果物の作成

`aidlc-docs/service-design/validation/concept-testing.md` を作成:
- 調査計画書
- インタビューガイド
- テスト結果サマリ
- 判定と根拠
- コンセプト修正案（Pivotの場合）

### Step 5: 完了メッセージ

```markdown
# Concept Testing Complete

コンセプトテストが完了しました:
- [主要な発見と判定結果を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/validation/concept-testing.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Approve & Continue** - 承認して **Customer Journey & Service Blueprint** へ進む
```
