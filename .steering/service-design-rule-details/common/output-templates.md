# Output Templates

**Purpose**: 各ステージの成果物のテンプレートを定義する。

## 共通ルール

- 成果物はすべてMarkdown形式で `aidlc-docs/service-design/{phase}/` に出力
- テーブル形式を積極的に使用し、情報を構造化する
- 各成果物の冒頭に「概要」セクションを設ける
- AI-DLC の content-validation.md に従ってコンテンツを検証する

## ステージ別成果物一覧

| フェーズ | ステージ | 成果物ファイル |
|---------|---------|--------------|
| Discovery | Goal Setting & Strategy | `discovery/goal-strategy.md` |
| Discovery | Research & Analysis | `discovery/research-analysis.md` |
| Definition | Concept Design | `definition/concept-design.md` |
| Definition | Persona & Scenario | `definition/persona-scenario.md` |
| Definition | Ideation & Deep-dive | `definition/ideation.md` |
| Validation | Concept Testing | `validation/concept-testing.md` |
| Validation | Customer Journey & Blueprint | `validation/customer-journey.md` |
| Validation | Business Model & KPI | `validation/business-model.md` |
| Prototyping | Technical Research | `prototyping/technical-research.md` |
| Prototyping | MVP & UX Design | `prototyping/mvp-ux-design.md` |
| Prototyping | User Testing | `prototyping/user-testing.md` |

## テンプレート: Goal Setting & Strategy

```markdown
# Goal Setting & Strategy

## 概要
[1-2文でサービスの方向性を記述]

## ビジネスゴール
- [ゴール1]
- [ゴール2]

## Why Now? - なぜ今やるのか
[市場環境、技術成熟度、競合状況等]

## Why Us? - なぜこの会社がやるのか
[自社の強み、アセット、ポジショニング]

## 中長期計画

| 時期 | プロダクト/サービスの変化 | 市場/社会の変化 |
|------|----------------------|---------------|
| 半年後 | | |
| 1年後 | | |
| 2年後 | | |
```

## テンプレート: Concept Design

```markdown
# Concept Design

## 概要

| 項目 | 内容 |
|------|------|
| メインの国/地域 | |
| 法人/コンシューマー | |
| ターゲットセグメント | |
| プロダクト/サービス概要 | |

## プロダクトビジョン
> [ビジョンステートメント]

## 価値仮説シート
**[ターゲット]** は、
**[状況/ニーズ]** が、
**[課題/障壁]** ので、
**[提供価値]** ことに価値がある。

## ステークホルダーマップ
[関係者とその関係性]
```

## テンプレート: Persona & Scenario

```markdown
# Persona & Scenario

## ペルソナ

| 項目 | 内容 |
|------|------|
| 名前 | |
| 年齢 | |
| 職業/役職 | |
| 所属 | |
| 状況 | |
| 課題 | |
| ゴール | |

## 6コマシナリオ
**[ペルソナ名]** は、
**[課題/状況]** が、
**[サービス名]** を使うことで
**[解決/変化]** となった。

## To-Be ジャーニー
[理想的な体験の流れ]
```

## テンプレート: Customer Journey & Service Blueprint

```markdown
# Customer Journey & Service Blueprint

## カスタマージャーニーマップ

| ステップ | [Step1] | [Step2] | [Step3] | ... |
|---------|---------|---------|---------|-----|
| User Actions | | | | |
| Goals & Experiences | | | | |
| Feelings & Thoughts | | | | |
| Pain Points | | | | |
| Opportunities | | | | |

## サービスブループリント

| レイヤー | [Step1] | [Step2] | [Step3] | ... |
|---------|---------|---------|---------|-----|
| カスタマーアクション | | | | |
| フロントステージアクション | | | | |
| ---顧客接点ライン--- | | | | |
| バックステージアクション | | | | |
| ---可視ライン--- | | | | |
| プロセス（内部システム） | | | | |
| 規制と指針 | | | | |
| 指標 | | | | |
```

## テンプレート: Business Model & KPI

```markdown
# Business Model & KPI

## ビジネスモデル
[ビジネスモデルの説明]

## マネタイズプラン

| プラン | 価格 | 提供内容 | ターゲット |
|--------|------|---------|-----------|
| | | | |

## KPI設定

| 指標種別 | 指標名 | 目標値 | 計測方法 |
|---------|--------|--------|---------|
| KGI | | | |
| KPI | | | |

## コスト構造
[主要コスト項目]

## 収支計画表

| 項目 | Month 1 | Month 3 | Month 6 | Year 1 |
|------|---------|---------|---------|--------|
| 売上 | | | | |
| コスト | | | | |
| 利益 | | | | |
```
