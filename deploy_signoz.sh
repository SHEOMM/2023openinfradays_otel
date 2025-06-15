#!/bin/bash

# Helm 레포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add signoz https://charts.signoz.io
helm repo update

# 네임스페이스 생성
kubectl create namespace metric --dry-run=client -o yaml | kubectl apply -f -

# SigNoz 설치 (OTel Collector 비활성화)
echo "Installing SigNoz without OTel Collector..."
helm upgrade -i signoz signoz/signoz \
  --namespace metric \
  --wait \
  --timeout 20m \
  -f signoz/values.yaml

# SigNoz OTLP 서비스 추가 (직접 수신용)
echo "Creating SigNoz OTLP service..."
kubectl apply -f signoz/service-patch.yaml

# Prometheus 설치
echo "Installing Prometheus..."
helm upgrade -i prometheus prometheus-community/prometheus \
  -f prometheus/values.yaml \
  -n metric

# Grafana 설치 (선택사항)
echo "Installing Grafana..."
helm upgrade -i grafana grafana/grafana -n metric

# Loki와 Promtail 설치
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
echo "=== 서비스 확인 ==="
kubectl get svc -n metric | grep signoz
