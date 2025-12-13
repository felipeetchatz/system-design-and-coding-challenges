# Load Testing & Benchmarking

Scripts for performance testing and simulating production load.

## Requirements

- Ruby (for `benchmark.rb`)
- `wrk` or `ab` (Apache Bench) for HTTP load testing

### Installation

**macOS:**
```bash
brew install wrk
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install wrk
# or
sudo apt-get install apache2-utils  # for ab
```

## Usage

### 1. Ruby Script (Recommended)

Complete test with detailed metrics:

```bash
# With Docker
docker-compose exec web ruby script/benchmark.rb

# Or locally (if server is running)
BASE_URL=http://localhost:3000 ruby script/benchmark.rb
```

The script executes:
- ✅ Create test (100 URLs)
- ✅ Redirect test (1000 requests)
- ✅ Analytics test (100 requests)
- ✅ Mixed load test (simulates real usage)

**Collected metrics:**
- Average, minimum, maximum latency
- Percentiles (p50, p95, p99)
- Throughput (requests/second)
- Success/failure rate

### 2. Tests with wrk (High Performance)

**Redirect (read-heavy):**
```bash
# First, create a URL to test
curl -X POST http://localhost:3000/api/v1/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'

# Then run the benchmark
SHORT_CODE=abc123 bash script/benchmark_redirect.sh
```

**Create (write-heavy):**
```bash
bash script/benchmark_create.sh
```

### 3. Manual Tests with curl

**Create URL:**
```bash
time curl -X POST http://localhost:3000/api/v1/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' \
  -w "\nTime: %{time_total}s\n"
```

**Redirect:**
```bash
time curl -L http://localhost:3000/abc123 \
  -w "\nTime: %{time_total}s\n"
```

**Analytics:**
```bash
time curl http://localhost:3000/api/v1/analytics/abc123 \
  -w "\nTime: %{time_total}s\n"
```

## Performance Requirements (from README)

- ✅ **Redirect**: < 100ms (p95)
- ✅ **Create**: < 200ms (p95)

## Interpreting Results

### Latency
- **p50 (median)**: 50% of requests are faster
- **p95**: 95% of requests are faster (important for SLAs)
- **p99**: 99% of requests are faster (outliers)

### Throughput
- Requests per second the system can process
- Compare with requirements: 1000 reads/sec, 100 writes/sec

### Cache Hit Rate
- Monitor Redis to see cache hit rate:
```bash
docker-compose exec redis redis-cli INFO stats | grep keyspace
```

## Tips

1. **Warm up the cache**: Run some redirects before measuring
2. **Test in isolated environment**: Avoid interference from other processes
3. **Monitor resources**: Use `htop` or `docker stats` during tests
4. **Test gradually**: Start with few connections and increase

## Troubleshooting

**Connection error:**
- Check if server is running: `docker-compose ps`
- Check the URL: `BASE_URL=http://localhost:3000`

**Low performance:**
- Check Rails logs: `docker-compose logs web`
- Check Redis: `docker-compose exec redis redis-cli ping`
- Check PostgreSQL: `docker-compose exec postgres pg_isready`
