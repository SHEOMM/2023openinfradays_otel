#!/bin/bash

# Helm 레포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add signoz https://charts.signoz.io
helm repo update

# 네임스페이스 생성
kubectl create namespace metric --dry-run=client -o yaml | kubectl apply -f -

# SigNoz 설치
echo "Installing SigNoz..."
helm upgrade -i signoz signoz/signoz \
  --namespace metric \
  --wait \
  --timeout 20m \
  -f signoz/values.yaml

# SigNoz OTLP 서비스 추가
echo "Creating SigNoz OTLP service..."
kubectl apply -f signoz/service-patch.yaml

# Prometheus 설치
echo "Installing Prometheus..."
helm upgrade -i prometheus prometheus-community/prometheus \
  -f prometheus/values.yaml \
  -n metric

# Grafana 설치
echo "Installing Grafana..."
helm upgrade -i grafana grafana/grafana -n metric

# Loki 설치 (수정된 values 사용)
echo "Installing Loki..."
helm upgrade -i loki grafana/loki \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem \
  --set loki.auth_enabled=false \
  --set singleBinary.replicas=1 \
  --set backend.replicas=0 \
  --set read.replicas=0 \
  --set write.replicas=0 \
  -n metric

# Promtail 설치
echo "Installing Promtail..."
helm upgrade -i promtail grafana/promtail -n metric

# OpenTelemetry Operator 설치 (수정된 설정)
echo "Setting up OpenTelemetry..."
kubectl create namespace otel --dry-run=client -o yaml | kubectl apply -f -
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade -i opentelemetry-operator open-telemetry/opentelemetry-operator \
  -n otel \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true \
  --wait

# OpenTelemetry CRD가 준비될 때까지 대기
echo "Waiting for OpenTelemetry CRDs..."
kubectl wait --for condition=established --timeout=60s crd/instrumentations.opentelemetry.io

# OpenTelemetry Instrumentation CRD 적용
kubectl apply -f otel/crd.yaml

# 애플리케이션 빌드 및 배포
echo "Building and deploying applications..."
cd client
sudo ./gradlew jibDockerBuild
kubectl apply -f kube.yaml

cd ../server
sudo ./gradlew jibDockerBuild
kubectl apply -f kube.yaml

cd ..

echo ""
echo "=== 배포 완료 ==="
echo "SigNoz UI: kubectl port-forward -n metric svc/signoz-frontend 3301:3301"
