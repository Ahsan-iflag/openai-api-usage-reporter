# OpenAI API 利用量・Auto Charge 通知 週次レポート自動化 実装計画

生成日: 2026-06-24

## 1. 概要

OpenAI Cost API から `ai-solution@iflag.co.jp` の OpenAI API 利用量・利用金額を日次で取得し、DynamoDB に蓄積する。

あわせて、`ai-solution@iflag.co.jp` に届く OpenAI Auto Charge 通知メールを Amazon SES inbound で受信し、S3 に保存されたメール本文から抽出できる範囲でチャージ金額を DynamoDB に保存する。

毎週土曜 05:00 JST に、1週間分の利用額、プロジェクト別利用額、Auto Charge 履歴を集計し、Amazon SES で `ai-solution@iflag.co.jp` 宛に週次レポートメールを送信する。

## 2. 対象範囲

- 対象ユーザー: `ai-solution@iflag.co.jp`
- 対象利用分: OpenAI API 利用分
- 利用額取得元: OpenAI Cost API
- メール取得方式: Amazon SES inbound + S3 + Lambda
- レポート送信方式: Amazon SES
- データ保存先: Amazon DynamoDB
- 認証情報管理: AWS Secrets Manager
- ログ管理: CloudWatch Logs
- リージョン既定値: `ap-northeast-1`

## 3. 対象外

- ChatGPT Enterprise の利用量取得
- 領収書・請求書 PDF の取得
- OpenAI Billing History 画面のスクレイピング
- Cookie を使った OpenAI 画面操作
- フロントエンド画面
- FastAPI、PostgreSQL、React、orval を前提にした Web アプリ構成

## 4. アーキテクチャ概要

```text
EventBridge
  |-- daily schedule --> Lambda: collect_daily_openai_costs
  |                         |-- Secrets Manager: OPENAI_ADMIN_KEY
  |                         |-- OpenAI Cost API
  |                         `-- DynamoDB: usage records
  |
  `-- weekly schedule --> Lambda: send_weekly_usage_report
                            |-- DynamoDB: usage / charge / report records
                            `-- SES: send weekly report

OpenAI Auto Charge email
  --> SES inbound
  --> S3 raw email object
  --> Lambda: ingest_autocharge_notifications
        `-- DynamoDB: charge records
```

## 5. Lambda 関数

### 5.1 `collect_daily_openai_costs`

目的:

- OpenAI Cost API から日次利用額とプロジェクト別利用額を取得する。
- 対象ユーザー `ai-solution@iflag.co.jp` に関係する利用データを DynamoDB に保存する。

主な処理:

1. Secrets Manager から `OPENAI_ADMIN_KEY` を取得する。
2. 対象日を決定する。
3. OpenAI Cost API を呼び出す。
4. pagination がある場合は全ページを取得する。
5. user / project / amount / quantity / bucket start / bucket end を正規化する。
6. DynamoDB に日付・ユーザー・プロジェクト単位で upsert する。
7. 処理件数、対象日、失敗理由を CloudWatch Logs に出力する。

冪等性:

- 同一対象日、同一ユーザー、同一プロジェクトのデータは上書き更新する。
- 再実行しても重複レコードを作らない。

### 5.2 `ingest_autocharge_notifications`

目的:

- SES inbound が S3 に保存した Auto Charge 通知メールを読み込み、本文と抽出できたチャージ金額を DynamoDB に保存する。

主な処理:

1. S3 event から bucket / object key を取得する。
2. raw email object を S3 から読み込む。
3. message id、received at、sender、subject、body を抽出する。
4. OpenAI Auto Charge 通知かどうかを判定する。
5. 本文から charge amount と currency を抽出する。
6. 抽出できない場合も本文と `extraction_status = failed` を保存する。
7. message id を使って重複保存を防ぐ。
8. 解析結果と失敗理由を CloudWatch Logs に出力する。

冪等性:

- `message_id` を一意キーとして扱う。
- 同一 message id のメールは2回保存しない。

### 5.3 `send_weekly_usage_report`

目的:

- 週次の利用額、プロジェクト別利用額、Auto Charge 履歴を集計し、SES でレポートメールを送信する。

主な処理:

1. 対象期間を決定する。
2. DynamoDB から対象期間の日次利用データを取得する。
3. DynamoDB から対象期間のプロジェクト別利用データを集計する。
4. DynamoDB から対象期間の Auto Charge 履歴を取得する。
5. テキストメール本文を生成する。
6. SES で `ai-solution@iflag.co.jp` から `ai-solution@iflag.co.jp` 宛に送信する。
7. SES message id と送信結果を DynamoDB に保存する。
8. 成功・失敗を CloudWatch Logs に出力する。

対象期間:

- 土曜 00:00:00 JST から金曜 23:59:59 JST まで。
- DynamoDB 保存日時は UTC とし、レポート表示では JST を併記する。

## 6. DynamoDB 設計

第一案は単一テーブル設計とする。

テーブル例:

- Table name: `openai-api-usage-reporter`
- Partition key: `PK`
- Sort key: `SK`

キー設計:

| 種別 | PK | SK |
| --- | --- | --- |
| 日次・プロジェクト別利用 | `USER#ai-solution@iflag.co.jp` | `USAGE#YYYY-MM-DD#PROJECT#{project_id}` |
| Auto Charge 通知 | `USER#ai-solution@iflag.co.jp` | `CHARGE#YYYY-MM-DDTHH:mm:ssZ#MESSAGE#{message_id}` |
| 週次レポート履歴 | `USER#ai-solution@iflag.co.jp` | `REPORT#YYYY-WW` |

Auto Charge 重複排除:

- `message_id` の一意性を担保するため、次のどちらかを実装時に採用する。
  - 同一テーブル内に `PK = MESSAGE#{message_id}`, `SK = CHARGE` の重複排除用アイテムを conditional put する。
  - または `GSI1PK = MESSAGE#{message_id}`, `GSI1SK = CHARGE` を付与し、保存前に検索する。
- 実装時の第一候補は conditional put による重複排除用アイテム方式とする。

金額の保存:

- 金額は文字列 decimal として保存する。
- 表示時のみ丸める。
- 通貨は必ず保存する。

主な属性:

| 属性 | 用途 |
| --- | --- |
| `record_type` | `usage`, `charge`, `report` |
| `user_email` | 対象ユーザー |
| `project_id` | OpenAI project id |
| `project_name` | 取得できる場合のみ保存 |
| `amount` | 利用額またはチャージ金額 |
| `currency` | 通貨 |
| `quantity` | Cost API の quantity |
| `bucket_start` | Cost API bucket start UTC |
| `bucket_end` | Cost API bucket end UTC |
| `received_at` | メール受信日時 UTC |
| `message_id` | メール message id |
| `subject` | メール件名 |
| `raw_body` | メール本文 |
| `extraction_status` | `success`, `failed`, `skipped` |
| `report_period_start` | レポート対象開始 UTC |
| `report_period_end` | レポート対象終了 UTC |
| `ses_message_id` | SES 送信 message id |
| `created_at` | 作成日時 UTC |
| `updated_at` | 更新日時 UTC |

## 7. SES inbound による Auto Charge メール取込

受信方式:

- `ai-solution@iflag.co.jp` 宛の OpenAI Auto Charge 通知メールを SES inbound で受信する。
- SES receipt rule で raw email を S3 bucket に保存する。
- S3 object created event で `ingest_autocharge_notifications` を起動する。

必要な設定:

- SES identity / domain または address verification
- MX record の SES inbound endpoint への設定
- SES receipt rule
- raw email 保存用 S3 bucket
- S3 event notification
- Lambda の S3 read 権限

注意:

- 既存メール運用に影響するため、MX record 変更の影響範囲を実装前に確認する。
- 既存メールボックスを維持する必要がある場合は、サブドメインや転送ルールを使う代替構成を検討する。
- 領収書・請求書 PDF の取得や解析は行わない。

## 8. OpenAI Cost API 日次収集

取得対象:

- `ai-solution@iflag.co.jp` の OpenAI API 利用分。
- 日次利用額。
- プロジェクト別利用額。

取得方針:

- `bucket_width = 1d` を基本とする。
- `group_by=user_id` と `group_by=project_id` のレスポンスを確認し、保存時に user / project の対応を保持する。
- API レスポンスに `user_email` や `project_name` が含まれない場合は ID を保存し、名前解決は別タスクとして扱う。
- pagination を最後まで処理する。

エラー時:

- OpenAI API が 429 または 5xx を返した場合は retry 対象にする。
- 認証エラーは retry せず、CloudWatch Logs に記録し、必要に応じてエラー通知する。

## 9. 週次レポート

送信条件:

- 毎週土曜 05:00 JST に送信する。
- EventBridge の UTC cron では金曜 20:00 UTC とする。

送信元・宛先:

- From: `ai-solution@iflag.co.jp`
- To: `ai-solution@iflag.co.jp`

メール本文:

```text
件名: OpenAI API 週次利用レポート YYYY-MM-DD - YYYY-MM-DD

対象期間:
YYYY-MM-DD HH:mm JST - YYYY-MM-DD HH:mm JST

合計利用額:
USD xxx.xx

日別利用額:
- YYYY-MM-DD: USD xx.xx

プロジェクト別利用額:
- project_name_or_id: USD xx.xx

Auto Charge 履歴:
- YYYY-MM-DD HH:mm JST: USD xx.xx / message_id

補足:
- 未解析 Auto Charge メール: n 件
- 収集エラー: n 件
```

送信履歴:

- 送信成功時は `REPORT#YYYY-WW` に送信履歴を保存する。
- SES message id、対象期間、合計金額、送信先、送信日時、ステータスを保存する。
- 送信失敗時も失敗ステータスと理由を保存する。

## 10. EventBridge スケジュール

| 用途 | JST | UTC cron | Target |
| --- | --- | --- | --- |
| 日次 Cost API 取得 | 毎日 05:10 JST | `cron(10 20 * * ? *)` | `collect_daily_openai_costs` |
| 週次レポート送信 | 毎週土曜 05:00 JST | `cron(0 20 ? * FRI *)` | `send_weekly_usage_report` |

補足:

- JST は UTC+9 のため、05:00 JST は前日 20:00 UTC。
- SES inbound は S3 event で起動するため EventBridge schedule は不要。

## 11. Secrets Manager 管理項目

| Secret | 内容 |
| --- | --- |
| `OPENAI_ADMIN_KEY` | OpenAI Cost API 用 Admin key |
| `ERROR_NOTIFICATION_EMAIL` | エラー通知先。既定値は `ai-solution@iflag.co.jp` |
| `SES_REPORT_SENDER` | レポート送信元。既定値は `ai-solution@iflag.co.jp` |

運用ルール:

- secret 値はコード、テストデータ、ログに出力しない。
- Lambda には secret 読み取りの最小権限のみ付与する。
- secret 名は環境変数で Lambda に渡す。

## 12. CloudWatch Logs / エラー通知

ログに出す情報:

- Lambda 関数名
- request id
- 対象日または対象期間
- 取得件数
- 保存件数
- skipped 件数
- failed 件数
- エラー種別

ログに出さない情報:

- OpenAI Admin key
- メール認証情報
- メール本文全文
- secret 値

エラー通知:

- 認証エラー、連続失敗、週次レポート送信失敗は通知対象とする。
- 通知先は `ai-solution@iflag.co.jp` とする。
- 初期実装では CloudWatch Logs に記録し、必要に応じて SES によるエラー通知を追加する。

## 13. 実装ステップ

| STEP | 内容 | 期間目安 | 成果物 |
| --- | --- | --- | --- |
| 1 | OpenAI Cost API から日次利用データを取得する処理を作成 | 0.5週間 | Cost API client、日次収集 Lambda |
| 2 | DynamoDB テーブル設計・保存処理を作成 | 0.5週間 | AWS SAM template、DynamoDB repository |
| 3 | Auto Charge 通知メールの読み込み・本文保存・チャージ金額抽出処理を作成 | 0.5週間 | SES inbound、S3、メール取込 Lambda、parser |
| 4 | 週次レポート集計処理を作成 | 0.5週間 | report builder、集計ロジック |
| 5 | SES による週次レポートメール送信処理を作成 | 0.5週間 | SES sender、送信履歴保存 |
| 6 | EventBridge による日次取得・毎週土曜5時レポート送信スケジュールを設定 | 0.25週間 | EventBridge rules |
| 7 | テスト・動作確認・エラー通知設定 | 0.25週間 | unit tests、SAM validation、運用ログ確認 |

合計期間目安:

- 2〜3週間
- 開発工数 20〜30時間程度

## 14. テスト・受け入れ条件

### Cost API

- pagination を最後まで処理できる。
- 空データでも正常終了する。
- API エラー時に適切に retry または失敗記録できる。
- 同じ対象日を再実行しても DynamoDB に重複保存されない。

### DynamoDB

- usage / charge / report の各 record を保存できる。
- usage は対象日・ユーザー・プロジェクト単位で upsert される。
- Auto Charge は message id で重複排除される。
- 金額と通貨が欠落しない。

### Auto Charge メール

- SES inbound で S3 に保存された raw email を読み込める。
- OpenAI Auto Charge 通知だけを処理対象にできる。
- チャージ金額抽出に成功したメールを `extraction_status = success` で保存できる。
- チャージ金額抽出に失敗したメールも `extraction_status = failed` で保存できる。
- PDF 添付や Billing History 画面操作を行わない。

### 週次レポート

- 土曜 00:00:00 JST から金曜 23:59:59 JST までを対象期間にできる。
- 利用データがない週でもレポートを送信できる。
- Auto Charge がない週でもレポートを送信できる。
- 日別利用額、プロジェクト別利用額、Auto Charge 履歴を本文に含められる。
- SES 送信成功時に送信履歴を保存できる。
- SES 送信失敗時に失敗履歴と理由を保存できる。

### セキュリティ・運用

- secret がコード、ログ、テストデータに露出していない。
- Lambda IAM policy が最小権限になっている。
- CloudWatch Logs で処理件数と失敗理由を追跡できる。
- `.codex` の方針と矛盾する FastAPI / PostgreSQL / React / orval 前提が入っていない。

## 15. 参考

- Amazon SES endpoints and quotas: https://docs.aws.amazon.com/general/latest/gr/ses.html
