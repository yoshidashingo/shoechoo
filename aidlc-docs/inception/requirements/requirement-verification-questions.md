# Requirements Verification Questions — Cycle 2 Refactoring

## Q1: リファクタリングの最優先目標

RE分析で技術的負債10件が特定されました。今回のリファクタリングで最も重視する目標はどれですか？

- A) **安定性**: クラッシュ・フリーズの完全排除（残存バグの修正）
- B) **アーキテクチャ品質**: NotificationCenter廃止、型安全なコマンドパターンへの移行
- C) **WYSIWYG体験の向上**: アクティブ/非アクティブブロックの切替、デリミタ非表示の品質向上
- D) **テストカバレッジ**: 現在~45%を80%以上に引き上げ
- E) **全部**: 上記すべてを段階的に実施
- X) Other (please describe)

[Answer]:

---

## Q2: NotificationCenter の置換方針

TD-01/TD-05で特定された最大の技術的負債です。5つのNotification（toggleFormatting, insertFormattedText, setLinePrefix, insertImageMarkdown, scrollToPosition）をどう置換しますか？

- A) **クロージャ/コールバック**: EditorViewModelにクロージャプロパティを定義、Coordinatorが直接バインド
- B) **Protocol/Delegate**: EditorCommandDelegate プロトコルを定義、Coordinatorが実装
- C) **Combine/AsyncStream**: Publisher/Subscriber パターンで型安全に伝達
- D) **直接参照**: CoordinatorがEditorViewModelを直接参照し、メソッド呼び出し（現在の逆方向）
- X) Other (please describe)

[Answer]:

---

## Q3: 複数ウィンドウ対応

TD-05で`object: nil`による複数ウィンドウ問題が特定されました。複数ウィンドウ対応をどこまで行いますか？

- A) **完全対応**: 各ウィンドウが独立して動作、コマンドは対象ウィンドウのみに影響
- B) **最低限**: NotificationCenter置換で自然に解消される範囲のみ
- C) **将来対応**: 今回はシングルウィンドウ前提で進め、複数ウィンドウは後回し
- X) Other (please describe)

[Answer]:

---

## Q4: ARCHITECTURE.md と実装の乖離（TD-03）

RE分析でARCHITECTURE.mdと実装に7箇所の乖離が発見されました。

- A) **実装に合わせてドキュメント更新**: 現在の実装が正しいとみなし、ドキュメントを修正
- B) **ドキュメントに合わせて実装修正**: 元の設計意図に戻す（RenderCache復活、50msデバウンス等）
- C) **両方を見直し**: 現在の実装とドキュメントの両方を最適な形に再設計
- X) Other (please describe)

[Answer]:

---

## Q5: isRichText=false の矛盾（TD-04）

NSTextViewの`isRichText = false`設定でリッチ属性をプログラム的に操作している矛盾があります。

- A) **isRichText = true に変更**: リッチテキスト操作を正式にサポート（ペースト時のリッチ属性除去は別途実装）
- B) **現状維持**: isRichText=false のまま、プログラム的な属性操作は許容されるため問題なし
- C) **TextKit 2 への移行**: NSTextLayoutManager ベースに移行し、属性管理を近代化
- X) Other (please describe)

[Answer]:

---

## Q6: テストカバレッジ戦略

現在98テスト、推定カバレッジ~45%。80%目標に向けてどう進めますか？

- A) **リファクタリングと並行**: 各コンポーネント修正時にテストも追加（TDD）
- B) **リファクタリング後に一括**: まずコード修正を完了し、その後テストを追加
- C) **クリティカルパスのみ**: パーサー、ハイライター、ドキュメント保存のテストを重点的に
- X) Other (please describe)

[Answer]:

---

## Q7: Highlightr 依存の扱い

project.ymlでHighlightr 2.2.1が宣言されていますが、コード内で直接利用されていません。

- A) **削除**: 不要な依存を除去してビルドを軽量化
- B) **活用**: コードブロックのシンタックスハイライトに実際に使用する
- C) **将来判断**: 今回は触れない
- X) Other (please describe)

[Answer]:

---

## Q8: セキュリティベースライン（Extension）

Cycle 1から Security Baseline extension が有効です。引き続き有効にしますか？

- A) **はい**: セキュリティベースラインを引き続き適用（画像インポートのパストラバーサル防止等）
- B) **いいえ**: リファクタリングフェーズでは不要

[Answer]:

---

## Q9: リファクタリングの段階分け

システム全体のリファクタリングをどう段階分けしますか？

- A) **レイヤー別**: Model層 → Parser層 → Renderer層 → Editor層 → View層の順
- B) **技術的負債の深刻度順**: TD-05(複数ウィンドウ) → TD-01(型安全性) → TD-03(ドキュメント乖離) → ...
- C) **機能フロー別**: テキスト編集フロー → 保存フロー → エクスポートフロー → ...
- D) **AI-DLCに任せる**: Workflow Planningで最適な順序を提案してもらう
- X) Other (please describe)

[Answer]:
