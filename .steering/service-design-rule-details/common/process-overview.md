# Service Design Process Overview

**Purpose**: サービスデザインワークフローの全体像を理解するためのテクニカルリファレンス。

## 4フェーズ構成（Double Diamond モデル）

```
    DISCOVERY          DEFINITION         VALIDATION        PROTOTYPING
    (発見)              (定義)              (検証)            (試作)
   ╱        ╲        ╱        ╲         ╱        ╲        ╱        ╲
  ╱ 発散     ╲      ╱ 発散     ╲       ╱ 発散     ╲      ╱ 発散     ╲
 ╱            ╲    ╱            ╲     ╱            ╲    ╱            ╲
╱   問題空間   ╲  ╱  解決策空間  ╲   ╱  検証空間   ╲  ╱  実装空間   ╲
╲   の探索     ╱  ╲  の探索     ╱   ╲  の探索     ╱  ╲  の探索     ╱
 ╲            ╱    ╲            ╱     ╲            ╱    ╲            ╱
  ╲ 収束     ╱      ╲ 収束     ╱       ╲ 収束     ╱      ╲ 収束     ╱
   ╲        ╱        ╲        ╱         ╲        ╱        ╲        ╱
    Goal &             Concept            CJM &              MVP &
    Strategy           & Persona          Biz Model          Prototype
```

## フェーズ概要

### DISCOVERY PHASE - 発見
- **目的**: ビジネスゴールの設定と問題空間の理解
- **入力**: サービスアイデア、ビジネス課題
- **出力**: ゴール・戦略文書、リサーチ結果
- **ユーザーの役割**: ビジネス背景の提供、方向性の承認

### DEFINITION PHASE - 定義
- **目的**: コンセプトの具体化とターゲットの明確化
- **入力**: Discovery の成果物
- **出力**: コンセプト文書、ペルソナ、シナリオ、アイディエーション結果
- **ユーザーの役割**: コンセプトの評価、ペルソナの妥当性確認

### VALIDATION PHASE - 検証
- **目的**: コンセプトとビジネスモデルの検証
- **入力**: Definition の成果物
- **出力**: テスト結果、CJM、サービスブループリント、ビジネスモデル
- **ユーザーの役割**: テスト計画の承認、ビジネス判断

### PROTOTYPING PHASE - 試作
- **目的**: 技術検証とMVP構築
- **入力**: Validation の成果物
- **出力**: 技術スタック選定、MVPデザイン、ユーザーテスト結果
- **ユーザーの役割**: 技術選定の承認、テスト結果の評価

## AI-DLC との関係

```
Service Design Workflow          AI-DLC Workflow
+------------------+            +------------------+
| DISCOVERY        |            |                  |
| DEFINITION       | --------→ | INCEPTION        |
| VALIDATION       |            | (Requirements    |
| PROTOTYPING      |            |  Analysis etc.)  |
+------------------+            +------------------+
                                | CONSTRUCTION     |
                                +------------------+
                                | OPERATIONS       |
                                +------------------+
```

- サービスデザインは AI-DLC の **上流工程** に位置する
- サービスデザインの成果物が AI-DLC の Requirements Analysis の入力となる
- サービスデザインで確定した要件は AI-DLC で **システム要件** に変換される

## ステージ実行判定

| ステージ | 実行条件 | スキップ条件 |
|---------|---------|------------|
| Goal Setting & Strategy | ALWAYS | - |
| Research & Analysis | ALWAYS | - |
| Concept Design | ALWAYS | - |
| Persona & Scenario | ALWAYS | - |
| Ideation & Deep-dive | 複数アプローチあり / 不確実性高い | コンセプト明確 |
| Concept Testing | 需要未検証 / ピボット可能性あり | 需要確認済み |
| Customer Journey & Blueprint | ALWAYS | - |
| Business Model & KPI | ALWAYS | - |
| Technical Research | ALWAYS | - |
| MVP & UX Design | プロダクト型 / UI重要 | コンサル型 / UI不要 |
| User Testing | MVP実施済み / プロト動作可能 | MVP未実施 |
