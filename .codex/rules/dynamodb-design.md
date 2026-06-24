# DynamoDB Design Guide

## 保存対象

- 日次利用データ
- プロジェクト別利用データ
- Auto Charge メール本文
- チャージ金額
- 週次レポート送信履歴

## 設計方針

小規模運用では単一テーブル設計を第一候補にする。ただし、アクセスパターンが明確に分かれ、運用の単純さを優先する場合は用途別テーブルも許容する。

## 推奨アクセスパターン

- 対象週の日次利用データを取得する
- 対象週のプロジェクト別利用額を取得する
- 対象週の Auto Charge 履歴を取得する
- message id で Auto Charge 通知の重複を防ぐ
- report id または対象週で送信履歴を取得する

## キー設計例

単一テーブルの場合:

- `PK = USER#ai-solution@iflag.co.jp`
- `SK = USAGE#YYYY-MM-DD#PROJECT#{project_id}`
- `SK = CHARGE#YYYY-MM-DDTHH:mm:ssZ#MESSAGE#{message_id}`
- `SK = REPORT#YYYY-WW`

GSI が必要な場合:

- `GSI1PK = MESSAGE#{message_id}`
- `GSI1SK = CHARGE`

## 金額

- amount は文字列 decimal または minor unit の整数で保存する
- 表示時に丸める
- 通貨を必ず保存する

## 冪等性

- Cost API データは対象日・ユーザー・プロジェクト単位で upsert
- Auto Charge メールは message id で conditional write
- 週次レポート履歴は対象週で重複送信を検知できるようにする
