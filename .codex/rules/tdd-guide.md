# TDD Guide

## 基本サイクル

1. RED: 失敗するテストを書く
2. GREEN: 最小実装で通す
3. REFACTOR: テストを通したまま整理する

## このプロジェクトで優先するテスト

- OpenAI Cost API client
- DynamoDB repository
- Auto Charge メール parser
- 週次集計ロジック
- SES report sender
- Lambda handler
- IaC template validation

## モック方針

- OpenAI Cost API は HTTP mock を使う
- DynamoDB は moto、local DynamoDB、または repository mock を使う
- SES は送信 client を mock する
- Secrets Manager は secret provider を差し替える

## 禁止

- テストなしで parser や集計ロジックを実装しない
- 実 secret をテストに使わない
- 外部 API に依存するテストを通常の unit test に混ぜない
