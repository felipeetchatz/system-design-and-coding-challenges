# Notes and Learnings: URL Shortener

## Key Concepts from "Designing Data-Intensive Applications"

### 1. Reliability, Scalability, and Maintainability

- **Reliability:** Handle failures gracefully (database, cache, network)
- **Scalability:** Design for horizontal scaling from the start
- **Maintainability:** Clear architecture, good monitoring

### 2. Data Models

**SQL (PostgreSQL) - Our Choice:**
- ACID transactions (critical for unique short codes)
- Strong consistency (important for analytics)
- Good for read-heavy workloads (10:1 read/write ratio)

### 3. Storage and Indexing

- Index on `short_code` for fast lookups
- PostgreSQL indexes are optimized for read-heavy workloads
- Essential for meeting < 100ms redirect latency requirement

### 4. Encoding

**Base62 Encoding:**
- Characters: a-z, A-Z, 0-9 (62 total)
- **6 characters** = 56.8 billion possible URLs
- URL-safe and human-readable

### 5. Replication

**Primary-Replica (Our Choice):**
- Primary handles writes (URL creation)
- Replicas handle reads (redirects)
- Improves read scalability for our read-heavy workload

### 6. Partitioning

**Hash-based (Our Choice):**
- Even distribution across partitions
- Avoids hot spots
- No range queries needed (always lookup by exact `short_code`)

### 7. Transactions

- Short code generation must be atomic
- Prevents duplicate short codes
- PostgreSQL ACID guarantees handle this

### 8. Consistency

**Strong Consistency (Our Choice):**
- All reads see latest data
- Important for accurate analytics
- Acceptable latency for our scale

## Design Decisions

### Why PostgreSQL?
- Read-heavy workload (1000 reads/sec vs 100 writes/sec)
- Need strong consistency for analytics
- ACID transactions ensure unique short codes
- Can scale with read replicas

### Why Counter-based Short Codes?
- Guaranteed uniqueness (no collision handling needed)
- Simple implementation
- Database sequence provides atomicity

### Why Cache (Redis)?
- 80-20 rule: 20% of URLs get 80% of traffic
- Reduces database load significantly
- Cache-aside pattern fits read-heavy workload
- **Cache TTL Strategy:** Popular URLs (click_count > 100) get 24h TTL, regular URLs get 1h TTL

### Why Hash-based Partitioning?
- Even distribution (no hot spots)
- We don't need range queries
- Scales horizontally easily

## Common Pitfalls

1. **Not handling collisions** - Use counter-based approach
2. **Not considering scale** - Design for millions from start
3. **Ignoring security** - Rate limiting at Load Balancer, URL validation
4. **Poor caching** - Cache popular URLs (click_count > 100) with longer TTL, not everything
5. **Single point of failure** - Use replication and redundancy

## Key Metrics to Monitor

- Request rate (QPS)
- Latency (p50, p95, p99)
- Error rate
- Cache hit rate

## References

- [Designing Data-Intensive Applications](https://dataintensive.net/)
- [System Design: URL Shortener](https://www.educative.io/courses/grokking-the-system-design-interview/m2ygV4E81AR)
- [Base62 Encoding](https://en.wikipedia.org/wiki/Base62)