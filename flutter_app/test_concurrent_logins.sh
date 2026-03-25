#!/bin/bash

# Test script to simulate 100 concurrent login requests
API_URL="https://script.google.com/macros/s/AKfycbxCSdtFgIjs8kCwELMOjxdaEe3SPHv6tNHU35H7n2poBIRrLFMX442T_EXVeB5llmXp/exec"
TEST_DATA='{"action":"login","code":"test","password":"test"}'
ENCODED_DATA=$(echo "$TEST_DATA" | jq -rR @uri)
CONCURRENT_REQUESTS=100

echo "Starting concurrent login test with $CONCURRENT_REQUESTS requests"
echo "API URL: $API_URL"
echo "Test started at: $(date)"
echo "=================================="

# Create temp directory for results
mkdir -p test_results
rm -f test_results/*

# Function to make a single request
make_request() {
    local id=$1
    local start_time=$(date +%s.%N)
    
    response=$(curl -s -L -w "\nSTATUS:%{http_code}\nTIME:%{time_total}\n" \
        "${API_URL}?data=${ENCODED_DATA}" 2>&1)
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Extract status and response time
    status=$(echo "$response" | grep "STATUS:" | cut -d: -f2)
    api_time=$(echo "$response" | grep "TIME:" | cut -d: -f2)
    body=$(echo "$response" | sed '/STATUS:/d' | sed '/TIME:/d')
    
    # Log results
    echo "Request $id: Status=$status, Time=${api_time}s, Duration=${duration}s" >> test_results/summary.log
    echo "$body" > "test_results/response_$id.json"
    
    # Check for errors
    if [[ "$status" != "200" ]]; then
        echo "Request $id: HTTP ERROR $status" >> test_results/errors.log
    fi
    
    if echo "$body" | grep -q "success.*false"; then
        echo "Request $id: API ERROR - $body" >> test_results/api_errors.log
    fi
    
    echo "[$id] Completed in ${api_time}s (total: ${duration}s)"
}

# Start concurrent requests
echo "Launching $CONCURRENT_REQUESTS concurrent requests..."
for i in $(seq 1 $CONCURRENT_REQUESTS); do
    make_request $i &
done

# Wait for all requests to complete
echo "Waiting for all requests to complete..."
wait

echo "=================================="
echo "Test completed at: $(date)"

# Analyze results
echo ""
echo "RESULTS SUMMARY:"
echo "================"

total_requests=$(wc -l < test_results/summary.log)
echo "Total requests: $total_requests"

# Count successful responses
success_count=$(grep -c "Status=200" test_results/summary.log 2>/dev/null || echo "0")
echo "HTTP 200 responses: $success_count"

# Count API errors
if [[ -f test_results/api_errors.log ]]; then
    api_error_count=$(wc -l < test_results/api_errors.log)
    echo "API errors: $api_error_count"
else
    echo "API errors: 0"
fi

# Count HTTP errors
if [[ -f test_results/errors.log ]]; then
    http_error_count=$(wc -l < test_results/errors.log)
    echo "HTTP errors: $http_error_count"
else
    echo "HTTP errors: 0"
fi

# Calculate response time statistics
if [[ -f test_results/summary.log ]]; then
    echo ""
    echo "RESPONSE TIME ANALYSIS:"
    echo "======================"
    
    # Extract times and calculate stats
    grep "Time=" test_results/summary.log | cut -d= -f3 | cut -d, -f1 | sed 's/s$//' > test_results/times.txt
    
    if [[ -s test_results/times.txt ]]; then
        min_time=$(sort -n test_results/times.txt | head -1)
        max_time=$(sort -n test_results/times.txt | tail -1)
        avg_time=$(awk '{sum+=$1} END {print sum/NR}' test_results/times.txt)
        
        echo "Min response time: ${min_time}s"
        echo "Max response time: ${max_time}s"
        echo "Average response time: ${avg_time}s"
        
        # Count requests that took longer than 10 seconds
        slow_requests=$(awk '$1 > 10 {count++} END {print count+0}' test_results/times.txt)
        echo "Requests > 10s: $slow_requests"
        
        # Count requests that took longer than 30 seconds (timeout territory)
        timeout_requests=$(awk '$1 > 30 {count++} END {print count+0}' test_results/times.txt)
        echo "Requests > 30s: $timeout_requests"
    fi
fi

echo ""
echo "Check test_results/ directory for detailed logs"
echo "=================================="