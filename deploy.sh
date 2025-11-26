#!/bin/bash
# =============================================================================
# Скрипт автоматического развертывания ClickHouse в Kubernetes
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl не найден. Установите kubectl."
    exit 1
fi

# Проверка подключения к кластеру
info "Проверка подключения к Kubernetes кластеру..."
if ! kubectl cluster-info &> /dev/null; then
    error "Не удается подключиться к Kubernetes кластеру."
    echo ""
    echo "Возможные решения:"
    echo "1. Запустите локальный кластер:"
    echo "   minikube start"
    echo "   или"
    echo "   kind create cluster"
    echo ""
    echo "2. Переключите контекст kubectl:"
    echo "   kubectl config get-contexts"
    echo "   kubectl config use-context text-name>"
    echo ""
    echo "3. Проверьте ~/.kube/config"
    exit 1
fi

info "Подключение к кластеру успешно!"
info "Текущий контекст: $(kubectl config current-context)"

# Создание namespace (опционально)
NAMESPACE="default"
info "Используется namespace: $NAMESPACE"

# Создание ConfigMaps
info "Создание ConfigMaps..."
kubectl apply -f configmap-users.yaml
kubectl apply -f configmap-config.yaml

# Создание Service
info "Создание Services..."
kubectl apply -f service.yaml

# Создание StatefulSet
info "Создание StatefulSet..."
kubectl apply -f statefulset.yaml

# Ожидание готовности пода
info "Ожидание готовности ClickHouse (это может занять несколько минут)..."
if kubectl wait --for=condition=ready pod -l app=clickhouse --timeout=300s; then
    info "ClickHouse успешно развернут!"
else
    error "Превышено время ожидания готовности пода."
    warn "Проверьте логи: kubectl logs -l app=clickhouse"
    exit 1
fi

# Вывод статуса
echo ""
info "====== Статус развертывания ======"
kubectl get pods -l app=clickhouse
echo ""
kubectl get svc -l app=clickhouse
echo ""
kubectl get pvc
echo ""

info "====== Команды для подключения ======"
echo "1. Подключение через clickhouse-client:"
echo "   kubectl exec -it clickhouse-0 -- clickhouse-client -u admin --password SecurePassword123!"
echo ""
echo "2. Port-forward для доступа с локальной машины:"
echo "   kubectl port-forward svc/clickhouse-service 9000:9000"
echo "   kubectl port-forward svc/clickhouse-service 8123:8123"
echo ""
echo "3. Проверка версии ClickHouse:"
echo "   kubectl exec clickhouse-0 -- clickhouse-client --query 'SELECT version()'"
