#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

OPENAPI_YML_PATH="$PROJECT_ROOT/Configs/openapi.yaml"

openapi-generator generate \
  -i "$PROJECT_ROOT/Configs/openapi.yaml" \
  -g swift6 \
  -c "$PROJECT_ROOT/Configs/openapi-generator-config.yaml" \
  -o "$PROJECT_ROOT/Dependencies/API"
