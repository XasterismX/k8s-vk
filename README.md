# ClickHouse в Kubernetes

Автоматическое развертывание базы данных ClickHouse в Kubernetes кластере.

## Описание технического решения

Данное решение разворачивает ClickHouse в Kubernetes с использованием StatefulSet для обеспечения стабильной идентификации подов и постоянного хранилища данных.

### Архитектура

- **StatefulSet**: Управляет развертыванием ClickHouse с предсказуемыми именами подов
- **PersistentVolumeClaim**: Обеспечивает постоянное хранение данных БД
- **Service**: Предоставляет стабильную точку доступа к ClickHouse
- **ConfigMap**: Хранит конфигурацию пользователей и настройки ClickHouse

### Особенности

✅ Параметризованная конфигурация через `values.yaml`
✅ Возможность выбора версии ClickHouse
✅ Гибкое управление пользователями и паролями
✅ Persistent storage для сохранения данных
✅ Все файлы содержат подробные комментарии

## Требования

- Kubernetes кластер (версия 1.19+)
- kubectl настроенный для работы с кластером
- Доступное хранилище (StorageClass)

## Установка

### Шаг 1: Настройка параметров

Отредактируйте файл `values.yaml` и укажите:
```
clickhouse:
version: "24.3" # Версия ClickHouse
replicas: 1 # Количество реплик

users:

name: "admin" # Имя пользователя
password: "SecurePassword123!" # Пароль

name: "readonly"
password: "ReadOnlyPass456!"
```

### Шаг 2: Создание namespace (опционально)
```
kubectl create namespace clickhouse
```
### Шаг 3: Применение конфигурации

Применить все манифесты
```
kubectl apply -f configmap-users.yaml
kubectl apply -f configmap-config.yaml
kubectl apply -f pvc.yaml
kubectl apply -f service.yaml
kubectl apply -f statefulset.yaml
```
text

### Шаг 4: Проверка статуса

Проверить статус пода
```kubectl get pods -l app=clickhouse```

Проверить логи
```kubectl logs clickhouse-0```

Проверить сервис
```kubectl get svc clickhouse-service```



## Подключение к ClickHouse

### Из кластера Kubernetes

Подключение через `clickhouse-client`
```
kubectl exec -it clickhouse-0 -- clickhouse-client -u admin --password SecurePassword123!
```


### Извне кластера (port-forward)

Перенаправление порта
```
kubectl port-forward svc/clickhouse-service 9000:9000
```
Подключение с локальной машины
```
clickhouse-client --host localhost --port 9000 -u admin --password SecurePassword123!
```


## Управление пользователями

Для изменения списка пользователей:

1. Отредактируйте `values.yaml`
2. Повторно примените `configmap-users.yaml`
3. Перезапустите под: `kubectl rollout restart statefulset clickhouse`

## Изменение версии ClickHouse

1. Измените параметр `version` в `values.yaml`
2. Примените изменения: `kubectl apply -f statefulset.yaml`
3. Kubernetes выполнит rolling update

## Удаление

Удалить все ресурсы
```
kubectl delete -f statefulset.yaml
kubectl delete -f service.yaml
kubectl delete -f pvc.yaml
kubectl delete -f configmap-config.yaml
kubectl delete -f configmap-users.yaml
```

⚠️ **Внимание**: PVC с данными останется. Для полного удаления выполните:
```
kubectl delete pvc data-clickhouse-0
```


## Масштабирование

Для увеличения количества реплик:
```
kubectl scale statefulset clickhouse --replicas=3
```

## Мониторинг

Проверка здоровья ClickHouse:
```
kubectl exec clickhouse-0 -- clickhouse-client --query "SELECT version()"
kubectl exec clickhouse-0 -- clickhouse-client --query "SELECT * FROM system clusters"
```

## Troubleshooting

### Под не запускается
```
kubectl describe pod clickhouse-0
kubectl logs clickhouse-0
```

### Проблемы с хранилищем
```
kubectl get pvc
kubectl describe pvc data-clickhouse-0
```


## Структура портов

- **9000**: Native protocol (TCP)
- **8123**: HTTP interface
- **9009**: Interserver HTTP