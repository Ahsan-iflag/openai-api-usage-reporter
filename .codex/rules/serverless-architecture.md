# Serverless Architecture Guide

## 方針

このプロジェクトは Web アプリではなく、AWS サーバーレスのバッチ・通知システムとして実装する。

## 採用技術

- AWS Lambda
- Amazon EventBridge
- Amazon DynamoDB
- Amazon SES
- AWS Secrets Manager
- CloudWatch Logs
- OpenAI Cost API
- メール取得 API またはメール受信連携

## 非採用

- FastAPI
- PostgreSQL
- React
- orval
- Cookie scraping
- OpenAI Billing History 画面操作

## Lambda 設計

- Lambda handler は薄く保つ
- OpenAI API client、DynamoDB repository、report builder、mail parser を分離する
- 外部 API 呼び出しは timeout と retry 方針を持つ
- 冪等キーを設計して再実行に耐える

## Timezone

- 保存日時は UTC
- レポート表示やスケジュール説明は JST を併記する
- JST 土曜 05:00 は UTC 金曜 20:00

## Security

- secrets は Secrets Manager から取得する
- IAM policy は最小権限にする
- secret やメール認証情報をログに出さない
