#!/bin/bash

kubectl create namespace gitlab

# Create the secret
kubectl create secret generic dummy-backup-secret \
  --from-literal=config="dummy" \
  -n gitlab

# Then install GitLab
helm install gitlab gitlab/gitlab \
  -f gitlab-min-values.yaml \
  --namespace gitlab \
  --timeout 15m