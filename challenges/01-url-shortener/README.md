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

