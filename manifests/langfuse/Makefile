.PHONY: help generate build deploy delete secrets

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

secrets: ## Create required secrets in Kubernetes
	@echo "Creating secrets..."
	@./scripts/create-secrets.sh

generate: ## Generate all.yaml from Helm chart
	@echo "Generating Kubernetes manifests from Helm chart..."
	cd base && helm template langfuse langfuse/langfuse -f values.yaml > all.yaml
	@echo "✓ Generated base/all.yaml"

build: ## Build kustomization (dry-run)
	@echo "Building kustomization..."
	kubectl kustomize base

deploy: generate ## Generate and deploy to Kubernetes
	@echo "Deploying Langfuse..."
	kubectl apply -k base
	@echo "✓ Deployed successfully"

delete: ## Delete Langfuse from Kubernetes
	@echo "Deleting Langfuse..."
	kubectl delete -k base
	@echo "✓ Deleted successfully"

status: ## Show deployment status
	@echo "Langfuse deployment status:"
	@kubectl get pods,svc,ingress -n langfuse -l app.kubernetes.io/name=langfuse

logs: ## Show logs from Langfuse pods
	@kubectl logs -n langfuse -l app.kubernetes.io/name=langfuse --tail=100 -f
