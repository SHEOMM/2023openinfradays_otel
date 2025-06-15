#!/bin/bash

echo "=== SigNoz 상태 확인 ==="
kubectl get pods -n metric | grep signoz

echo -e "\n=== ClickHouse 상태 확인 ==="
kubectl get pods -n metric | grep clickhouse

echo -e "\n=== PVC 상태 확인 ==="
kubectl get pvc -n metric

echo -e "\n=== StorageClass 확인 ==="
kubectl get storageclass

echo -e "\n=== SigNoz 로그 확인 ==="
kubectl logs signoz-0 -n metric --tail=50

echo -e "\n=== ClickHouse 로그 확인 ==="
CLICKHOUSE_POD=$(kubectl get pods -n metric | grep clickhouse | awk '{print $1}' | head -1)
if [ ! -z "$CLICKHOUSE_POD" ]; then
    kubectl logs $CLICKHOUSE_POD -n metric --tail=30
fi

echo -e "\n=== 서비스 확인 ==="
kubectl get svc -n metric | grep signoz
