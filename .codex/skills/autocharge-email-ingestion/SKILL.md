---
name: autocharge-email-ingestion
description: Auto Charge 通知メールを取得し、本文と抽出金額を DynamoDB に保存する
---

# autocharge-email-ingestion

## Goal

OpenAI Auto Charge 通知メールから、保存可能な本文とチャージ金額を DynamoDB に保存する。

## Steps

1. メール取得方式を確認する
2. メール client を実装する
3. OpenAI Auto Charge 通知だけを対象にする filter を作る
4. 本文 parser を TDD で作る
5. message id で重複保存を防ぐ
6. 抽出できないメールも本文と status を保存する
7. Lambda handler に接続する

## Done

- 金額抽出 parser のテストがある
- message id 重複時のテストがある
- PDF や Billing History 操作をしていない
