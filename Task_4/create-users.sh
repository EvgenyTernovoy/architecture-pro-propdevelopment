#!/bin/sh
set -e

kubectl create namespace development-tenant

./utils/create-user.sh alice devops-role development-tenant
./utils/create-user.sh bob cluster-pod-reader development-tenant
./utils/create-user.sh sam secret-reader development-tenant