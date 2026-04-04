# インストール済みプラグイン比較表

**作成日**: 2026-04-04
**Claude Code バージョン**: 2.1.92
**対象プロジェクト**: ekocci (エコちっち — Apple Watch たまごっちクローン)

---

## インストール済みプラグイン一覧

| # | プラグイン | マーケットプレイス | バージョン | インストール日 |
|---|-----------|-------------------|-----------|---------------|
| 1 | **Superpowers** | claude-plugins-official | 5.0.7 | 2026-04-01 |
| 2 | **Everything Claude Code (ECC)** | everything-claude-code | 1.9.0 | 2026-04-01 |
| 3 | **Oh My ClaudeCode (OMC)** | omc | 4.10.1 | 2026-04-04 |
| 4 | **Ralph Loop** | claude-plugins-official | 1.0.0 | 2026-04-01 |
| 5 | **Frontend Design** | claude-plugins-official | unknown | 2026-04-01 |
| 6 | **Slack** | claude-plugins-official | 1.0.0 | 2026-04-01 |
| 7 | **Circleback** | claude-plugins-official | 1.0.0 | 2026-04-01 |
| 8 | **Deploy on AWS** | agent-plugins-for-aws | 1.1.0 | 2026-02-24 |
| 9 | **AWS Amplify** | agent-plugins-for-aws | 1.0.0 | 2026-04-01 |
| 10 | **AWS Serverless** | agent-plugins-for-aws | 1.0.0 | 2026-04-01 |
| 11 | **Codex** | openai-codex | 1.0.2 | 2026-04-01 |

---

## カテゴリ別プラグイン比較

### 1. 開発ワークフロー・ライフサイクル

| 機能 | Superpowers | ECC | OMC | Ralph Loop |
|------|:-----------:|:---:|:---:|:----------:|
| 計画・設計 | writing-plans, brainstorming | planner, architect | plan, ralplan, autopilot | - |
| TDD | test-driven-development | tdd-guide (agent) | - | - |
| 実装実行 | executing-plans, subagent-driven-development | 各種build-resolver | autopilot, ultrawork | ralph-loop |
| コードレビュー | requesting/receiving-code-review | code-reviewer + 言語別reviewer×10 | code-reviewer, critic | - |
| デバッグ | systematic-debugging | build-error-resolver | debug, tracer | - |
| 検証・完了 | verification-before-completion | verification-loop | verify, ultraqa | - |
| Git/ブランチ | finishing-a-development-branch, using-git-worktrees | git-workflow | git-master (agent) | - |
| **スキル数** | **14** | **147 skills + 36 agents** | **37 skills + 19 agents** | **3 commands** |

### 2. 言語・フレームワーク専門レビュー

| 対象 | ECC (agents) | ECC (skills) | OMC |
|------|:------------:|:------------:|:---:|
| TypeScript/JS | typescript-reviewer | TS patterns, frontend-patterns | - |
| Python | python-reviewer | python-patterns, python-testing | - |
| Swift/SwiftUI | - | swiftui-patterns, swift-concurrency-6-2, swift-actor-persistence, swift-protocol-di-testing, foundation-models-on-device, liquid-glass-design | - |
| Go | go-reviewer, go-build-resolver | golang-patterns, golang-testing | - |
| Rust | rust-reviewer, rust-build-resolver | rust-patterns, rust-testing | - |
| Kotlin | kotlin-reviewer, kotlin-build-resolver | kotlin-patterns, kotlin-testing, kotlin-coroutines-flows, compose-multiplatform-patterns | - |
| Java | java-reviewer, java-build-resolver | java-coding-standards, jpa-patterns, springboot-* | - |
| C++ | cpp-reviewer, cpp-build-resolver | cpp-coding-standards, cpp-testing | - |
| Flutter/Dart | flutter-reviewer | dart-flutter-patterns | - |
| PostgreSQL | database-reviewer | postgres-patterns, database-migrations | - |
| Laravel/PHP | - | laravel-patterns, laravel-security, laravel-tdd | - |
| Django | - | django-patterns, django-security, django-tdd | - |

### 3. AWS・インフラ

| 機能 | Deploy on AWS | AWS Amplify | AWS Serverless |
|------|:------------:|:-----------:|:--------------:|
| IaCテンプレート検証 | validate_cloudformation_template | - | - |
| コンプライアンスチェック | check_cloudformation_template_compliance | - | - |
| CDKドキュメント検索 | search_cdk_documentation, search_cdk_samples | - | - |
| CloudFormationトラブルシュート | troubleshoot_cloudformation_deployment | - | - |
| 料金見積もり | get_pricing, generate_cost_report, analyze_cdk_project | - | - |
| Amplifyワークフロー | - | amplify-workflow | - |
| Lambda設計・デプロイ | - | - | aws-lambda, aws-serverless-deployment |
| API Gateway | - | - | api-gateway |
| SAM CLI連携 | - | - | sam_init, sam_build, sam_deploy, sam_local_invoke |
| ESM（Kafka/Kinesis/DynamoDB Streams） | - | - | esm_guidance, esm_optimize |
| **MCP tools数** | **~12** | **~2** | **~20+** |

### 4. コミュニケーション・外部連携

| 機能 | Slack | Circleback | freee MCP |
|------|:-----:|:----------:|:---------:|
| 種別 | Plugin | Plugin (MCP) | MCP Server |
| メッセージ検索 | slack-search | SearchMeetings, SearchEmails, SearchTranscripts | - |
| チャンネルサマリ | summarize-channel, channel-digest | - | - |
| スタンドアップ | standup | - | - |
| アナウンス作成 | draft-announcement | - | - |
| ミーティング管理 | - | ReadMeetings, GetTranscriptsForMeetings | - |
| カレンダー | - | SearchCalendarEvents | - |
| 会計API | - | - | freee_api_get/post/put/patch/delete |
| 人事労務 | - | - | freee API経由 |

### 5. AI/マルチモデル連携

| 機能 | Codex | ECC | OMC |
|------|:-----:|:---:|:---:|
| 外部モデル連携 | OpenAI Codex CLI (GPT-5.4) | - | - |
| セカンドオピニオン | codex-rescue | - | sciomc |
| プロンプト最適化 | gpt-5-4-prompting | prompt-optimizer | - |
| マルチエージェント | - | gan-style-harness, dmux-workflows, autonomous-loops | omc-teams |

### 6. その他特化機能

| 機能 | プラグイン | 説明 |
|------|-----------|------|
| UI/フロントエンド設計 | **Frontend Design** | Figma連携、プロダクショングレードUI生成 |
| Figmaデザイン読込 | **Figma MCP** (組み込み) | デザインからコード変換、Code Connect |
| Google Calendar | **Google Calendar MCP** (組み込み) | イベント管理、空き時間検索 |
| Gmail | **Gmail MCP** (組み込み) | メール検索、下書き作成 |
| Notion | **Notion MCP** (組み込み) | ページ作成・検索・更新 |
| セキュリティスキャン | **ECC** | security-scan, security-review |
| ドキュメント生成 | **ECC** | doc-updater, article-writing |
| オープンソース化 | **ECC** | opensource-forker → opensource-sanitizer → opensource-packager |
| ヘルスケア | **ECC** | healthcare-reviewer, healthcare-cdss-patterns |
| 動画生成 | **ECC** | remotion-video-creation, video-editing, fal-ai-media |

---

## ekocci プロジェクトへの適合度

Apple Watch たまごっちクローン（Swift/SwiftUI + watchOS）の開発に対する各プラグインの有用性:

| プラグイン | 適合度 | 理由 |
|-----------|:------:|------|
| **Superpowers** | ★★★ | worktree隔離、計画→実装→レビューの一貫ワークフロー。watchOS開発の段階的進行に最適 |
| **ECC** | ★★★ | Swift/SwiftUI スキル群（swiftui-patterns, swift-concurrency-6-2, swift-actor-persistence, foundation-models-on-device, liquid-glass-design）が watchOS 開発に直結。TDDガイド・コードレビューも活用 |
| **OMC** | ★★☆ | autopilot/ralph による自律実装、deep-interview による要件深掘りが有用。ただし Swift 専門レビューはない |
| **Ralph Loop** | ★★☆ | 単一の難しいタスク（watchOS固有のUI実装等）の確実な完遂に有効 |
| **Frontend Design** | ★★☆ | Web UIではないがデザインシステム構築のアプローチは参考になる |
| **Codex** | ★★☆ | セカンドオピニオン・別視点での実装支援 |
| **Deploy on AWS** | ★☆☆ | バックエンドAPI構築時に有用だが、初期フェーズでは不要 |
| **AWS Amplify** | ★☆☆ | 同上 |
| **AWS Serverless** | ★☆☆ | 同上 |
| **Slack** | ★☆☆ | 開発コミュニケーション支援。直接の開発貢献は限定的 |
| **Circleback** | ★☆☆ | ミーティング管理。チーム開発時に有用 |
| **freee MCP** | ☆☆☆ | 会計API。ekocci開発には直接関係なし |

---

## 機能重複マトリクス

同等機能を提供するプラグイン間の重複:

| 機能領域 | 競合するプラグイン | 推奨 |
|----------|-------------------|------|
| 計画策定 | Superpowers (writing-plans) vs ECC (planner) vs OMC (plan, ralplan) | **Superpowers** — レビューチェックポイント付き |
| コードレビュー | Superpowers (code-reviewer) vs ECC (code-reviewer + 言語別) vs OMC (code-reviewer, critic) | **ECC** — 言語別専門レビュー。Phase完了時は **Superpowers** |
| TDD | Superpowers (test-driven-development) vs ECC (tdd-guide, tdd-workflow) | **ECC** — tdd-guide agent が自律的 |
| 自律ループ | Ralph Loop (ralph-loop) vs OMC (ralph, autopilot, ultrawork) vs ECC (autonomous-loops, continuous-agent-loop) | タスク難度で使い分け: 単純→**OMC:autopilot**, 複雑→**Ralph Loop** |
| デバッグ | Superpowers (systematic-debugging) vs ECC (build-error-resolver) vs OMC (debug, tracer) | **Superpowers** — 体系的アプローチ。ビルドエラーのみ→**ECC** |
| セキュリティ | ECC (security-reviewer, security-scan) vs OMC (security-reviewer) | **ECC** — スキャン機能含む |

---

## 数値サマリ

| プラグイン | Skills | Agents | Commands | MCP Tools |
|-----------|:------:|:------:|:--------:|:---------:|
| Superpowers | 14 | 1 | - | - |
| ECC | 147 | 36 | 80+ | context7, github, playwright, exa, memory |
| OMC | 37 | 19 | - | - |
| Ralph Loop | - | - | 3 | - |
| Frontend Design | 1 | - | - | - |
| Slack | 2 | - | 5 | - |
| Circleback | - | - | - | ~10 (MCP) |
| Deploy on AWS | 1 | - | - | ~12 (MCP) |
| AWS Amplify | 1 | - | - | ~2 (MCP) |
| AWS Serverless | 4 | - | - | ~20 (MCP) |
| Codex | 3 | 1 | - | - |
| **合計** | **~210** | **~57** | **~88** | **~44** |

---

## 参考: 仕様駆動開発ツール比較との対応

ga-copilot向け比較表（`仕様駆動開発ツール比較_ga-copilot-Storyboard.md`）で言及されたツールの導入状況:

| ツール | 導入状態 | 備考 |
|--------|:--------:|------|
| AI-DLC | ✅ 導入済み | `.steering/aws-aidlc-rules` + `.steering/aws-aidlc-rule-details` としてekocci にも配置済み |
| Tsumiki (Classmethod) | ❌ **未導入** | Kairoサブシステム含む。Claude Code スキルとして導入可能 |
| cc-sdd (gotalab) | ❌ **未導入** | 仕様駆動開発の本命。GitHub 3000★ |
| takt (nrslib) | ❌ **未導入** | YAML宣言的ワークフロー。GitHub 893★ |
| Superpowers | ✅ 導入済み | v5.0.7 |
| ECC | ✅ 導入済み | v1.9.0 |
| OMC | ✅ 導入済み | v4.10.1 |

### ekocci で追加導入を検討すべきツール

| 優先度 | ツール | 理由 |
|:------:|--------|------|
| HIGH | **Tsumiki** | kairo-tasks→kairo-loop→auto-debug のパイプラインが watchOS アプリの段階的実装に有効。EARS記法による要件明確化も |
| MEDIUM | **cc-sdd** | 仕様ファイルからテスト・コード自動生成。ただし Swift/watchOS での動作は未検証 |
| LOW | **takt** | チーム開発やマルチプロバイダー利用時に検討。個人開発では優先度低 |
