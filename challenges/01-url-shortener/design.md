# System Design: URL Shortener

## High-Level Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│         Load Balancer               │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│  App Server │    │  App Server │
│ (Instance 1)│    │ (Instance 2)│
│             │    │      ...    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       │                  │
       └──────────┬───────┘
                  │
                  ▼
         ┌─────────────────┐
         │  Cache (Redis)  │
         │  Shared Service │
         │  (Cluster)      │
         └─────────┬───────┘
                   │
                   ▼
         ┌─────────────────┐
         │   Database      │
         │  (PostgreSQL)   │
         │  Primary-Replica│
         └─────────────────┘
```

**Note:** 
- App Server instances are identical copies of the same stateless service, scaled horizontally
- Redis is a **shared service** - all app instances connect to the same Redis cluster
- This allows cache sharing across all instances (cache hit in one instance benefits all)

## API Design

### 1. Create Short URL

**Endpoint:** `POST /api/v1/shorten`

**Request:**
```json
{
  "url": "https://www.example.com/very/long/url/with/many/segments"
}
```

**Response:**
```json
{
  "short_url": "https://short.ly/abc123",
  "original_url": "https://www.example.com/very/long/url/with/many/segments",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### 2. Redirect Short URL

**Endpoint:** `GET /{short_code}`

**Response:**
- **302 Found** (redirect to original URL)
- **404 Not Found** (if short code doesn't exist)

### 3. Get Analytics

**Endpoint:** `GET /api/v1/analytics/{short_code}`

**Response:**
```json
{
  "short_code": "abc123",
  "original_url": "https://www.example.com/...",
  "click_count": 1523,
  "created_at": "2024-01-15T10:30:00Z",
  "last_accessed": "2024-01-20T15:45:00Z"
}
```

**Note:** `click_count` is incremented and `last_accessed` is updated synchronously on each redirect request (see Read Flow in Caching Strategy section). This enables both analytics tracking and cache TTL optimization based on URL popularity.

## Database Design

### Choice: PostgreSQL (SQL)

**Schema:**
```sql
CREATE TABLE short_urls (
    id BIGSERIAL PRIMARY KEY,
    short_code VARCHAR(6) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    click_count BIGINT DEFAULT 0,
    last_accessed TIMESTAMP,
    INDEX idx_short_code (short_code),
    INDEX idx_created_at (created_at)
);
```

**Note:** `expires_at` is out of scope for MVP but can be added later for URL expiration feature.

**Trade-offs:**

✅ **Pros:**
- **ACID transactions** - Guarantees data integrity when generating short codes
- **Strong consistency** - All reads see the latest committed data (important for analytics)
- **Complex queries** - Easy to query analytics, date ranges, etc.
- **Mature ecosystem** - Well-understood, extensive tooling and monitoring
- **Relational model** - Natural fit for structured data with relationships

❌ **Cons:**
- **Horizontal scaling** - Harder to scale writes horizontally (requires sharding)
- **Single write primary** - Can become bottleneck at very high write rates
- **Vertical scaling first** - Need to scale up before scaling out

**Justification:**
For the initial scale (100 writes/sec, 1000 reads/sec), PostgreSQL provides strong consistency and ACID guarantees that are critical for ensuring unique short codes and accurate analytics. The read-heavy workload (10:1 ratio) is well-suited for PostgreSQL with read replicas. We can migrate to a distributed database (e.g., Cassandra) if write throughput becomes a bottleneck at scale.

**Replication Strategy:**
- **Primary-Replica replication** for read scaling
- Read replicas handle redirect requests (read-heavy)
- Primary handles URL creation (write operations)

## Short Code Generation

### Choice: Counter-based with Base62 Encoding

**Implementation:**
1. Get next number from database sequence (atomic operation)
2. Convert to Base62 (a-z, A-Z, 0-9) - 62 characters
3. Use as short code (6 characters)

**Base62 Encoding:**
- **6 characters** = 62^6 = 56.8 billion possible URLs
- Chosen length provides sufficient capacity (100 million requirement) while keeping URLs short
- More compact than decimal (10 digits) or hexadecimal (16 characters)
- If growth exceeds capacity, can extend to 7 or 8 characters in the future

**Trade-offs:**

✅ **Pros:**
- **Guaranteed uniqueness** - Database sequence ensures no collisions
- **Atomic operation** - Sequence generation is ACID-compliant
- **Simple implementation** - Straightforward logic, easy to reason about
- **Sequential IDs** - Can be useful for analytics and debugging
- **No collision handling** - No need for retry logic or collision detection

❌ **Cons:**
- **Database dependency** - Requires database access for each code generation
- **Single point of failure** - Sequence generator can bottleneck writes
- **Predictable** - Sequential nature makes codes somewhat predictable (mitigated by Base62 encoding length)
- **Scaling writes** - Sequence generation can become bottleneck at very high write rates

**Justification:**
The counter-based approach provides guaranteed uniqueness without collision handling complexity. For 100 writes/sec, the database sequence is more than sufficient. The predictable nature is acceptable for this use case (not a security concern for public URL shortening). If we need to scale writes significantly, we can pre-allocate number ranges per server or use a distributed ID generator (e.g., Snowflake algorithm).

## Caching Strategy

### Choice: Cache-Aside Pattern with Redis

**Read Flow (Redirect):**
1. Check Redis cache first
2. If cache hit:
   - Increment `click_count` and update `last_accessed` in database (synchronous)
   - Return redirect immediately
3. If cache miss:
   - Query PostgreSQL for original URL
   - Increment `click_count` and update `last_accessed` in database (synchronous)
   - Store result in Redis with TTL (based on updated click_count)
   - Return redirect to client

**Note:** Updates are done synchronously for simplicity. A simple UPDATE query is fast (< 5ms) and ensures immediate consistency for analytics. This approach keeps the implementation straightforward while still meeting the < 100ms redirect latency requirement.

**Write Flow:**
1. Write to PostgreSQL
2. Invalidate cache entry (or update if we want to cache immediately)

**Cache TTL Strategy:**
- **Popular URLs** (high click count): 24 hours TTL
- **Regular URLs**: 1 hour TTL
- **LRU eviction** for memory management

**How we determine Popular vs Regular URLs:**
- Use `click_count` field from database to determine popularity
- **Popular:** `click_count > 100` → 24 hours TTL
- **Regular:** `click_count ≤ 100` → 1 hour TTL
- When caching a URL (cache miss), check `click_count` from database to determine TTL
- When URL expires from cache and is re-cached, check updated `click_count` to determine new TTL
- This ensures frequently accessed URLs stay in cache longer, reducing database load
- URLs start as "regular" and become "popular" as they accumulate clicks (click_count is incremented on each redirect)

**Redis Architecture:**
- **Shared service** - All app server instances connect to the same Redis cluster
- **Not per-instance** - Redis is centralized, not distributed across app instances
- **Cache sharing** - When one instance caches a URL, all instances benefit (cache hit)
- **High availability** - Redis Cluster or Sentinel for redundancy and failover

**Trade-offs:**

✅ **Pros:**
- **Simple to implement** - Straightforward logic
- **Cache independence** - Cache failure doesn't affect database
- **Flexible TTL** - Can adjust per URL popularity
- **Read optimization** - Reduces database load for popular URLs

❌ **Cons:**
- **Cache miss penalty** - Two round trips (cache + database) on miss
- **Potential inconsistency** - Cache might have stale data briefly after invalidation
- **Cache stampede** - Multiple requests for same uncached URL can hit database simultaneously

**Justification:**
Cache-aside is ideal for read-heavy workloads (1000 reads/sec vs 100 writes/sec). The 80-20 rule applies here - 20% of URLs will get 80% of traffic. Caching these popular URLs significantly reduces database load. The brief inconsistency window is acceptable for URL redirection (not critical if a URL is cached for a few extra seconds).

## Partitioning Strategy

### Choice: Hash-based Partitioning

**Strategy:**
- Partition by hash of `short_code`
- Use consistent hashing for even distribution
- Each partition handles a range of hash values

**Trade-offs:**

✅ **Pros:**
- **Even distribution** - Hash function distributes data uniformly across partitions
- **No hot spots** - Avoids concentration of popular URLs in single partition
- **Scalable** - Easy to add new partitions and redistribute data
- **Load balancing** - Natural load distribution across partitions

❌ **Cons:**
- **No range queries** - Can't efficiently query by short_code range
- **Re-partitioning overhead** - Requires data movement when adding partitions
- **Hash collisions** - Different short_codes might hash to same partition (rare with good hash function)

**Justification:**
Hash-based partitioning provides uniform distribution, which is critical for avoiding hot spots. Since we don't need range queries (we always query by exact short_code), this is the optimal choice. Consistent hashing allows us to add/remove partitions with minimal data movement, which is important for scaling.

## Capacity Estimation

### Storage

- **Short code:** 6 bytes (6 characters)
- **Original URL:** ~500 bytes (average)
- **Metadata:** ~50 bytes (timestamps, counters)
- **Total per record:** ~556 bytes

For 100 million URLs:
- **Total storage:** ~55.6 GB
- **With replication (3x):** ~166.8 GB

### Bandwidth

- **Write:** 100 req/s × 500 bytes = 50 KB/s
- **Read:** 1000 req/s × 500 bytes = 500 KB/s
- **Total:** ~550 KB/s

### Memory (Cache)

- Cache top 20% of URLs (20 million)
- 20M × 556 bytes = ~11.12 GB
- With overhead: ~15-20 GB

## Scalability Considerations

### Horizontal Scaling

1. **Application Servers**
   - Stateless design enables horizontal scaling
   - Load balancer distributes traffic
   - Auto-scaling based on traffic metrics

2. **Database**
   - **Read Replicas:** Handle read traffic (redirects are read-heavy)
   - **Sharding:** Hash-based partitioning when single primary becomes bottleneck
   - **Connection Pooling:** Efficient database connection management

3. **Cache**
   - **Redis Cluster:** For high availability and horizontal scaling
   - **Consistent Hashing:** Distributes cache across cluster nodes
   - **Regional caching:** Deploy cache closer to users for lower latency

## Reliability and Fault Tolerance

1. **Database Replication**
   - Primary-Replica replication with automatic failover
   - Read replicas for redundancy
   - Regular backups with point-in-time recovery

2. **Cache Redundancy**
   - Redis Sentinel or Cluster mode
   - Multiple cache instances across availability zones
   - Graceful degradation if cache fails (fallback to database)

3. **Data Backup**
   - Daily automated backups
   - Point-in-time recovery capability
   - Backup verification and testing

4. **Monitoring**
   - Health checks for all components
   - Alerting on failures and performance degradation
   - Performance metrics (latency, throughput, error rates)

## Security Considerations

1. **Rate Limiting**
   - **Implemented at Load Balancer level** - First line of defense
   - Prevent abuse: 100 requests/minute per IP for URL creation (~1.67 req/sec per IP)
   - This allows the system to support 100 writes/sec from distributed sources while preventing abuse from single IPs
   - Blocks abusive traffic before reaching application servers
   - API key authentication for higher rate limits (handled by app servers)
   - Load balancer tracks request counts per IP address
   - **Note:** With 100 req/min per IP limit, the system can support 100 writes/sec from ~60+ unique IPs, which is realistic for a public URL shortener service

2. **URL Validation**
   - Whitelist allowed protocols (http, https only)
   - Block known malicious URLs and domains
   - Validate URL length limits (max 2048 characters)
   - Sanitize and validate URL format

3. **Short Code Security**
   - Base62 encoding with 6 characters (56.8 billion possibilities) prevents brute force
   - Monitor for suspicious patterns (rapid generation, etc.)
   - Optional: Add random salt to counter for additional unpredictability

## Alternatives Considered

### Database: NoSQL (Cassandra)

**Why not chosen:**
- **Eventual consistency** - Not ideal for analytics queries that need accurate counts
- **Complexity** - More complex setup and maintenance
- **Overkill for scale** - Current requirements don't justify distributed database complexity
- **Query limitations** - Limited query capabilities compared to SQL

**When to reconsider:**
- If write throughput exceeds 10,000 writes/sec
- If we need multi-region writes
- If horizontal write scaling becomes critical

### Short Code: Hash-based Generation

**Why not chosen:**
- **Collision handling** - Requires retry logic and collision detection
- **Deterministic** - Same URL always gets same code (might be feature or bug)
- **Complexity** - More complex implementation with edge cases

**When to reconsider:**
- If we want same URL to always generate same short code (deduplication)
- If we need to generate codes without database access

### Partitioning: Range-based

**Why not chosen:**
- **Hot spots** - Popular short codes might cluster in certain ranges
- **Uneven distribution** - Natural clustering of data can cause imbalance
- **Range queries not needed** - We always query by exact short_code

**When to reconsider:**
- If we need to query URLs by creation date range
- If we need alphabetical sorting of short codes

### Cache: Write-through Pattern

**Why not chosen:**
- **Write latency** - Every write must update both database and cache
- **Cache dependency** - Cache failure blocks writes
- **Over-caching** - Caches data that might never be read

**When to reconsider:**
- If we need guaranteed cache consistency
- If cache writes are very fast and acceptable overhead

## Future Enhancements

1. **Custom Short URLs**
   - Allow users to specify their own short codes
   - Validate uniqueness and format
   - Premium feature for authenticated users

2. **URL Expiration**
   - TTL for short URLs
   - Automatic cleanup of expired URLs
   - User-configurable expiration dates

3. **Advanced Analytics**
   - Geographic distribution of clicks
   - Referrer tracking
   - Time-series data for click patterns
   - User agent and device analytics

4. **User Management**
   - Authentication and authorization
   - User-specific URL management
   - Dashboard for URL analytics
   - API keys for programmatic access

5. **CDN Integration**
   - Cache popular redirects at edge locations
   - Reduce latency globally
   - Offload traffic from origin servers

6. **Migration Path to Distributed Database**
   - Plan for Cassandra migration if write scale requires it
   - Dual-write pattern during migration
   - Gradual cutover strategy
