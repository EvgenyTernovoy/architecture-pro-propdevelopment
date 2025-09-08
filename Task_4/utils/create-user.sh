#!/bin/sh
set -e

USER="$1"
ROLE="$2"
NAMESPACE="${3:-default}"

if [ -z "$USER" ] || [ -z "$ROLE" ]; then
  echo "Usage: $0 <username> <role> [namespace]"
  exit 1
fi

CERTS_DIR="./certs"
mkdir -p "$CERTS_DIR"

echo "==> Generating certs for $USER"

# генерируем ключ и CSR
openssl genrsa -out "$CERTS_DIR/${USER}.key" 2048
openssl req -new -key "$CERTS_DIR/${USER}.key" -out "$CERTS_DIR/${USER}.csr" -subj "/CN=${USER}/O=${USER}-group"

# подписываем через CA minikube
minikube ssh "sudo cat /var/lib/minikube/certs/ca.crt" > "$CERTS_DIR/ca.crt"
minikube ssh "sudo cat /var/lib/minikube/certs/ca.key" > "$CERTS_DIR/ca.key"

openssl x509 -req -in "$CERTS_DIR/${USER}.csr" \
  -CA "$CERTS_DIR/ca.crt" \
  -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERTS_DIR/${USER}.crt" -days 365

# добавляем пользователя в kubeconfig
kubectl config set-credentials "$USER" \
  --client-certificate="$CERTS_DIR/${USER}.crt" \
  --client-key="$CERTS_DIR/${USER}.key"

kubectl config set-context "${USER}@minikube" \
  --cluster=minikube \
  --namespace="$NAMESPACE" \
  --user="$USER"

# создаём роль/биндинг
BINDING_NAME="${USER}-${ROLE}-binding"

if [ "$NAMESPACE" = "cluster" ]; then
  echo "==> Creating ClusterRoleBinding for $USER with role $ROLE"
  kubectl create clusterrolebinding "$BINDING_NAME" \
    --clusterrole="$ROLE" \
    --user="$USER" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "==> Creating RoleBinding for $USER with role $ROLE in namespace $NAMESPACE"
  kubectl create rolebinding "$BINDING_NAME" \
    --clusterrole="$ROLE" \
    --user="$USER" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo "==> User $USER created with role $ROLE in namespace $NAMESPACE"
echo "Switch context: kubectl config use-context ${USER}@minikube"
