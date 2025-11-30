#!/bin/bash
set -e

NAMESPACE="langfuse"

echo "Generating secrets for Langfuse..."
echo ""

# Generate random passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
CLICKHOUSE_PASSWORD=$(openssl rand -base64 32)
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_SECRET_DEDICATED=$(openssl rand -base64 32)
SALT=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)

echo "Creating namespace if not exists..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Creating secrets..."

# PostgreSQL secret
kubectl create secret generic langfuse-postgresql-auth \
  --namespace=${NAMESPACE} \
  --from-literal=password="${POSTGRES_PASSWORD}" \
  --from-literal=postgres-password="${POSTGRES_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Created langfuse-postgresql-auth"

# Redis secret
kubectl create secret generic langfuse-redis-auth \
  --namespace=${NAMESPACE} \
  --from-literal=password="${REDIS_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Created langfuse-redis-auth"

# ClickHouse secret
kubectl create secret generic langfuse-clickhouse-auth \
  --namespace=${NAMESPACE} \
  --from-literal=password="${CLICKHOUSE_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Created langfuse-clickhouse-auth"

# NextAuth secret (dedicated)
kubectl create secret generic langfuse-nextauth-secret \
  --namespace=${NAMESPACE} \
  --from-literal=nextauth-secret="${NEXTAUTH_SECRET_DEDICATED}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Created langfuse-nextauth-secret"

# General secrets
kubectl create secret generic langfuse-general \
  --namespace=${NAMESPACE} \
  --from-literal=nextauth-secret="${NEXTAUTH_SECRET}" \
  --from-literal=salt="${SALT}" \
  --from-literal=encryption-key="${ENCRYPTION_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Created langfuse-general"

echo ""
echo "✅ All secrets created successfully!"
echo ""
echo "To view secrets:"
echo "  kubectl get secrets -n ${NAMESPACE}"
echo ""
echo "To delete secrets (if needed):"
echo "  kubectl delete secret langfuse-postgresql-auth langfuse-redis-auth langfuse-clickhouse-auth langfuse-nextauth-secret langfuse-general -n ${NAMESPACE}"
