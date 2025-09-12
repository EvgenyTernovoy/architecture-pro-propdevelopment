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

echo "Applying PodSecurity Admission..."
kubectl label namespace audit-zone \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted \
  --overwrite

# Ждём, пока появится default ServiceAccount
echo "Waiting for default ServiceAccount in audit-zone..."
until kubectl get sa default -n audit-zone &> /dev/null; do
  echo "default ServiceAccount not yet created, waiting..."
  sleep 2
done
echo "✅ default ServiceAccount is ready."

echo "Applying insecure manifests and showing all errors..."
# Проходим по всем yaml-файлам рекурсивно
for file in $(find ./insecure-manifests/ -type f -name "*.yaml"); do
  echo "Applying $file..."
  if ! kubectl apply -f "$file"; then
    echo "❌ Error applying $file"
  fi
done

echo "All done!"
