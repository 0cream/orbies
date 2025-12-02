#!/bin/bash

# Default values
MODULE_PATH=""
ROOT_MODULE_NAME=""

# Parse named arguments
while getopts "p:r:h" opt; do
    case $opt in
        p) MODULE_PATH="$OPTARG" ;;
        r) ROOT_MODULE_NAME="$OPTARG" ;;
        h) 
            echo "Usage: $0 -p <module_path> -r <root_module_name>"
            echo "Example: $0 -p 'Biometrics/Selfie' -r 'Instruction'"
            exit 0
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$MODULE_PATH" ] || [ -z "$ROOT_MODULE_NAME" ]; then
    echo "Error: Both module path (-p) and root module name (-r) are required"
    echo "Use -h for help"
    exit 1
fi

# Extract module name from path
MODULE_NAME=$(basename "$MODULE_PATH")

# Generate root name by combining module name and root module name
ROOT_NAME="${MODULE_NAME}${ROOT_MODULE_NAME}"

# Convert root module name to camel case (first letter lowercase)
ROOT_CAMEL_CASE_NAME=$(echo "${ROOT_MODULE_NAME:0:1}" | tr '[:upper:]' '[:lower:]')${ROOT_MODULE_NAME:1}

# Generate coordinator using Tuist
tuist scaffold coordinator \
    --module_path "$MODULE_PATH" \
    --name "$MODULE_NAME" \
    --root_name="$ROOT_NAME" \
    --root_camel_case_name="$ROOT_CAMEL_CASE_NAME"