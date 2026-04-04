# Section-9 サービスカタログ

## サービス体系全体像

Section-9のサービスは、顧客のクラウドモダナイゼーション成熟度に応じた3段階で構成される。

```
成熟度: Modernize → Optimize → Innovate

Modernize : 既存システムのクラウドモダナイゼーション（サーバーレス化、コンテナ化）
Optimize  : クラウド運用の最適化（コスト削減、オブザーバビリティ、ガバナンス）
Innovate  : 生成AI・LLMを活用した新規事業・サービス開発
```

## サービスメニュー一覧

| # | サービス名 | 分類 | 詳細ファイル |
|---|-----------|------|-------------|
| 1 | サーバーレス＆モダンアプリケーション開発 | 開発 | services/serverless-modern-apps.md |
| 2 | Platform Engineering支援 | 基盤構築 | services/platform-engineering.md |
| 3 | 生成AIアプリケーション開発 | 開発・コンサルティング | services/genai-development.md |
| 4 | AWSコスト削減 | 最適化 | services/cost-optimization.md |
| 5 | HEROZ（AWSエンジニア人材紹介） | 人材 | services/talent.md |

## サービス選定ガイド

顧客の状況に応じた推奨サービスの組み合わせ:

### パターンA: レガシーシステムをモダナイズしたい
→ サーバーレス＆モダンアプリケーション開発 + Platform Engineering支援

### パターンB: クラウドコストを最適化したい
→ AWSコスト削減 + Platform Engineering支援（ガバナンス強化）

### パターンC: 生成AIで新規事業・業務改善したい
→ 生成AIアプリケーション開発（ユースケース開発WS → LLMアプリ開発）

### パターンD: クラウド人材を確保したい
→ HEROZ（SRE、クラウドエンジニア、LLMエンジニアの採用支援）

### パターンE: 包括的にクラウド活用を推進したい（推奨）
→ Platform Engineering支援をベースに、各サービスを段階的に組み合わせ

## 技術スタック

Section-9が主に活用する技術:

| カテゴリ | 技術 |
|---------|------|
| サーバーレス | AWS Lambda, API Gateway, DynamoDB, Step Functions |
| コンテナ | ECS, EKS（サーバーレス構成） |
| フロントエンド | AWS Amplify, Cognito |
| オブザーバビリティ | CloudWatch, New Relic, Datadog |
| ガバナンス | AWS Control Tower |
| 生成AI | LangChain, LangGraph, Dify, Amazon Bedrock |
| IaC | AWS CDK, Terraform |
