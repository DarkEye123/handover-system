#!/bin/bash

# Simple test runner for handover scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Running handover script tests..."
echo ""

# Run the test suite
bash "$SCRIPT_DIR/test-handovers.sh"