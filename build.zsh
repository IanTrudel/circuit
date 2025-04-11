#!/usr/bin/zsh
set -euo pipefail

GHUSERNAME=iantrudel
REPO=circuit
REGISTRY=ghcr.io/$GHUSERNAME/$REPO
DOCKER_AUTH=0

[[ -f .env ]] && source .env

# Authenticate to GHCR (requires PAT with write:packages)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
   echo "$GITHUB_TOKEN" | docker login ghcr.io -u $GHUSERNAME --password-stdin
   DOCKER_AUTH=1
fi

function build_step() {
   local name=$1
   local file=$2

   docker build -f "$file" --label "${REPO}.build=${name}" -t "${REGISTRY}:${name}" .

   if (( DOCKER_AUTH )); then
      docker push "${REGISTRY}:${name}"
   fi
}

build_step googletest Workflow/Dockerfile.googletest
build_step slang Workflow/Dockerfile.slang
build_step circt Workflow/Dockerfile.circt
build_step circuit Workflow/Dockerfile.circuit

docker image prune --filter "label=${REPO}.build" --filter "dangling=true" -f
