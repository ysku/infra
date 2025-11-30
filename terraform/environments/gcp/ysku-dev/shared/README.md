# Shared Infrastructure

ysku-dev プロジェクト内の複数のアプリケーションで共有するインフラリソースを管理します。

## 構成リソース

### VPC Network
- **Network Name**: `shared-vpc`
- **説明**: すべてのプロジェクトで共有する VPC ネットワーク
- **自動サブネット作成**: 無効（手動で管理）

### Subnet
- **Subnet Name**: `gke-subnet`
- **Primary IP Range**: `10.0.0.0/20` (4,096 アドレス)
- **Region**: `asia-northeast1`
- **Private Google Access**: 有効

#### セカンダリ IP レンジ（GKE 用）
- **Pods**: `10.16.0.0/12` (1,048,576 アドレス)
- **Services**: `10.32.0.0/16` (65,536 アドレス)

### Cloud NAT
- **Router**: `nat-router`
- **NAT Gateway**: `nat-gateway`
- **用途**: プライベート IP から外部インターネットへのアクセス
- **IP 割り当て**: 自動
- **ログ**: エラーのみ記録

### Firewall Rules

#### `allow-internal`
- **目的**: VPC 内部の通信を許可
- **プロトコル**: TCP/UDP/ICMP
- **送信元**: VPC 内のすべての IP レンジ

#### `allow-iap-ssh`
- **目的**: Identity-Aware Proxy 経由の SSH アクセス
- **プロトコル**: TCP/22
- **送信元**: `35.235.240.0/20` (Google IAP)

#### `allow-health-checks`
- **目的**: Google Cloud Load Balancer からのヘルスチェック
- **プロトコル**: TCP
- **送信元**: `35.191.0.0/16`, `130.211.0.0/22`

### GKE Cluster
- **Cluster Name**: `shared-gke` (変更可能)
- **Mode**: Autopilot (fully managed by Google)
- **Type**: Regional
- **Region**: `asia-northeast1`
- **Release Channel**: `REGULAR`
- **Network**: VPC-native cluster (Alias IP 使用)

#### Autopilot の特徴
- ノードプールの管理が不要
- Podのリソース要求に基づいて自動的に最適なノードを選択・作成
- 使用したリソース分のみ課金
- セキュリティのベストプラクティスが自動適用
- Spot VMも自動的に活用

#### Private Cluster 設定
- **Private Nodes**: 有効（ノードにパブリック IP なし）
- **Private Endpoint**: 無効（コントロールプレーンはパブリックアクセス可能）
- **Master CIDR**: `172.16.0.0/28`

#### 自動で有効化される機能
- **Workload Identity**: 有効
- **Network Policy**: 有効
- **HTTP Load Balancing**: 有効
- **Horizontal Pod Autoscaling**: 有効
- **Managed Prometheus**: 有効
- **GCS Fuse CSI Driver**: 有効
- **Filestore CSI Driver**: 有効
- **Logging**: System Components + Workloads
- **Monitoring**: System Components

## デプロイ手順

### 前提条件
- Workload Identity Federation が `init/` でセットアップ済み
- GCS バケット `ysku-dev-tfstates` が作成済み

### 初期化とデプロイ

```bash
cd terraform/environments/gcp/ysku-dev/shared

# Terraform の初期化
terraform init

# 実行プランの確認
terraform plan

# リソースを作成
terraform apply
```

### 出力値の確認

```bash
# VPC 情報
terraform output vpc_name
terraform output vpc_self_link

# Subnet 情報
terraform output gke_subnet_name
terraform output gke_subnet_self_link

# GKE 用のセカンダリ IP レンジ名
terraform output gke_pods_range_name
terraform output gke_services_range_name

# GKE 情報
terraform output gke_cluster_name
terraform output gke_cluster_location
terraform output gke_service_account
```

### GKE クラスターへの接続

```bash
# gcloud で認証情報を取得（Autopilot は regional）
gcloud container clusters get-credentials shared-gke \
  --region=asia-northeast1 \
  --project=ysku-dev

# kubectl で確認
kubectl get nodes
kubectl get pods -A
```

## カスタマイズ

`terraform.tfvars` で以下の設定を変更できます:

```hcl
# GKE クラスター設定
gke_cluster_name    = "shared-gke"
gke_release_channel = "REGULAR"  # RAPID, REGULAR, STABLE

# Note: Autopilot モードでは以下の設定は不要です
# - gke_regional, gke_zone (常に regional)
# - gke_node_count, gke_min_node_count, gke_max_node_count (自動管理)
# - gke_machine_type, gke_disk_size_gb (自動選択)
# - gke_spot_enabled (自動的に活用)
```

## 次のステップ

VPC と GKE 作成後、各アプリケーション用のディレクトリを作成し、アプリケーション固有のリソース（Ingress、Service、Deployment など）を管理します。

## 注意事項

- このインフラは複数のアプリケーションで共有されます
- 変更する際は、すべての依存プロジェクトへの影響を確認してください
- Terraform State は GCS の `shared` プレフィックスに保存されます
