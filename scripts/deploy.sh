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
LOCAL_PORT=18000

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

echo "Deployment rollout successful."

kubectl get deployment "$RELEASE"

echo "Running pods:"
kubectl get pods -l "app.kubernetes.io/instance=${RELEASE}"

echo "Starting temporary port-forward..."

kubectl port-forward \
    "service/${RELEASE}" \
    "${LOCAL_PORT}:8000" >/tmp/cicd-platform-port-forward.log 2>&1 &

PORT_FORWARD_PID=$!

cleanup() {
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
}

trap cleanup EXIT

echo "Checking application health..."

for attempt in {1..10}; do
    if curl --fail --silent --show-error \
        "http://127.0.0.1:${LOCAL_PORT}/health"; then
        echo
        echo "Application health check passed."
        echo "Deployment verification successful."
        exit 0
    fi

    echo "Health check attempt ${attempt}/10 failed. Retrying..."
    sleep 2
done

echo "Application health check failed."
exit 1
