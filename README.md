# Infra

Terraform と GitHub Actions を使用してクラウドインフラを管理するリポジトリです。

## 構成

### ディレクトリ構造

```
terraform/
├── environments/
│   └── gcp/
│       └── ysku-dev/
│           ├── init/       # 初回セットアップ（Workload Identity Federation）
│           └── shared/     # 共有インフラ（VPC、GKE）
└── modules/
    └── gcp/
        └── gh-actions-oidc/  # GitHub Actions OIDC モジュール

.github/
└── workflows/
    └── deploy-shared.yml     # 共有インフラのデプロイワークフロー
```

### レイヤー

- **init**: Workload Identity Federation のセットアップ（初回のみ手動実行）
- **shared**: VPC、GKE など複数プロジェクトで共有するリソース
- **各プロジェクト**: アプリケーション固有のリソース（今後追加予定）

## セットアップ

### 1. 初回セットアップ（ローカルで実行）

Workload Identity Federation を設定:

```bash
cd terraform/environments/gcp/ysku-dev/init
terraform init
terraform apply
```

詳細: [terraform/environments/gcp/ysku-dev/init/README.md](terraform/environments/gcp/ysku-dev/init/README.md)

### 2. 共有インフラのデプロイ

#### ローカルで実行する場合

```bash
cd terraform/environments/gcp/ysku-dev/shared
terraform init
terraform plan
terraform apply
```

#### GitHub Actions で実行する場合

1. GitHub の **Actions** タブを開く
2. **Deploy Shared Infrastructure** を選択
3. **Run workflow** をクリック
4. アクション（`plan`、`apply`、`destroy`）を選択して実行

詳細: [.github/workflows/README.md](.github/workflows/README.md)

## GitHub Actions

### 認証方式

Service Account Key を使わず、**Workload Identity Federation** で安全に認証します。

- **Workload Identity Provider**: GitHub Actions 用の OIDC プロバイダー
- **Service Account**: `github-actions@ysku-dev.iam.gserviceaccount.com`
- **権限**: `roles/editor`

### ワークフロー

#### Deploy Shared Infrastructure

- **トリガー**:
  - 手動実行（workflow_dispatch）
  - `main` ブランチへのプッシュ
  - Pull Request
- **実行内容**: VPC と GKE のデプロイ

詳細: [.github/workflows/README.md](.github/workflows/README.md)

## Folder Structure (詳細)

- `terraform/environments/<cloud provider>/<name>/{init,shared,<project name>}`
  - `cloud provider`: `gcp`
  - `name`: Google Cloud のプロジェクト ID（例: `ysku-dev`）
  - `init`: 初回セットアップ用
  - `shared`: 共有リソース
  - `<project name>`: 各アプリケーション名（今後追加）
