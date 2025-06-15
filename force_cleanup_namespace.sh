#!/bin/bash

echo "=== 네임스페이스 강제 정리 ==="

# kubectl proxy 시작
kubectl proxy &
PROXY_PID=$!
sleep 3

# Terminating 상태의 네임스페이스 찾기
TERMINATING_NS=$(kubectl get namespace --field-selector=status.phase=Terminating --output=jsonpath="{.items[*].metadata.name}")

for ns in $TERMINATING_NS; do
    echo "강제 정리 중: $ns"

    # finalizers 제거
    kubectl get namespace "$ns" -o json | jq '.spec = {"finalizers": []}' > /tmp/ns-patch.json
    curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/ns-patch.json "http://127.0.0.1:8001/api/v1/namespaces/$ns/finalize"

    # 강제 삭제
    kubectl delete namespace "$ns" --force --grace-period=0 --ignore-not-found=true
done

# proxy 종료
kill $PROXY_PID
rm -f /tmp/ns-patch.json

echo "네임스페이스 정리 완료"
