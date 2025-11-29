# 初期セットアップ用 Terraform

GitHub Actions から GCP を操作するための Workload Identity Federation を設定します。
このディレクトリの Terraform は **初回のみ手動で実行** する必要があります。

## 前提条件

- GCP プロジェクトが作成済みであること
- gcloud CLI で認証済みであること
- 必要な権限（Project Editor 以上）があること

## セットアップ手順

### 1. Terraform の初期化

```bash
cd terraform/environments/gcp/ysku-dev/init
terraform init
```

### 2. 実行プランの確認

```bash
terraform plan
```

以下のリソースが作成されます:
- Workload Identity Pool: `github-actions-pool`
- Workload Identity Provider: `github-actions-provider`
- Service Account: `github-actions@ysku-dev.iam.gserviceaccount.com`
- 必要な IAM バインディング
- 必要な GCP API の有効化

### 3. リソースの作成

```bash
terraform apply
```

### 4. 出力値の確認

```bash
terraform output workload_identity_provider
terraform output service_account_email
```

この出力値を GitHub Actions のワークフローで使用します。

## GitHub Actions での使用方法

ワークフローに以下を追加:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: '<terraform output で取得した値>'
          service_account: 'github-actions@ysku-dev.iam.gserviceaccount.com'

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Use gcloud CLI
        run: gcloud info
```

## 注意事項

- このディレクトリの Terraform State はローカルに保存されます（GCS バックエンドは使用しません）
- 一度セットアップが完了したら、通常は再実行する必要はありません
- リポジトリを追加する場合は `terraform.tfvars` を更新して `terraform apply` を実行してください
