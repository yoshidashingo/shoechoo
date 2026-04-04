# Persona & Scenario

**Assume the role** of a UX researcher / service designer

**Always executes.** コンセプトを基に、ターゲットペルソナとシナリオを設計する。

## Prerequisites
- Concept Design が完了していること
- `aidlc-docs/service-design/definition/concept-design.md` を読み込むこと

## Execution Steps

### Step 1: ペルソナ設計

ターゲットセグメントごとにペルソナを作成する（1〜3体）:

| 項目 | 内容 |
|------|------|
| 名前 | [仮名] |
| 年齢 | |
| 性別 | |
| 職業/役職 | |
| 所属（業界・規模） | |
| 技術リテラシー | 高/中/低 |
| 性格・行動特性 | |
| 現在の状況 | [このペルソナの日常・業務環境] |
| 課題 | [抱えている具体的な課題] |
| ゴール | [どうなったら成功か] |
| 情報源 | [普段参照するメディア・コミュニティ] |

**ペルソナ作成のルール**:
- 調査結果（Research & Analysis）に基づくこと
- 想像ではなくデータに裏付けられた特徴を優先
- 複数ペルソナがある場合、優先順位を付ける（プライマリ/セカンダリ）

### Step 2: 6コマシナリオの作成

ペルソナごとに、サービス利用前→利用後のストーリーを作成:

```
**[ペルソナ名]** は、
**[課題や困っている状況の描写]** が、
**[サービス名]** を使うことで
**[解決した状態・得られた変化]** となった。
```

6コマの構成:
1. **日常**: ペルソナの普段の状況
2. **課題発生**: 困りごと・ペインの発生
3. **サービス発見**: サービスとの出会い
4. **サービス利用**: 具体的な利用シーン
5. **課題解決**: ペインの解消
6. **変化した日常**: サービスによって変わった生活/業務

### Step 3: To-Be ジャーニーの作成

As-Is ジャーニー（Research & Analysis で作成済み）と対比する形で、
サービス導入後の理想的な顧客体験を描く:

| ステップ | As-Is（現状） | To-Be（理想） | 提供する価値 |
|---------|-------------|-------------|------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

### Step 4: シナリオの検証

作成したシナリオが以下を満たすか確認:
- [ ] ペルソナの課題がリサーチ結果と整合しているか
- [ ] 価値仮説シート（Concept Design）と矛盾がないか
- [ ] 6コマシナリオが自然で現実的か
- [ ] To-Be ジャーニーが実現可能か

### Step 5: 質問ファイルの生成

ペルソナやシナリオの妥当性に疑問がある場合:
1. `aidlc-docs/service-design/definition/persona-questions.md` を作成
2. AI-DLCの質問フォーマットに従う
3. ユーザーの回答を待つ

### Step 6: 成果物の作成

`aidlc-docs/service-design/definition/persona-scenario.md` を作成:
- `common/output-templates.md` のテンプレートに従う

### Step 7: 完了メッセージ

```markdown
# Persona & Scenario Complete

ペルソナとシナリオの設計が完了しました:
- [主要なペルソナと発見を箇条書きで記載]

> **REVIEW REQUIRED:**
> 成果物を確認してください: `aidlc-docs/service-design/definition/persona-scenario.md`

> **WHAT'S NEXT?**
>
> **You may:**
>
> **Request Changes** - 成果物の修正を依頼
> **Add Ideation** - **Ideation & Deep-dive** ステージを追加（コンセプトの発散・収束が必要な場合）
> **Approve & Continue** - 承認して **VALIDATION PHASE** へ進む
```
