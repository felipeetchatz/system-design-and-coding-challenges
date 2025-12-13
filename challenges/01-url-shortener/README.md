# Challenge 1: URL Shortener (TinyURL/bit.ly)

## Problem Statement

Design a URL shortener service that can convert long URLs into short, shareable links. The service should be able to handle millions of requests per day and provide basic analytics.

## Documentation Structure

- **Design:** See [`design.md`](./design.md) for the complete system design, architecture, and implementation decisions
- **Implementation:** Code implementation will be located in [`implementation/`](./implementation/) directory
- **Notes:** See [`notes.md`](./notes.md) for learnings and concepts from "Designing Data-Intensive Applications"

## Functional Requirements

1. **URL Shortening**
   - Given a long URL, generate a shorter unique alias
   - Short URLs should be 6 characters long (Base62 encoding)
   - Short URLs should be unique and collision-free

2. **URL Redirection**
   - When a short URL is accessed, redirect to the original long URL
   - Handle invalid/non-existent short URLs gracefully

3. **Analytics**
   - Track click counts for each short URL
   - Record timestamps of accesses
   - Provide basic statistics

## Non-Functional Requirements

1. **Scalability**
   - Handle 100 million URLs
   - Support 1000 requests per second (read-heavy)
   - Support 100 requests per second (write-heavy)

2. **Availability**
   - 99.9% uptime
   - Handle system failures gracefully

3. **Performance**
   - URL redirection should be fast (< 100ms)
   - URL shortening should be fast (< 200ms)

4. **Durability**
   - No data loss
   - URLs should persist even after system restarts

## Constraints and Assumptions

- Short URLs should be 6 characters long (Base62: a-z, A-Z, 0-9)
- 6 characters provide 56.8 billion possible URLs (sufficient for 100 million requirement)
- Original URLs can be up to 2048 characters
- System should handle both HTTP and HTTPS URLs

## Out of Scope (for MVP)

- User authentication and authorization
- Custom short URLs
- URL expiration and deletion
- Advanced analytics and reporting
- URL preview/metadata

## Success Metrics

- Low latency for URL redirection
- High availability
- Ability to scale horizontally
- Minimal storage requirements

## Load Testing & Performance Validation

The implementation includes comprehensive load testing scripts to validate performance requirements and simulate production traffic patterns.

### Available Scripts

All load testing scripts are located in [`implementation/script/`](./implementation/script/):

1. **`benchmark.rb`** - Comprehensive Ruby script for detailed performance metrics
   - Tests create, redirect, and analytics endpoints
   - Collects latency (p50, p95, p99), throughput, and success rates
   - Supports mixed load testing to simulate real-world usage

2. **`benchmark_redirect.sh`** - High-performance redirect endpoint testing using `wrk`
   - Automatically creates test URLs if needed
   - Tests redirect performance under high load

3. **`benchmark_create.sh`** - High-performance create endpoint testing using `wrk`
   - Generates dynamic URLs for each request
   - Tests write performance under high load

4. **`wrk_create.lua`** - Lua script for dynamic POST requests with `wrk`

### Quick Start

```bash
# Navigate to implementation directory
cd implementation

# Run comprehensive benchmark (recommended)
docker-compose exec web ruby script/benchmark.rb

# Run high-performance redirect test
bash script/benchmark_redirect.sh

# Run high-performance create test
bash script/benchmark_create.sh
```

### Performance Results

Current performance metrics (validated with load testing scripts):

- **Redirect**: p95 = 14.79ms (well below 100ms requirement) ✅
- **Create**: p95 = 14.08ms (well below 200ms requirement) ✅
- **Analytics**: p95 = 5.83ms (excellent performance) ✅

For detailed usage instructions, performance requirements, and troubleshooting, see [`implementation/script/README.md`](./implementation/script/README.md).

