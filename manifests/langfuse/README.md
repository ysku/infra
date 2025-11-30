# Langfuse Deployment

Helm + Kustomize を使用して Langfuse を GKE にデプロイします。

## 構成

```
manifests/langfuse/
├── base/
│   ├── namespace.yaml     # Namespace リソース
│   ├── values.yaml        # Helm values
│   ├── all.yaml          # Helm template で生成されたマニフェスト
│   └── kustomization.yaml # Kustomize base 設定
└── overlays/
    └── production/       # 環境固有の設定（今後追加予定）
```

## セットアップ手順

### 1. Helm リポジトリの追加

```bash
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update
```

### 2. values.yaml の作成・編集

`base/values.yaml` に Langfuse の設定を記述します。

主な設定項目:
- データベース接続情報
- NextAuth 設定
- Ingress 設定
- リソース制限など

### 3. マニフェストの生成

Helm template コマンドで Kubernetes マニフェストを生成します:

```bash
cd manifests/langfuse/base
helm template langfuse langfuse/langfuse -f values.yaml > all.yaml
```

**注意**: `values.yaml` を変更した場合は、必ずこのコマンドを再実行して `all.yaml` を更新してください。

### 4. Kustomize でのビルド確認

```bash
cd manifests/langfuse/base
kubectl kustomize .
```

### 5. デプロイ

```bash
kubectl apply -k manifests/langfuse/base
```

すべてのリソースは `langfuse` namespace にデプロイされます。

## values.yaml の更新手順

1. `base/values.yaml` を編集
2. マニフェストを再生成:
   ```bash
   cd manifests/langfuse/base
   helm template langfuse langfuse/langfuse -f values.yaml > all.yaml
   ```
3. 変更を確認:
   ```bash
   kubectl kustomize .
   ```
4. デプロイ:
   ```bash
   kubectl apply -k manifests/langfuse/base
   ```

## 注意事項

- `all.yaml` は自動生成されるファイルです。直接編集しないでください
- 設定変更は必ず `values.yaml` で行い、`helm template` で再生成してください
- 環境固有の設定は `overlays/` ディレクトリで管理します（今後追加予定）

## トラブルシューティング

### マニフェストが古い

`values.yaml` を変更したのに反映されない場合、`all.yaml` の再生成を忘れている可能性があります:

```bash
cd manifests/langfuse/base
helm template langfuse langfuse/langfuse -f values.yaml > all.yaml
```

### Helm チャートのバージョン確認

```bash
helm search repo langfuse/langfuse --versions
```

### 特定バージョンの使用

```bash
helm template langfuse langfuse/langfuse --version 0.x.x -f values.yaml > all.yaml
```
