# GitHub Actions Workflows

このディレクトリには、インフラストラクチャのデプロイを自動化する GitHub Actions ワークフローが含まれています。

## ワークフロー一覧

### `deploy-shared.yml`

共有インフラ（VPC、GKE）を管理するワークフローです。

#### トリガー条件

1. **手動実行（workflow_dispatch）**
   - GitHub の Actions タブから手動で実行
   - `plan`、`apply`、`destroy` から選択可能

2. **自動実行（push）**
   - `main` ブランチへのプッシュ時
   - 以下のパスに変更があった場合:
     - `terraform/environments/gcp/ysku-dev/shared/**`
     - `terraform/modules/gcp/**`
     - `.github/workflows/deploy-shared.yml`
   - 自動的に `terraform plan` を実行
   - `main` ブランチでは自動的に `terraform apply` も実行

3. **Pull Request**
   - PR 作成時に `terraform plan` を実行
   - 結果を PR にコメント

#### 手動実行方法

1. GitHub リポジトリの **Actions** タブを開く
2. 左サイドバーから **Deploy Shared Infrastructure** を選択
3. **Run workflow** ボタンをクリック
4. アクションを選択:
   - `plan`: 実行プランの確認のみ
   - `apply`: インフラを作成/更新
   - `destroy`: インフラを削除
5. **Run workflow** をクリック

#### 認証方式

Workload Identity Federation を使用して、Google Cloud に認証します。

- **Workload Identity Provider**: `projects/834974033969/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider`
- **Service Account**: `github-actions@ysku-dev.iam.gserviceaccount.com`

#### 実行ステップ

1. コードのチェックアウト
2. Google Cloud への認証
3. Terraform のセットアップ
4. Terraform のフォーマットチェック
5. Terraform の初期化
6. Terraform の検証
7. Terraform プランの作成
8. Terraform の適用（条件による）

#### 権限

ワークフローには以下の権限が必要です:

- `id-token: write` - Workload Identity Federation の認証に必要
- `contents: read` - リポジトリのコードを読み取るために必要
- `pull-requests: write` - PR にコメントを投稿するために必要

## ベストプラクティス

### main ブランチへのマージ前

1. Pull Request を作成
2. 自動的に `terraform plan` が実行される
3. PR のコメントで変更内容を確認
4. レビュー後、マージ

### main ブランチへのマージ後

1. 自動的に `terraform apply` が実行される
2. Actions タブで実行状況を確認

### 緊急時の手動実行

1. Actions タブから手動でワークフローを実行
2. 必要に応じて `destroy` を選択してリソースを削除

## トラブルシューティング

### 認証エラー

Workload Identity Federation の設定を確認:

```bash
cd terraform/environments/gcp/ysku-dev/init
terraform output workload_identity_provider
terraform output service_account_email
```

出力値が `.github/workflows/deploy-shared.yml` の設定と一致しているか確認してください。

### Terraform State のロック

複数の実行が同時に行われた場合、State がロックされることがあります。
GCS で State のロックを解除:

```bash
terraform force-unlock <LOCK_ID>
```

### リソースの作成に失敗

1. Actions の詳細ログを確認
2. 必要な API が有効化されているか確認
3. Service Account の権限を確認

## セキュリティ

- Service Account Key は使用していません
- Workload Identity Federation で一時的な認証情報を使用
- 最小権限の原則に従って Service Account の権限を設定
