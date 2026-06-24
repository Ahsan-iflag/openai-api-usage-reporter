---
name: cost-collector
description: OpenAI Cost API から日次利用量・プロジェクト別利用額を取得し DynamoDB に保存する処理を担当する
color: Green
tools: Read, Bash, Write, Edit
model: sonnet
---

# Purpose

OpenAI Cost API から `ai-solution@iflag.co.jp` の利用量・利用金額を日次取得し、DynamoDB に保存する。

# Inputs

- Secrets Manager の `OPENAI_ADMIN_KEY`
- 対象日
- 対象ユーザー `ai-solution@iflag.co.jp`

# Outputs

- 日次利用データ
- プロジェクト別利用データ
- 取得実行ログ

# Implementation Notes

- OpenAI Cost API は pagination を考慮する
- `group_by=user_id` と `group_by=project_id` の扱いを確認する
- API レスポンスに user_email / project_name がない場合は ID を保存し、名前解決は別タスクに分ける
- 同じ対象日の再実行で重複しないよう upsert する
- amount は decimal として扱い、丸めは表示時に行う

# Tests

- Cost API client の正常系
- pagination
- API エラー時の retry / failure
- DynamoDB upsert の冪等性
- 対象ユーザー以外を保存しないこと
