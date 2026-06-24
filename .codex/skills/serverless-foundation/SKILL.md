---
name: serverless-foundation
description: AWS Lambda/DynamoDB/SES/EventBridge/Secrets Manager を使うサーバーレス基盤を作成する
---

# serverless-foundation

## Goal

OpenAI API 利用量・Auto Charge 週次レポート自動化の基盤を作る。

## Outputs

- IaC template
- Lambda 関数の最小構成
- DynamoDB テーブル定義
- EventBridge schedule 定義
- SES 送信権限
- Secrets Manager 参照設定
- README または docs の起動・デプロイ手順

## Steps

1. 既存リポジトリの言語・パッケージ管理を確認する
2. IaC ツールが未導入なら AWS SAM を第一候補にする
3. Lambda 関数を3つ作る
   - `collect_daily_openai_costs`
   - `ingest_autocharge_notifications`
   - `send_weekly_usage_report`
4. DynamoDB テーブルを定義する
5. Secrets Manager の secret 名を環境変数で渡す
6. EventBridge の日次・週次スケジュールを定義する
7. CloudWatch Logs の保持期間を設定する
8. template validation を実行する

## Done

- ローカルで IaC validation が通る
- Lambda handler の smoke test が通る
- secret 値がコードに含まれていない
