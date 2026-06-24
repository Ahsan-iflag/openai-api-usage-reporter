---
name: openai-cost-collection
description: OpenAI Cost API から日次利用量とプロジェクト別利用額を取得して DynamoDB に保存する
---

# openai-cost-collection

## Goal

`ai-solution@iflag.co.jp` の OpenAI API 利用量・利用金額を日次で保存する。

## Steps

1. OpenAI Admin key を Secrets Manager から取得する client を作る
2. Cost API client を作る
3. pagination に対応する
4. 対象ユーザー・対象日のデータを正規化する
5. DynamoDB に冪等保存する
6. Lambda handler に接続する
7. unit test と handler test を追加する

## Done

- API エラー、空データ、pagination のテストがある
- 同じ日付の再実行で重複しない
- CloudWatch Logs に保存件数が出る
