# OpenAI API Usage Reporter - Codex 開発ガイド

このファイルは、Codex CLI / Codex がこのリポジトリで作業するときに従うルールです。

プロジェクトの詳細要件、アーキテクチャ、DynamoDB 設計、スケジュール、受け入れ条件は `docs/detail-plan.md` を参照してください。このファイルには重複する詳細仕様を書かず、作業時の進め方と守るべきルールだけを記載します。

## 回答

- 日本語で回答してください。
- 実装内容、未実施の検証、次にやることを簡潔に報告してください。

## 作業開始時のルール

1. 作業前に必ず `git pull origin main` を実行してください。
2. `docs/detail-plan.md` を読み、今回の作業が計画のどの部分に対応するか確認してください。
3. `.codex/` 配下の agent / skill / rule も確認し、今回の AWS サーバーレス構成と矛盾しないようにしてください。
4. 既存のユーザー変更を勝手に戻さないでください。

## 技術方針

- AWS SAM を第一候補にしてください。
- Lambda は薄い handler にし、処理本体は分離してください。
- DynamoDB への保存は冪等にしてください。
- Auto Charge 通知メールは `message_id` で重複排除してください。
- 日時保存は UTC、レポート表示は JST 併記を基本にしてください。
- secret は AWS Secrets Manager から取得し、コード・ログ・テストデータに書かないでください。
- CloudWatch Logs に処理件数、対象期間、失敗理由を出してください。

## 採用技術

- AWS Lambda
- AWS SAM
- Amazon DynamoDB
- Amazon SES
- Amazon S3
- Amazon EventBridge
- AWS Secrets Manager
- CloudWatch Logs
- OpenAI Cost API
- Python
- pytest

## 採用しないもの

- FastAPI
- PostgreSQL
- React
- orval
- OpenAI Billing History 画面のスクレイピング
- Cookie を使った OpenAI 画面操作
- 領収書・請求書 PDF の取得

## 推奨ディレクトリ方針

実装を追加する場合は、以下のような構成を第一候補にしてください。既存構成ができた後は、その構成を優先してください。

```text
.
├── docs/
│   └── detail-plan.md
├── src/
│   ├── handlers/
│   ├── services/
│   ├── repositories/
│   ├── clients/
│   ├── parsers/
│   └── reports/
├── tests/
├── template.yaml
├── STATUS.md
└── AGENTS.md
```

## 実装フロー

1. 対象タスクを `docs/detail-plan.md` の章・STEP に紐づけて確認する。
2. テストを書ける処理は、先にテスト観点を整理する。
3. 小さく実装する。
4. 可能な範囲で検証する。
5. `STATUS.md` を更新する。
6. 最後に変更内容、検証結果、次の作業を報告する。

## テスト方針

実装した範囲に応じて、可能なものを実行してください。

```bash
python -m compileall .
python -m pytest
sam validate
```

`sam validate` は AWS SAM CLI が使える場合のみ実行してください。

優先してテストする観点:

- OpenAI Cost API pagination / 空データ / API エラー
- DynamoDB upsert の冪等性
- SES inbound メールの重複排除
- Auto Charge 金額抽出の成功 / 失敗
- 週次期間境界
- SES 送信成功 / 失敗
- secret がログ・コード・テストデータに露出していないこと

## STATUS.md 更新ルール

実装やドキュメント変更を行った後は、必ず `STATUS.md` を更新してください。

`STATUS.md` には以下を記載します。

- 最終更新日
- 現在のフェーズ
- 今回行った修正
- 実行した検証
- 未実施の検証
- 次にすべきこと
- 注意点・未決事項

古い履歴を長く残すよりも、現在の状態がすぐ分かることを優先してください。完了した詳細な作業ログを残したい場合は、必要に応じて別途ログファイルを作成してください。

## コミット前の確認

- `git status --short` で変更内容を確認してください。
- secret、`.env`、認証情報、不要な cache をコミットしないでください。
- 実行できなかった検証がある場合は、最終報告と `STATUS.md` に理由を書いてください。
