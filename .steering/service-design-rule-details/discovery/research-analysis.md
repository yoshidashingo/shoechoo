# Research & Analysis

**Assume the role** of a market researcher / business analyst

**Always executes.** ゴール・戦略を踏まえ、市場・競合・技術環境を調査する。

## Prerequisites
- Goal Setting & Strategy が完了していること
- `aidlc-docs/service-design/discovery/goal-strategy.md` を読み込むこと

## Execution Steps

### Step 1: PEST分析

外部環境を4つの観点で分析する:

| 観点 | 分析内容 |
|------|---------|
| **P**olitical（政治・法規制） | 関連法規制、政策動向、業界ガイドライン |
| **E**conomic（経済） | 市場規模、成長率、景気動向、為替影響 |
| **S**ocial（社会） | 人口動態、働き方の変化、技術リテラシー |
| **T**echnological（技術） | 技術トレンド、イノベーション、成熟度 |

### Step 2: 競合調査

#### 2.1 直接競合
同じ課題を同じ手法で解決するサービス:
- サービス名、提供企業
- 価格体系
- 強み・弱み
- ターゲット顧客

#### 2.2 間接競合
同じ課題を異なる手法で解決するサービス:
- 代替手段の一覧
- 顧客が現在使っている解決策

#### 2.3 競合プロダクト分析
主要競合について深掘り:
- 機能比較マトリクス
- 価格比較
- ポジショニングマップ

### Step 3: 市場調査

- **TAM**（Total Addressable Market）: 潜在市場全体
- **SAM**（Serviceable Addressable Market）: 自社がアプローチ可能な市場
- **SOM**（Serviceable Obtainable Market）: 現実的に獲得可能な市場

### Step 4: As-Is ジャーニー

顧客が**現在**どのように課題を解決しているか:

| ステップ | 現状の行動 | 使用ツール/手段 | 課題・Pain Point |
|---------|-----------|---------------|----------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

### Step 5: インサイトの整理

調査結果から得られた知見:
- **機会**: 市場ギャップ、未充足ニーズ
- **脅威**: 競合の強み、参入障壁
- **示唆**: サービス設計への影響

### Step 6: 質問ファイルの生成

追加情報が必要な場合:
1. `aidlc-docs/service-design/discovery/research-questions.md` を作成
2. AI-DLCの質問フォーマットに従う
3. ユーザーの回答を待つ

### Step 7: 成果物の作成

`aidlc-docs/service-design/discovery/research-analysis.md` を作成:
- PEST分析結果
- 競合調査結果
- 市場調査結果
- As-Isジャーニー
- インサイトサマリ

### Step 8: 完了メッセージ

```markdown
# Research & Analysis Complete

市場・競合調査が完了しました:
- [主要な発見を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/discovery/research-analysis.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Approve & Continue** - 承認して **DEFINITION PHASE** へ進む
```
