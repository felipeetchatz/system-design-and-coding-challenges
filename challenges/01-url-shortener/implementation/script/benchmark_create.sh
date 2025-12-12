#!/bin/bash
# Benchmark script for create endpoint

BASE_URL="${BASE_URL:-http://localhost:3000}"

echo "📝 Benchmarking Create Endpoint"
echo "URL: ${BASE_URL}/api/v1/shorten"
echo ""

# Create a JSON file for the request
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" <<EOF
{"url":"https://example.com/test/benchmark"}
EOF

# Check if wrk is available
if command -v wrk &> /dev/null; then
    echo "Using wrk..."
    wrk -t4 -c50 -d30s --timeout 5s \
        -s script/wrk_create.lua \
        "${BASE_URL}/api/v1/shorten"
elif command -v ab &> /dev/null; then
    echo "Using Apache Bench..."
    ab -n 1000 -c 50 -p "$TMP_FILE" -T application/json \
       "${BASE_URL}/api/v1/shorten"
else
    echo "❌ Neither wrk nor ab found."
    exit 1
fi

rm "$TMP_FILE"

