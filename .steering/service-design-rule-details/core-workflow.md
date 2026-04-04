# Service Design Workflow for AI Agent Services

# PRIORITY: AI-DLCのINCEPTION前にサービスデザインが必要な場合、このワークフローを先に実行する

## Adaptive Workflow Principle
**ワークフローは作業に適応し、逆ではない。**

AIモデルは以下に基づいてどのステージが必要かをインテリジェントに評価する:
1. ユーザーの意図と明確さ
2. 既存の検討状況・資料の有無
3. サービスの複雑性とスコープ
4. ビジネスリスクとインパクト

## MANDATORY: ルール読み込み

**CRITICAL**: 各フェーズ実行時、`.steering/service-design-rule-details/` 配下の該当ルールファイルを必ず読み込むこと。

**共通ルール**: ワークフロー開始時に必ず読み込む:
- `common/process-overview.md` - プロセス全体像
- `common/output-templates.md` - 成果物テンプレート
- AI-DLCの `common/question-format-guide.md` - 質問フォーマット（共用）
- AI-DLCの `common/content-validation.md` - コンテンツバリデーション（共用）

## 4フェーズ構成

```
                     サービスアイデア / ビジネス課題
                              |
                              v
        +=======================================+
        |     DISCOVERY PHASE                   |
        |     発見 - 問題空間の探索             |
        +=======================================+
        | * Goal Setting & Strategy  (ALWAYS)   |
        | * Research & Analysis      (ALWAYS)   |
        +=======================================+
                              |
                              v
        +=======================================+
        |     DEFINITION PHASE                  |
        |     定義 - コンセプトの具体化         |
        +=======================================+
        | * Concept Design           (ALWAYS)   |
        | * Persona & Scenario       (ALWAYS)   |
        | * Ideation & Deep-dive     (COND)     |
        +=======================================+
                              |
                              v
        +=======================================+
        |     VALIDATION PHASE                  |
        |     検証 - 仮説の検証                 |
        +=======================================+
        | * Concept Testing          (COND)     |
        | * Customer Journey & Blueprint (ALWAYS)|
        | * Business Model & KPI     (ALWAYS)   |
        +=======================================+
                              |
                              v
        +=======================================+
        |     PROTOTYPING PHASE                 |
        |     試作 - 技術検証とMVP              |
        +=======================================+
        | * Technical Research       (ALWAYS)   |
        | * MVP & UX Design          (COND)     |
        | * User Testing             (COND)     |
        +=======================================+
                              |
                              v
                    AI-DLC INCEPTION へ接続
```

---

# DISCOVERY PHASE

**Purpose**: ビジネスゴールの設定と問題空間の探索

**Focus**: なぜやるのか、誰のためか、市場はどうか

**Stages**:
- Goal Setting & Strategy (ALWAYS)
- Research & Analysis (ALWAYS)

---

## Goal Setting & Strategy (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザーリクエストを audit.md に記録
2. `.steering/service-design-rule-details/discovery/goal-strategy.md` を読み込み
3. 実行内容:
   - ビジネスゴールの設定
   - Why Now? / Why Us? の整理
   - 中長期計画の策定（半年・1年・2年）
   - 成果物: `aidlc-docs/service-design/discovery/goal-strategy.md`
4. **Wait for Explicit Approval**: 完了メッセージを提示し、ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## Research & Analysis (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/discovery/research-analysis.md` を読み込み
3. 実行内容:
   - PEST分析（Political, Economic, Social, Technological）
   - 競合調査・競合プロダクト分析
   - 市場調査・マーケットリサーチ
   - As-Is ジャーニー（現状の代替手段の整理）
   - 成果物: `aidlc-docs/service-design/discovery/research-analysis.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

---

# DEFINITION PHASE

**Purpose**: コンセプトの具体化とペルソナ設計

**Focus**: 誰の何を解決するのか、どんなサービスか

**Stages**:
- Concept Design (ALWAYS)
- Persona & Scenario (ALWAYS)
- Ideation & Deep-dive (CONDITIONAL)

---

## Concept Design (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/definition/concept-design.md` を読み込み
3. 実行内容:
   - サービスコンセプトの整理（概要、ターゲット、プロダクトビジョン）
   - 価値仮説シートの作成
   - ステークホルダーマップの作成
   - 成果物: `aidlc-docs/service-design/definition/concept-design.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## Persona & Scenario (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/definition/persona-scenario.md` を読み込み
3. 実行内容:
   - ペルソナ設計（属性、状況、課題、ゴール）
   - 6コマシナリオの作成
   - To-Be ジャーニー / シナリオ
   - 成果物: `aidlc-docs/service-design/definition/persona-scenario.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## Ideation & Deep-dive (CONDITIONAL)

**Execute IF**:
- 複数のサービスアプローチが考えられる
- コンセプトに不確実性が高い
- チームでの発散・収束が必要

**Skip IF**:
- コンセプトが明確で合意済み
- 単純なサービス拡張

**Execution**:
1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/definition/ideation.md` を読み込み
3. 実行内容:
   - スプリントクエスチョン（失敗原因、障壁の洗い出し）
   - アイディエーション（発散）
   - アイデアの評価・収束
   - 成果物: `aidlc-docs/service-design/definition/ideation.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

---

# VALIDATION PHASE

**Purpose**: コンセプトとビジネスモデルの検証

**Focus**: このサービスは成立するか、顧客に求められるか

**Stages**:
- Concept Testing (CONDITIONAL)
- Customer Journey & Service Blueprint (ALWAYS)
- Business Model & KPI (ALWAYS)

---

## Concept Testing (CONDITIONAL)

**Execute IF**:
- コンセプトの需要性が未検証
- ピボットの可能性がある
- ターゲット顧客へのアクセスが可能

**Skip IF**:
- 既存顧客からの明確なニーズがある
- 既存サービスの拡張で需要が確認済み

**Execution**:
1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/validation/concept-testing.md` を読み込み
3. 実行内容:
   - 調査計画書の作成（目的、ゴール、手法、対象者）
   - インタビュー設計（半構造化インタビュー）
   - テスト実施・結果分析
   - 課題の洗い出しとコンセプト修正
   - 成果物: `aidlc-docs/service-design/validation/concept-testing.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## Customer Journey & Service Blueprint (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/validation/customer-journey.md` を読み込み
3. 実行内容:
   - カスタマージャーニーマップ（CJM）の作成
   - サービスブループリントの作成
     - カスタマーアクション
     - フロントステージアクション（顧客接点）
     - バックステージアクション（裏方業務）
     - プロセス（内部システム）
     - 規制と指針
     - 指標（KPI）
   - 課題定義と取り組む課題の決定
   - 成果物: `aidlc-docs/service-design/validation/customer-journey.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## Business Model & KPI (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/validation/business-model.md` を読み込み
3. 実行内容:
   - ビジネスモデルの設計
   - マネタイズプランの策定
   - KGI/KPI設定
   - コスト構造の分析
   - 収支計画表の作成
   - 成果物: `aidlc-docs/service-design/validation/business-model.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

---

# PROTOTYPING PHASE

**Purpose**: 技術検証とMVP構築

**Focus**: 実現可能か、ユーザーに受け入れられるか

**Stages**:
- Technical Research (ALWAYS)
- MVP & UX Design (CONDITIONAL)
- User Testing (CONDITIONAL)

---

## Technical Research (ALWAYS EXECUTE)

1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/prototyping/technical-research.md` を読み込み
3. 実行内容:
   - 技術スタック・フレームワークの選定
   - AIエージェントアーキテクチャの設計
   - インフラ構成の検討
   - 追加の技術習得の必要性評価
   - 成果物: `aidlc-docs/service-design/prototyping/technical-research.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## MVP & UX Design (CONDITIONAL)

**Execute IF**:
- プロダクト/プラットフォーム型サービスの場合
- UI/UXが差別化要因になる場合

**Skip IF**:
- コンサルティング/アドバイザリー型サービスの場合
- UIが不要または既存ツール活用の場合

**Execution**:
1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/prototyping/mvp-ux-design.md` を読み込み
3. 実行内容:
   - ユーザーストーリーマップの作成
   - MVP定義
   - 情報設計・UIフロー図
   - ワイヤーフレーム・プロトタイプ
   - 成果物: `aidlc-docs/service-design/prototyping/mvp-ux-design.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

## User Testing (CONDITIONAL)

**Execute IF**:
- MVP & UX Design を実施した場合
- プロトタイプが動作可能な状態の場合

**Skip IF**:
- MVP & UX Design をスキップした場合
- プロトタイプが未完成の場合

**Execution**:
1. **MANDATORY**: ユーザー入力を audit.md に記録
2. `.steering/service-design-rule-details/prototyping/user-testing.md` を読み込み
3. 実行内容:
   - ユーザーテスト計画の作成
   - 認知的ウォークスルー
   - テスト実施・結果分析
   - 改善点の洗い出し
   - 成果物: `aidlc-docs/service-design/prototyping/user-testing.md`
4. **Wait for Explicit Approval**: ユーザー承認を待つ
5. **MANDATORY**: ユーザーの回答を audit.md に記録

---

# AI-DLC への接続

**PROTOTYPING PHASE 完了後**:
- サービスデザインの成果物を AI-DLC INCEPTION PHASE の入力として使用
- Requirements Analysis では、サービスデザインで確定した要件を基にシステム要件を定義
- サービスデザインの成果物パス: `aidlc-docs/service-design/`
- AI-DLC成果物パス: `aidlc-docs/inception/`, `aidlc-docs/construction/`

---

## Key Principles

- **Double Diamond**: 発散→収束を2回繰り返す（Discovery→Definition, Validation→Prototyping）
- **Adaptive Execution**: 付加価値のあるステージのみ実行
- **Transparent Planning**: 実行前に計画を提示
- **User Control**: ユーザーがステージの追加・除外を指示可能
- **Progress Tracking**: aidlc-state.md で進捗を管理
- **Complete Audit Trail**: すべてのユーザー入力とAI応答を audit.md に記録
- **AI-DLC互換**: 質問フォーマット、コンテンツバリデーション、監査ログはAI-DLCルールを共用

## MANDATORY: 承認メッセージフォーマット

各ステージ完了時、以下のフォーマットで承認を求める:

```markdown
> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/{phase}/{filename}`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Approve & Continue** - 承認して次のステージ **[次ステージ名]** へ進む
```

## Directory Structure

```text
aidlc-docs/
  service-design/
    discovery/
      goal-strategy.md
      research-analysis.md
    definition/
      concept-design.md
      persona-scenario.md
      ideation.md
    validation/
      concept-testing.md
      customer-journey.md
      business-model.md
    prototyping/
      technical-research.md
      mvp-ux-design.md
      user-testing.md
  inception/                  # AI-DLC INCEPTION（サービスデザイン後）
  construction/               # AI-DLC CONSTRUCTION
  operations/                 # AI-DLC OPERATIONS
  aidlc-state.md
  audit.md
```
