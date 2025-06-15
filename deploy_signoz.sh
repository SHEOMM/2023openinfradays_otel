#!/bin/bash

# Helm 레포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add signoz https://charts.signoz.io
helm repo update

# 네임스페이스 생성
kubectl create namespace metric --dry-run=client -o yaml | kubectl apply -f -

# 스토리지 클래스 확인 (필요시 values.yaml에서 수정)
echo "Available storage classes:"
kubectl get storageclass

# SigNoz 설치 (Tempo 대신)
echo "Installing SigNoz..."
helm upgrade -i signoz signoz/signoz \
  --namespace metric \
  --wait \
  --timeout 20m \
  -f signoz/value.yaml

# Prometheus 설치 (SigNoz 연동 설정 포함)
echo "Installing Prometheus..."
helm upgrade -i prometheus prometheus-community/prometheus \
  -f prometheus/values.yaml \
  -n metric

# Grafana 설치 (선택사항 - SigNoz UI 사용 가능)
echo "Installing Grafana..."
helm upgrade -i grafana grafana/grafana -n metric

# Loki와 Promtail 설치 (로그 수집용)
echo "Installing Loki and Promtail..."
helm upgrade -i -f loki/values.yaml loki grafana/loki -n metric
helm upgrade -i promtail grafana/promtail -n metric

# OpenTelemetry Operator 설치
echo "Setting up OpenTelemetry..."
kubectl create namespace otel --dry-run=client -o yaml | kubectl apply -f -
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade -i opentelemetry-operator open-telemetry/opentelemetry-operator \
  -n otel \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert=true \
  --wait

# OpenTelemetry Instrumentation CRD 적용
kubectl apply -f otel/crd.yaml

# 애플리케이션 빌드 및 배포
echo "Building and deploying client application..."
cd client
sudo ./gradlew jibDockerBuild
kubectl apply -f kube.yaml

echo "Building and deploying server application..."
cd ../server
sudo ./gradlew jibDockerBuild
kubectl apply -f kube.yaml

cd ..

# 접속 정보 출력
echo ""
echo "=== 접속 정보 ==="
echo "SigNoz UI: kubectl port-forward -n metric svc/signoz-frontend 3301:3301"
echo "SigNoz URL: http://localhost:3301"
echo ""
echo "Grafana: kubectl port-forward -n metric svc/grafana 7777:80"
echo "Grafana admin password:"
kubectl get secret --namespace metric grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo ""
