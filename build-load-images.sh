#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KIND_CLUSTER="${KIND_CLUSTER:-toggle-master}"
MICROSERVICES_DIR="$REPO_ROOT/toggle-master/microsservices"

if ! command -v docker >/dev/null 2>&1 || ! command -v kind >/dev/null 2>&1; then
  echo "Erro: este script precisa de docker e kind instalados." >&2
  exit 1
fi

if ! kind get clusters | grep -Fxq "$KIND_CLUSTER"; then
  echo "Erro: cluster Kind '$KIND_CLUSTER' não encontrado." >&2
  echo "Clusters disponíveis:" >&2
  kind get clusters >&2
  exit 1
fi

for name in auth evaluation flag targeting analytics; do
  image="${name}-service:latest"
  context="$MICROSERVICES_DIR/${name}-service-main"

  if [[ ! -f "$context/Dockerfile" ]]; then
    echo "Erro: Dockerfile não encontrado em $context" >&2
    exit 1
  fi

  echo "Construindo $image..."
  docker build -t "$image" "$context"

  echo "Carregando $image no cluster $KIND_CLUSTER..."
  kind load docker-image "$image" --name "$KIND_CLUSTER"
done

echo "Build e carregamento das imagens concluídos."