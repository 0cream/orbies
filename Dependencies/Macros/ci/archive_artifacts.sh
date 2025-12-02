#!/bin/bash

# Configuration
ARTIFACT_NAMES=("DependencyMacros-tool")
BUILD_CONFIG="release" # Use "debug" for development builds
PACKAGE_DIR="."
ARTIFACTS_OUTPUT_DIR="$PACKAGE_DIR/Artifacts"

echo "|================================================|"
echo "|              [ BUILDING PACKAGE ]              |"
echo "|================================================|"

echo "Building Swift package in '$BUILD_CONFIG' mode..."
swift build -c $BUILD_CONFIG

# Check if the build command was successful
if [ $? -ne 0 ]; then
    echo "Swift build failed. Aborting."
    exit 1
fi
echo "Build successful."

echo "|=================================================|"
echo "|              [ COPYING ARTIFACTS ]              |"
echo "|=================================================|"

MISSING_ARTIFACTS=()
COPY_FAILED_EXECUTABLES=()
COPIED_EXECUTABLES=()

for ARTIFACT_NAME in "${ARTIFACT_NAMES[@]}"; do
  EXECUTABLE_NAME=${ARTIFACT_NAME%-tool}
  ARTIFACT_PATH="$PACKAGE_DIR/.build/$BUILD_CONFIG/$ARTIFACT_NAME"
  
  # Check if the executable exists at the source path
  if [ ! -f "$ARTIFACT_PATH" ]; then
      echo "Error: Executable '$ARTIFACT_NAME' not found at '$ARTIFACT_PATH'."
      echo "Please check ARTIFACT_NAMES in the script and your Package.swift file."
      MISSING_ARTIFACTS+=("$ARTIFACT_NAME")
      continue
  fi
  
  # Step 2: Copy the executable to the Artifacts directory
  DESTINATION_PATH="$ARTIFACTS_OUTPUT_DIR/$EXECUTABLE_NAME"
  
  # Create Artifacts directory if it doesn't exist
  mkdir -p "$ARTIFACTS_OUTPUT_DIR"
  
  echo "Copying executable from '$ARTIFACT_PATH' to '$DESTINATION_PATH'..."
  cp "$ARTIFACT_PATH" "$DESTINATION_PATH"
  
  if [ $? -ne 0 ]; then
    COPY_FAILED_EXECUTABLES+=("$EXECUTABLE_NAME")
    echo "Failed to copy the executable. Aborting."
  else
    COPIED_EXECUTABLES+=("$EXECUTABLE_NAME")
    echo "$EXECUTABLE_NAME copied."
  fi
done

echo "|=================================================|"
echo "|            [ REMOVING DERIVED DATA ]            |"
echo "|=================================================|"

chmod +x ./ci/remove_derived_data.sh && source ./ci/remove_derived_data.sh

echo "|=================================================|"
echo "|                  [ COMPLETED ]                  |"
echo "|=================================================|"

if [ ${#MISSING_ARTIFACTS[@]} -ne 0 ]; then
  echo "There are '${#MISSING_ARTIFACTS[@]}' missing artifacts: '${MISSING_ARTIFACTS}'"
fi

if [ ${#COPY_FAILED_EXECUTABLES[@]} -ne 0 ]; then
  echo "There are '${#COPY_FAILED_EXECUTABLES[@]}' executables that failed to be copied: '${COPY_FAILED_EXECUTABLES}'"
fi

echo "You can find '$COPIED_EXECUTABLES' in '$ARTIFACTS_OUTPUT_DIR'"
