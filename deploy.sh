#!/bin/bash
# =============================================================================
# Скрипт автоматического развертывания ClickHouse в Kubernetes
# =============================================================================

set -e

GREEN='\033[0;32m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

info "Начинаем развертывание ClickHouse..."

# Создание ConfigMaps
info "Создание ConfigMaps..."
kubectl apply -f configmap-users.yaml
kubectl apply -f configmap-config.yaml


# Создание Service
info "Создание Service..."
kubectl apply -f service.yaml

# Создание StatefulSet
info "Создание StatefulSet..."
kubectl apply -f statefulset.yaml

# Ожидание готовности
info "Ожидание готовности ClickHouse..."
kubectl wait --for=condition=ready pod -l app=clickhouse --timeout=300s

info "Развертывание завершено!"
kubectl get pods,svc,pvc -l app=clickhouse
