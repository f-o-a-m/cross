#!/usr/bin/env bash

set -x
set -euo pipefail

cd docker

run() {
  local dockerfile="Dockerfile.${1}"
  local image_name="rustembedded/cross:${1}"

  if docker pull "${image_name}"; then
    local cache_from_args=(--cache-from "${image_name}")
  fi

  docker build ${cache_from_args[@]} --pull -t "${image_name}" -f "${dockerfile}" .

  local version="$(cargo metadata --format-version 1 | jq --raw-output '.packages[] | select(.name == "cross") | .version')"

  if ! [[ "${version}" =~ alpha ]] && ! [[ "${version}" =~ dev ]]; then
    local versioned_image_name="${image_name}-${version}"
    docker tag "${image_name}" "${versioned_image_name}"
  fi
}

if [ -z "${1}" ]; then
  for t in Dockerfile.*; do
    run "${t##Dockerfile.}"
  done
else
  run "${1}"
fi
