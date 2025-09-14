#!/bin/bash
set -e

# Полное удаление старого minikube
echo "Deleting existing minikube cluster..."
minikube delete

# Запуск нового minikube
echo "Starting minikube..."
minikube start

# Создание namespace audit-zone
echo "Creating audit-zone namespace..."
kubectl apply -f ./01-create-namespace.yaml

# Установка Gatekeeper
echo "Installing OPA Gatekeeper..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.15.0/deploy/gatekeeper.yaml

echo "Waiting for Gatekeeper pods to be created..."
NAMESPACE=gatekeeper-system

# Ждём, пока namespace и хотя бы один pod появятся
while true; do
  PODS=$(kubectl get pods -n $NAMESPACE --ignore-not-found)
  if [ -n "$PODS" ]; then
    echo "Gatekeeper pods found."
    break
  fi
  echo "No Gatekeeper pods yet, waiting 5s..."
  sleep 5
done

# Теперь ждём готовность всех подов
echo "Waiting for all Gatekeeper pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s


# Применение ConstraintTemplates
echo "Applying Gatekeeper ConstraintTemplates..."
kubectl apply -f ./gatekeeper/constraint-templates/ --recursive

for crd in k8spspprivileged k8spsphostpath k8spsprunasnonroot; do
  echo "Waiting for CRD $crd..."
  until kubectl get crd ${crd}.constraints.gatekeeper.sh &> /dev/null; do
    sleep 2
  done
done

# Применение Constraints
echo "Applying Gatekeeper Constraints..."
kubectl apply -f ./gatekeeper/constraints/ --recursive

echo "Applying insecure manifests and showing all errors..."

# Проходим по всем yaml-файлам рекурсивно
for file in $(find ./insecure-manifests/ -type f -name "*.yaml"); do
  echo "Applying $file..."
  if ! kubectl apply -f "$file"; then
    echo "❌ Error applying $file"
  fi
done

echo "All done!"
