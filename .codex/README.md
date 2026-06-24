# Codex Project Guide

この `.codex` は、OpenAI API 利用量・Auto Charge 通知の週次レポート自動化を進めるためのガイドです。

## 対象

- OpenAI Cost API から `ai-solution@iflag.co.jp` の日次利用量・利用金額を取得する
- Auto Charge 通知メールを読み込み、本文と抽出できたチャージ金額を保存する
- 毎週土曜午前5時に、1週間分の利用額・プロジェクト別利用額・チャージ履歴を集計する
- Amazon SES で `ai-solution@iflag.co.jp` 宛に週次レポートを送信する

## 対象外

- ChatGPT Enterprise の利用量取得
- 領収書・請求書 PDF の取得
- OpenAI Billing History 画面のスクレイピング
- Cookie を使った OpenAI 画面操作
- フロントエンド画面
- FastAPI、PostgreSQL、React、orval

## 想定技術

- AWS Lambda
- Amazon EventBridge
- Amazon DynamoDB
- Amazon SES
- AWS Secrets Manager
- CloudWatch Logs
- OpenAI Cost API
- メール取得 API またはメール受信連携

## 推奨フロー

1. `agents/planner.md` で実装計画を作る
2. `agents/serverless-foundation.md` で AWS サーバーレス基盤を整える
3. `agents/cost-collector.md` で OpenAI Cost API の日次収集を実装する
4. `agents/autocharge-ingestor.md` で Auto Charge 通知メールの取込を実装する
5. `agents/weekly-report.md` で週次集計と SES 送信を実装する
6. `agents/test-and-observability.md` でテスト、ログ、エラー通知を確認する
