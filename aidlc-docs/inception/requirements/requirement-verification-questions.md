# Requirements Verification Questions — Cycle 2 Refactoring

## Q1: リファクタリングの最優先目標

- A) 安定性  B) アーキテクチャ品質  C) WYSIWYG体験  D) テストカバレッジ  E) 全部  X) Other

[Answer]: E — 全部を段階的に実施

---

## Q2: NotificationCenter の置換方針

- A) クロージャ  B) Protocol/Delegate  C) Combine/AsyncStream  D) 直接参照  X) Other

[Answer]: X — Protocol/Delegate + クロージャのハイブリッド（AI推奨）

---

## Q3: 複数ウィンドウ対応

- A) 完全対応  B) 最低限  C) 将来対応  X) Other

[Answer]: A — 完全対応

---

## Q4: ARCHITECTURE.md と実装の乖離

- A) 実装に合わせてドキュメント更新  B) ドキュメントに合わせて実装修正  C) 両方を見直し  X) Other

[Answer]: C — 両方を見直し

---

## Q5: isRichText=false の矛盾

- A) isRichText = true に変更  B) 現状維持  C) TextKit 2 への移行  X) Other

[Answer]: C — TextKit 2 への移行

---

## Q6: テストカバレッジ戦略

- A) リファクタリングと並行（TDD）  B) リファクタリング後に一括  C) クリティカルパスのみ  X) Other

[Answer]: A — リファクタリングと並行（TDD）

---

## Q7: Highlightr 依存の扱い

- A) 削除  B) 活用  C) 将来判断  X) Other

[Answer]: B — 活用（コードブロックのシンタックスハイライトに使用）

---

## Q8: セキュリティベースライン

- A) はい  B) いいえ

[Answer]: A — はい（引き続き適用）

---

## Q9: リファクタリングの段階分け

- A) レイヤー別  B) 深刻度順  C) 機能フロー別  D) AI-DLCに任せる  X) Other

[Answer]: D — AI-DLCに任せる
