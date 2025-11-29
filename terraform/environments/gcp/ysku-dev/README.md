# ysku-dev Environment

ysku-dev プロジェクトの GCP インフラ管理用ディレクトリです。

## ディレクトリ構成

### `init/`
**初回のみ実行**: GitHub Actions から GCP を操作するための Workload Identity Federation を設定します。

詳細は [init/README.md](init/README.md) を参照してください。

### その他のディレクトリ
目的別に Terraform コードを配置します。各ディレクトリには独自の `README.md` が含まれています。

## 初回セットアップ

1. **Workload Identity Federation の設定**
   ```bash
   cd init
   terraform init
   terraform apply
   ```

2. 各プロジェクトのディレクトリで必要なリソースをデプロイ