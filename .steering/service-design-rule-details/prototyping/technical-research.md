# Technical Research

**Assume the role** of a technical architect / AI engineer

**Always executes.** サービス実現のための技術スタックとアーキテクチャを調査・選定する。

## Prerequisites
- Validation Phase が完了していること
- 以下を読み込むこと:
  - `aidlc-docs/service-design/definition/concept-design.md`
  - `aidlc-docs/service-design/validation/customer-journey.md`（サービスブループリント）
  - `aidlc-docs/service-design/validation/business-model.md`

## Execution Steps

### Step 1: 技術要件の抽出

サービスブループリントの「プロセス」レイヤーから技術要件を抽出:

| # | 要件 | 種別 | 優先度 |
|---|------|------|--------|
| 1 | | 機能/性能/セキュリティ/統合 | P1/P2/P3 |

### Step 2: AIエージェントアーキテクチャの設計

#### 2.1 エージェント類型の選定

| 類型 | 適用場面 | 複雑性 |
|------|---------|--------|
| **チャットボット型** | Q&A、情報検索 | 低 |
| **ワークフロー型** | 定型業務の自動化 | 中 |
| **自律型** | 複雑なタスクの自律遂行 | 高 |
| **マルチエージェント型** | 複数エージェントの協調 | 最高 |

#### 2.2 エージェント構成

| エージェント名 | 役割 | 類型 | 使用ツール |
|-------------|------|------|-----------|
| | | | |

#### 2.3 データソース・外部連携

| 連携先 | 連携方式 | 用途 |
|--------|---------|------|
| | API/MCP/DB/ファイル | |

### Step 3: 技術スタック選定

| カテゴリ | 候補 | 選定 | 選定理由 |
|---------|------|------|---------|
| LLM | GPT-4o / Claude / Gemini | | |
| フレームワーク | LangChain / LangGraph / CrewAI | | |
| 開発ツール | Claude Code / Cursor / GitHub Copilot | | |
| インフラ | AWS / GCP / Azure | | |
| データベース | PostgreSQL / DynamoDB / Pinecone | | |
| フロントエンド | Next.js / Streamlit / Gradio | | |
| 認証 | Cognito / Auth0 / Clerk | | |
| CI/CD | GitHub Actions / AWS CodePipeline | | |

### Step 4: セキュリティ・ガバナンス要件

| 項目 | 要件 | 対策 |
|------|------|------|
| データ保護 | | |
| 認証・認可 | | |
| ログ・監査 | | |
| コンプライアンス | | |
| LLM安全性 | ハルシネーション対策、PII保護 | |

### Step 5: 技術習得の必要性評価

| 技術/ツール | チームの現在のスキルレベル | 必要なスキルレベル | ギャップ | 学習方法 |
|------------|----------------------|------------------|---------|---------|
| | 高/中/低/なし | 高/中/低 | | |

### Step 6: 成果物の作成

`aidlc-docs/service-design/prototyping/technical-research.md` を作成:
- 技術要件一覧
- AIエージェントアーキテクチャ
- 技術スタック選定結果
- セキュリティ・ガバナンス要件
- 技術習得計画

### Step 7: 完了メッセージ

```markdown
# Technical Research Complete

技術調査が完了しました:
- [主要な技術選定と発見を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/prototyping/technical-research.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Add MVP & UX Design** - MVP・UXデザインステージを追加
> **Approve & Continue** - 承認して **AI-DLC INCEPTION** へ接続
```
