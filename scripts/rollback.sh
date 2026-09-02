#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:-}"
TARGET_REVISION="${2:-}"

if [[ -z "$ENVIRONMENT" || -z "$TARGET_REVISION" ]]; then
    echo "Usage: $0 <dev|prod> <revision>"
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

if ! [[ "$TARGET_REVISION" =~ ^[0-9]+$ ]]; then
    echo "Invalid revision: $TARGET_REVISION"
    echo "Revision must be a positive integer."
    exit 1
fi

if [[ "$TARGET_REVISION" -lt 1 ]]; then
    echo "Invalid revision: $TARGET_REVISION"
    exit 1
fi

RELEASE="cicd-platform-${ENVIRONMENT}"

echo "Release: ${RELEASE}"
echo "Target revision: ${TARGET_REVISION}"

helm rollback "$RELEASE" "$TARGET_REVISION"

echo "Waiting for deployment rollout..."

kubectl rollout status \
    "deployment/${RELEASE}" \
    --timeout=120s

echo "Rollback successful."

echo "Current image:"
kubectl get deployment "$RELEASE" \
    -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

echo "Current pods:"
kubectl get pods -l "app.kubernetes.io/instance=${RELEASE}"
