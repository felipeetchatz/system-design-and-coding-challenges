#!/bin/bash
# Benchmark script for redirect endpoint using wrk or ab

BASE_URL="${BASE_URL:-http://localhost:3000}"
SHORT_CODE="${SHORT_CODE:-}"

# If SHORT_CODE is not provided, create one automatically
if [ -z "$SHORT_CODE" ]; then
  echo "📝 No SHORT_CODE provided. Creating a new URL..."
  RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/shorten" \
    -H "Content-Type: application/json" \
    -d '{"url":"https://example.com/benchmark"}')
  
  if [ $? -eq 0 ] && echo "$RESPONSE" | grep -q "short_url"; then
    # Extract short_code from response (e.g., "http://localhost:3000/abc123" -> "abc123")
    SHORT_CODE=$(echo "$RESPONSE" | grep -o '"short_url":"[^"]*"' | cut -d'"' -f4 | sed 's|.*/||' | sed 's|"$||')
    if [ -n "$SHORT_CODE" ] && [ ${#SHORT_CODE} -eq 6 ]; then
      echo "✅ Created URL with short_code: ${SHORT_CODE}"
    else
      echo "❌ Failed to extract valid short_code from response"
      exit 1
    fi
  else
    echo "❌ Failed to create URL. Please provide SHORT_CODE manually."
    exit 1
  fi
fi

echo "🔄 Benchmarking Redirect Endpoint"
echo "URL: ${BASE_URL}/${SHORT_CODE}"
echo ""

# Check if wrk is available
if command -v wrk &> /dev/null; then
    echo "Using wrk..."
    wrk -t4 -c100 -d30s --timeout 2s "${BASE_URL}/${SHORT_CODE}"
elif command -v ab &> /dev/null; then
    echo "Using Apache Bench..."
    ab -n 10000 -c 100 "${BASE_URL}/${SHORT_CODE}"
else
    echo "❌ Neither wrk nor ab found. Please install one:"
    echo "  - wrk: brew install wrk (macOS) or apt-get install wrk (Linux)"
    echo "  - ab: Usually comes with Apache httpd"
    exit 1
fi
