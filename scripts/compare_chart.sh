#!/bin/bash

# Usage: ./compare_chart.sh <chart_directory> <release_name> <manifest_url>

# Check if correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <chart_directory> <release_name> <manifest_url>"
    exit 1
fi

CHART_DIR=$1
RELEASE_NAME=$2
MANIFEST_URL=$3

# Define scratch directory and output file names
SCRATCH_DIR="./scratch"
mkdir -p ${SCRATCH_DIR}

CURRENT_YAML="${SCRATCH_DIR}/current-${RELEASE_NAME}.yaml"
LATEST_YAML="${SCRATCH_DIR}/latest-${RELEASE_NAME}.yaml"

# Fetch the latest manifest
curl -o ${LATEST_YAML} ${MANIFEST_URL}
if [ $? -ne 0 ]; then
    echo "Failed to download the manifest from ${MANIFEST_URL}"
    exit 1
fi

# Render the Helm chart
helm template ${RELEASE_NAME} ${CHART_DIR} > ${CURRENT_YAML}
if [ $? -ne 0 ]; then
    echo "Failed to render Helm chart from ${CHART_DIR}"
    exit 1
fi

# Compare the files side by side
diff -y ${CURRENT_YAML} ${LATEST_YAML}

# The files will remain in the scratch directory for review
