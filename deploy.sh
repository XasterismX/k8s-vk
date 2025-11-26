#!/bin/bash
# =============================================================================
# Скрипт автоматического развертывания ClickHouse в Kubernetes
# =============================================================================

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция вывода цветного текста
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
if ! kubectl cluster-info &> /dev/null; then
    error "Не удается подключиться к Kubernetes кластеру."
    exit 1
fi

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

# Ожидание готовности пода
info "Ожидание готовности ClickHouse..."
kubectl wait --for=condition=ready pod -l app=clickhouse --timeout=300s

# Вывод статуса
info "Статус развертывания:"
kubectl get pods -l app=clickhouse
kubectl get svc -l app=clickhouse
kubectl get pvc

info "ClickHouse успешно развернут!"
info "Для подключения используйте:"
echo "  kubectl exec -it clickhouse-0 -- clickhouse-client -u admin --password SecurePassword123!"
