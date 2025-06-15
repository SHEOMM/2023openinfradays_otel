#!/bin/bash

echo "=== OpenTelemetry 모니터링 스택 정리 시작 ==="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수 정의
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 애플리케이션 정리
print_status "애플리케이션 정리 중..."
kubectl delete -f client/kube.yaml --ignore-not-found=true
kubectl delete -f server/kube.yaml --ignore-not-found=true

# OpenTelemetry Operator 및 CRD 정리
print_status "OpenTelemetry 설정 정리 중..."
kubectl delete -f otel/crd.yaml --ignore-not-found=true
helm uninstall opentelemetry-operator -n otel --ignore-not-found

# SigNoz 정리
print_status "SigNoz 정리 중..."
kubectl delete -f signoz/service-patch.yaml --ignore-not-found=true
helm uninstall signoz -n metric --ignore-not-found

# 모니터링 스택 정리
print_status "Prometheus 정리 중..."
helm uninstall prometheus -n metric --ignore-not-found

print_status "Grafana 정리 중..."
helm uninstall grafana -n metric --ignore-not-found

print_status "Loki 정리 중..."
helm uninstall loki -n metric --ignore-not-found

print_status "Promtail 정리 중..."
helm uninstall promtail -n metric --ignore-not-found

# PVC 정리 (데이터 완전 삭제)
print_warning "PVC(영구 볼륨) 정리 중... 데이터가 완전히 삭제됩니다."
read -p "PVC를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete pvc --all -n metric --ignore-not-found=true
    kubectl delete pvc --all -n otel --ignore-not-found=true
    print_status "PVC 삭제 완료"
else
    print_warning "PVC 삭제를 건너뛰었습니다."
fi

# PV 정리 (필요시)
print_status "PV(영구 볼륨) 확인 중..."
PVS=$(kubectl get pv --no-headers 2>/dev/null | grep -E "(metric|otel)" | awk '{print $1}')
if [ ! -z "$PVS" ]; then
    print_warning "관련 PV가 발견되었습니다:"
    echo "$PVS"
    read -p "PV를 삭제하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$PVS" | xargs kubectl delete pv --ignore-not-found=true
        print_status "PV 삭제 완료"
    else
        print_warning "PV 삭제를 건너뛰었습니다."
    fi
fi

# 네임스페이스 정리
print_status "네임스페이스 정리 중..."
kubectl delete namespace metric --ignore-not-found=true
kubectl delete namespace otel --ignore-not-found=true

# Docker 이미지 정리 (선택사항)
print_warning "로컬 Docker 이미지 정리"
read -p "애플리케이션 Docker 이미지를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi spring-client:latest --force 2>/dev/null || true
    docker rmi spring-server:latest --force 2>/dev/null || true
    print_status "Docker 이미지 삭제 완료"
else
    print_warning "Docker 이미지 삭제를 건너뛰었습니다."
fi

# Helm 레포지토리 정리 (선택사항)
print_warning "Helm 레포지토리 정리"
read -p "추가된 Helm 레포지토리를 제거하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    helm repo remove prometheus-community 2>/dev/null || true
    helm repo remove grafana 2>/dev/null || true
    helm repo remove signoz 2>/dev/null || true
    helm repo remove open-telemetry 2>/dev/null || true
    print_status "Helm 레포지토리 제거 완료"
else
    print_warning "Helm 레포지토리 제거를 건너뛰었습니다."
fi

# 정리 상태 확인
print_status "정리 상태 확인 중..."

echo ""
echo "=== 남은 리소스 확인 ==="
echo "Pods in metric namespace:"
kubectl get pods -n metric 2>/dev/null || echo "namespace 'metric' not found"

echo ""
echo "Pods in otel namespace:"
kubectl get pods -n otel 2>/dev/null || echo "namespace 'otel' not found"

echo ""
echo "Helm releases:"
helm list -A | grep -E "(signoz|prometheus|grafana|loki|promtail|opentelemetry)" || echo "관련 Helm release 없음"

echo ""
echo "PVCs:"
kubectl get pvc -A | grep -E "(metric|otel)" || echo "관련 PVC 없음"

echo ""
echo "PVs:"
kubectl get pv | grep -E "(metric|otel)" || echo "관련 PV 없음"

echo ""
print_status "=== 정리 완료 ==="
print_warning "참고: 일부 리소스는 완전히 정리되는데 시간이 걸릴 수 있습니다."
