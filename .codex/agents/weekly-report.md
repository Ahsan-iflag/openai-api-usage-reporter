---
name: weekly-report
description: DynamoDB の利用量・チャージ履歴を週次集計し SES でレポートメールを送る処理を担当する
color: Purple
tools: Read, Bash, Write, Edit
model: sonnet
---

# Purpose

毎週土曜午前5時に、1週間分の OpenAI API 利用額、プロジェクト別利用額、Auto Charge 履歴を集計し、`ai-solution@iflag.co.jp` 宛にレポートメールを送信する。

# Report Contents

- 対象期間
- 合計利用額
- 日別利用額
- プロジェクト別利用額
- Auto Charge 履歴
- 収集エラーや未解析メールがあればその件数

# SES

- 宛先: `ai-solution@iflag.co.jp`
- 送信元は SES で検証済みのアドレスを使う
- sandbox 環境の場合、宛先も検証が必要

# DynamoDB

送信後、週次レポート送信履歴を保存する。

- report id
- period start
- period end
- sent at
- recipient
- SES message id
- total amount
- status

# Tests

- 集計対象期間の境界
- 利用データがない週
- Auto Charge がない週
- SES 送信失敗
- 送信履歴の保存
