# Unit of Work Dependencies — Cycle 2

## Dependency Graph

```mermaid
graph LR
    U1a["Unit 1a<br/>NotificationCenter廃止"]
    U1b["Unit 1b<br/>複数ウィンドウ検証"]
    U1c["Unit 1c<br/>Timer→Task"]
    U2["Unit 2<br/>Model層クリーンアップ"]
    U3["Unit 3<br/>TextKit 2 PoC"]
    GoNoGo{"Go/No-Go"}
    U4["Unit 4<br/>WYSIWYG+コードブロック"]
    U5["Unit 5<br/>ドキュメント+テスト"]

    U1a --> U1b
    U1a --> U3
    U3 --> GoNoGo
    GoNoGo --> U4
    U1a --> U5
    U1b --> U5
    U1c --> U5
    U2 --> U5
    U4 --> U5

    style U1a fill:#4CAF50,color:#fff
    style U1c fill:#4CAF50,color:#fff
    style U2 fill:#4CAF50,color:#fff
    style U1b fill:#FFA726,color:#000
    style U3 fill:#FF5252,color:#fff
    style GoNoGo fill:#FF5252,color:#fff
    style U4 fill:#FFA726,color:#000
    style U5 fill:#FFA726,color:#000
```

**凡例**: 緑=並行開始可、赤=判定ゲート、オレンジ=依存あり

## Dependency Matrix

| Unit | 依存先 | 並行可能 | ブロッカー |
|------|--------|---------|-----------|
| 1a | なし | 即開始可 | — |
| 1b | 1a | 1a完了後 | 1a |
| 1c | なし | 1aと並行可 | — |
| 2 | なし | 1aと並行可 | — |
| 3 | 1a | 1a完了後 | 1a |
| 4 | 3判定 | 3判定後 | 3 Go/No-Go |
| 5 | 1a,1b,1c,2,4 | 全Unit完了後 | 全Unit |

## 並行実行戦略

```
Phase A (並行): Unit 1a + Unit 1c + Unit 2
Phase B (1a完了後): Unit 1b + Unit 3 PoC
Phase C (3判定後): Unit 4
Phase D (全完了後): Unit 5
```

## Per-Unit ビルド検証ゲート

各Unit完了時に必須:
1. `xcodebuild build` — ビルドエラー0
2. `xcodebuild test` — 全テスト通過
3. Unit固有の検証（unit-of-work.md 各Unit の完了基準参照）
4. main へ squash merge
