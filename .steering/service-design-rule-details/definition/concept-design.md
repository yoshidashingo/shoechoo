# Concept Design

**Assume the role** of a service designer / product strategist

**Always executes.** 調査結果を踏まえ、サービスコンセプトを具体化する。

## Prerequisites
- Discovery Phase が完了していること
- `aidlc-docs/service-design/discovery/goal-strategy.md` を読み込むこと
- `aidlc-docs/service-design/discovery/research-analysis.md` を読み込むこと

## Execution Steps

### Step 1: サービスコンセプトの整理

以下の項目を構造化する:

| 項目 | 内容 |
|------|------|
| メインの国/地域 | |
| 法人/コンシューマー | |
| ターゲットセグメント | |
| プロダクト/サービス概要 | |
| 発足の背景 | |

### Step 2: プロダクト/サービスビジョン

一文でサービスが目指す世界観を表現する:
- **フォーマット**: 「[動詞]して[状態]を実現する」
- 顧客にとっての理想的な状態を描く
- 事業側のゴールではなく、社会/顧客視点で記述

### Step 3: 価値仮説シートの作成

以下のフォーマットで価値仮説を明文化する:

```
**[ターゲット顧客の特徴]** は、
**[状況・ニーズ]** が、
**[課題・障壁]** ので、
**[サービスが提供する価値・体験]** ことに価値がある。
```

**検証ポイント**:
- ターゲットは具体的か（「企業」ではなく「開発チームを持つ中堅IT企業」）
- 課題は実在するか（調査結果に裏付けがあるか）
- 提供価値はユニークか（競合との差別化があるか）

### Step 4: ステークホルダーマップ

サービスに関わる関係者を整理する:

- **コアステークホルダー**: サービスの直接的な利用者・提供者
- **サポートステークホルダー**: サービス運営を支える関係者
- **外部ステークホルダー**: 間接的に影響を与える/受ける関係者

各ステークホルダーについて:
- 役割
- サービスとの接点
- 期待する価値
- 懸念事項

### Step 5: コンセプトの差別化ポイント

競合調査結果を踏まえ、以下を明確にする:
- **Must Have**: 競合と同等に提供すべき機能・価値
- **Differentiator**: 自社ならではの差別化要素
- **WOW Factor**: 顧客の期待を超える価値

### Step 6: 質問ファイルの生成

コンセプトの不明点がある場合:
1. `aidlc-docs/service-design/definition/concept-questions.md` を作成
2. AI-DLCの質問フォーマットに従う
3. ユーザーの回答を待つ

### Step 7: 成果物の作成

`aidlc-docs/service-design/definition/concept-design.md` を作成:
- `common/output-templates.md` のテンプレートに従う

### Step 8: 完了メッセージ

```markdown
# Concept Design Complete

サービスコンセプトの整理が完了しました:
- [主要なコンセプト要素を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/definition/concept-design.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Approve & Continue** - 承認して **Persona & Scenario** へ進む
```
