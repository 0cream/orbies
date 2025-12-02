#!/bin/bash

# Default values
MODULE_PATH=""
MODULE_NAME=""

# Parse named arguments
while getopts "p:n:h" opt; do
    case $opt in
        p) MODULE_PATH="$OPTARG" ;;
        n) MODULE_NAME="$OPTARG" ;;
        h) 
            echo "Usage: $0 -p <module_path> [-n <name>]"
            echo "Example with automatic name: $0 -p 'Biometrics/Selfie/Instruction'"
            echo "Example with custom name: $0 -p 'Biometrics/Selfie/Instruction' -n 'CustomName'"
            exit 0
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Check if module path is provided
if [ -z "$MODULE_PATH" ]; then
    echo "Error: Module path (-p) is required"
    echo "Use -h for help"
    exit 1
fi

# Generate module name if not provided
if [ -z "$MODULE_NAME" ]; then
    LAST_COMPONENT=$(basename "$MODULE_PATH")
    PARENT_COMPONENT=$(basename "$(dirname "$MODULE_PATH")")
    MODULE_NAME="${PARENT_COMPONENT}${LAST_COMPONENT}"
fi

# Generate module using Tuist
tuist scaffold module \
    --module_path "$MODULE_PATH" \
    --name "$MODULE_NAME"
