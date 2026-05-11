#!/bin/bash

kubectl delete namespace gitlab --ignore-not-found

kubectl create namespace gitlab

# Create the secret
kubectl create secret generic dummy-backup-secret \
  --from-literal=config="dummy" \
  -n gitlab

# Then install GitLab
helm install gitlab gitlab/gitlab \
  -f values.yaml \
  --namespace gitlab \
  --timeout 15m


kubectl apply -f gitlab-ingress.yaml