#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:-}"
IMAGE_TAG="${2:-}"

if [[ -z "$ENVIRONMENT" || -z "$IMAGE_TAG" ]]; then
    echo "Usage: $0 <dev|prod> <image-tag>"
    exit 1
fi

case "$ENVIRONMENT" in
    dev|prod)
        ;;
    *)
        echo "Invalid environment: $ENVIRONMENT"
        echo "Expected: dev or prod"
        exit 1
        ;;
esac

RELEASE="cicd-platform-${ENVIRONMENT}"
VALUES_FILE="helm/cicd-platform/values-${ENVIRONMENT}.yaml"

echo "Deploying ${RELEASE}"
echo "Image tag: ${IMAGE_TAG}"

helm upgrade --install "$RELEASE" helm/cicd-platform \
    -f helm/cicd-platform/values.yaml \
    -f "$VALUES_FILE" \
    --set "image.tag=${IMAGE_TAG}"

echo "Waiting for deployment rollout..."

kubectl rollout status \
    "deployment/${RELEASE}" \
    --timeout=120s

echo "Deployment successful."

kubectl get deployment "$RELEASE"
kubectl get pods -l "app.kubernetes.io/instance=${RELEASE}"
