---
name: weekly-report
description: DynamoDB の利用量・チャージ履歴を集計し SES で週次レポートを送信する
---

# weekly-report

## Goal

毎週土曜午前5時に、`ai-solution@iflag.co.jp` へ週次レポートメールを送る。

## Steps

1. 対象週の期間計算を実装する
2. DynamoDB から日次利用額を取得する
3. DynamoDB からプロジェクト別利用額を取得する
4. DynamoDB から Auto Charge 履歴を取得する
5. テキストメール本文を生成する
6. SES で送信する
7. 送信履歴を保存する
8. EventBridge schedule と接続する

## Done

- 期間境界のテストがある
- データなしの週でもメールが生成できる
- SES 送信失敗時の扱いがテストされている
- 送信履歴が保存される
