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

   ```

2. **共通基盤 (`shared`) のデプロイ** (必須)
   各サービス環境が依存する共有リソースを作成します。
   ```bash
   cd shared
   terraform init
   terraform apply
   ```
   **前提条件:**
   - AWS Route53 からの委譲設定が完了していること（詳細は `shared/README.md`）。
   - Cloud DNS Managed Zone (`ysku-dev-zone`) が作成されていること。

3. **各サービス環境 (`allies` 等) のデプロイ** (任意)
   アプリケーションごとのリソースを作成します。
   ```bash
   cd allies
   terraform init
   terraform apply
   ```

## 依存関係と実行順序

以下の順序で実行する必要があります。

1.  `init/` : Workload Identity (GHA連携用)
2.  `shared/` : ネットワーク、GKE、Cloud DNS、共有IP
3.  `allies/` (等) : 各サービスのDNSレコード、IAMバインディング

※ `allies` などのサービス環境は、`shared` で作成されたリソース（Cloud DNS Zone、Shared IP）を参照するため、**必ず `shared` の適用後に** 実行してください。