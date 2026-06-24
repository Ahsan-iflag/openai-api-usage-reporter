# STATUS

最終更新日: 2026-06-24

## 現在のフェーズ

計画・開発ガイド整備フェーズ。

## 今回行った修正

- Codex CLI / Codex 向けの作業ルールとして `AGENTS.md` を追加。
- プロジェクト詳細は `docs/detail-plan.md` に集約し、`AGENTS.md` では作業ルールと実装方針だけを記載。
- 実装後に毎回 `STATUS.md` を更新するルールを `AGENTS.md` に追記。
- 現在の進捗・次タスクを管理する `STATUS.md` を追加。

## 実行した検証

- 作業前に `git pull origin main` を実行し、最新状態であることを確認。
- 添付された旧開発ガイドの内容を確認し、今回の AWS サーバーレス要件に合わせて不要なプロジェクト詳細を除外。

## 未実施の検証

- コード実装は行っていないため、`python -m compileall .`、`python -m pytest`、`sam validate` は未実行。

## 次にすべきこと

1. `docs/detail-plan.md` に沿って AWS SAM の土台を作成する。
2. `template.yaml`、Lambda handler、DynamoDB、S3、SES、EventBridge の最小構成を追加する。
3. OpenAI Cost API client、DynamoDB repository、メール parser、週次 report builder、SES sender の実装方針を固める。
4. pytest のテスト土台を追加する。
5. 実装後に `STATUS.md` を更新する。

## 注意点・未決事項

- AWS リージョンは `ap-northeast-1` を既定とする。
- SES inbound の MX record 設定は既存メール運用に影響する可能性があるため、実デプロイ前に確認が必要。
- secret は AWS Secrets Manager で管理し、コード・ログ・テストデータに書かない。
