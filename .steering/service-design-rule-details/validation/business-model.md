# Business Model & KPI

**Assume the role** of a business strategist / financial analyst

**Always executes.** サービスのビジネスモデル、収益構造、KPIを設計する。

## Prerequisites
- Customer Journey & Service Blueprint が完了していること
- 以下を読み込むこと:
  - `aidlc-docs/service-design/discovery/goal-strategy.md`
  - `aidlc-docs/service-design/discovery/research-analysis.md`
  - `aidlc-docs/service-design/definition/concept-design.md`
  - `aidlc-docs/service-design/validation/customer-journey.md`

## Execution Steps

### Step 1: ビジネスモデルの設計

以下の要素を構造化する:

#### 1.1 ビジネスモデルキャンバス

| 要素 | 内容 |
|------|------|
| **顧客セグメント** | 誰に価値を提供するか |
| **価値提案** | どんな価値を提供するか |
| **チャネル** | どう届けるか |
| **顧客との関係** | どう関係を維持するか |
| **収益の流れ** | どう収益を得るか |
| **主要リソース** | 何が必要か |
| **主要活動** | 何をするか |
| **パートナー** | 誰と組むか |
| **コスト構造** | 何にコストがかかるか |

### Step 2: マネタイズプランの策定

#### 2.1 料金モデル

適用可能なモデルを検討:
- **月額/年額サブスクリプション**: 継続課金
- **プロジェクト単価**: スポット契約
- **従量課金**: 利用量に応じた課金
- **成果報酬**: 成果に連動した課金
- **フリーミアム**: 基本無料 + 有料プラン
- **ハイブリッド**: 上記の組み合わせ

#### 2.2 価格設定

| プラン | 価格 | 提供内容 | ターゲット | 想定顧客数 |
|--------|------|---------|-----------|-----------|
| | | | | |

**価格設定の根拠**:
- 競合価格との比較
- 顧客の支払い意思（WTP: Willingness to Pay）
- 原価に基づく下限
- 提供価値に基づく上限

### Step 3: KGI/KPI設定

#### 3.1 KGI（Key Goal Indicator）

| KGI | 目標値 | 期限 | 計測方法 |
|-----|--------|------|---------|
| | | | |

#### 3.2 KPI（Key Performance Indicator）

| KPI | 目標値 | 計測頻度 | 計測方法 | 関連KGI |
|-----|--------|---------|---------|--------|
| | | 日次/週次/月次 | | |

**推奨KPI例（B2Bサービス）**:
- MRR（Monthly Recurring Revenue）
- Churn Rate（解約率）
- LTV（Life Time Value）
- CAC（Customer Acquisition Cost）
- NPS（Net Promoter Score）
- 契約更新率
- 顧客あたり単価

### Step 4: コスト構造の分析

#### 4.1 固定費

| 項目 | 月額コスト | 備考 |
|------|-----------|------|
| 人件費 | | |
| インフラ/ツール | | |
| その他 | | |

#### 4.2 変動費

| 項目 | 単価 | 変動要因 | 備考 |
|------|------|---------|------|
| | | | |

### Step 5: 収支計画表の作成

| 項目 | Month 1 | Month 3 | Month 6 | Year 1 | Year 2 |
|------|---------|---------|---------|--------|--------|
| **売上** | | | | | |
| プランA | | | | | |
| プランB | | | | | |
| **コスト** | | | | | |
| 固定費 | | | | | |
| 変動費 | | | | | |
| **営業利益** | | | | | |
| **累計損益** | | | | | |

**BEP（損益分岐点）**: [顧客数 or 売上額] で損益分岐

### Step 6: 質問ファイルの生成

ビジネスモデルに不明点がある場合:
1. `aidlc-docs/service-design/validation/business-model-questions.md` を作成
2. AI-DLCの質問フォーマットに従う
3. ユーザーの回答を待つ

### Step 7: 成果物の作成

`aidlc-docs/service-design/validation/business-model.md` を作成:
- ビジネスモデルキャンバス
- マネタイズプラン・価格設定
- KGI/KPI設定
- コスト構造
- 収支計画表

### Step 8: 完了メッセージ

```markdown
# Business Model & KPI Complete

ビジネスモデルとKPI設計が完了しました:
- [主要な数値と発見を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/validation/business-model.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Approve & Continue** - 承認して **PROTOTYPING PHASE** へ進む
```
