# System Design: Notification Service

## High-Level Architecture

```
┌─────────────┐
│   Client    │
│ Application │
└──────┬──────┘
       │
       │ POST /api/v1/notifications
       ▼
┌─────────────────────────────────────┐
│         Load Balancer               │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│  API Server │    │  API Server │
│ (Instance 1)│    │ (Instance 2)│
└───┬─────┬───┘    └───┬─────┬───┘
    │     │            │     │
    │     │            │     │
    │     │ Cache Lookup     │
    │     ▼            │     ▼
    │  ┌──────────────────────────┐
    │  │   Redis Cache           │
    │  │  (Preferences & Templates)│
    │  └──────┬───────────────────┘
    │         │ (cache miss)
    │         ▼
    │  ┌─────────────────┐
    │  │   Database      │
    │  │  (PostgreSQL)   │
    │  │  (Preferences   │
    │  │   & Templates)  │
    │  └─────────────────┘
    │
    │ Enqueue Jobs
    ▼
┌─────────────────────────────────────┐
│      Job Queue (Sidekiq/Redis)     │
│  ┌──────────┐  ┌──────────┐        │
│  │ Priority │  │ Normal   │        │
│  │  Queue   │  │  Queue   │        │
│  └──────────┘  └──────────┘        │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│   Worker    │    │   Worker    │
│  Instances  │    │  Instances  │
└──────┬──────┘    └──────┬──────┘
       │                  │
       │ Process Jobs     │
       ▼                  ▼
┌─────────────────────────────────────┐
│      Channel Handlers               │
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │Email │  │ SMS  │  │ Push │      │
│  └──┬───┘  └──┬───┘  └──┬───┘      │
└─────┼─────────┼─────────┼──────────┘
      │         │         │
      ▼         ▼         ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│Email    │ │SMS      │ │Push     │
│Provider │ │Gateway  │ │Service  │
│(SendGrid)│ │(Twilio) │ │(FCM/APNs)│
└─────────┘ └─────────┘ └─────────┘
      │         │         │
      │         │         │
      └─────────┼─────────┘
                │
                │ Store notification status
                ▼
      ┌─────────────────┐
      │   Database      │
      │  (PostgreSQL)   │
      │  - Notifications │
      │  - Preferences   │
      │  - Templates     │
      └─────────────────┘
```

## API Design

### 1. Send Notification

**Endpoint:** `POST /api/v1/notifications`

**Request:**

**Note:** The `scheduled_at` field accepts a full ISO 8601 timestamp (date and time) in UTC format. Use `null` for immediate delivery, or provide a timestamp like `"2024-01-20T14:30:00Z"` for scheduled delivery.

**Example 1: Immediate notification**
```json
{
  "user_id": "12345",
  "channel": "email",
  "template_id": "order_confirmation",
  "variables": {
    "order_number": "ORD-12345",
    "total": "$99.99",
    "delivery_date": "2024-01-20"
  },
  "priority": "normal",
  "scheduled_at": null
}
```

**Example 2: Scheduled notification (with specific date and time)**
```json
{
  "user_id": "12345",
  "channel": "email",
  "template_id": "password_reset",
  "variables": {
    "reset_link": "https://example.com/reset?token=abc123"
  },
  "priority": "urgent",
  "scheduled_at": "2024-01-20T14:30:00Z"
}
```

**Response:**
```json
{
  "notification_id": "notif_abc123",
  "status": "queued",
  "queued_at": "2024-01-15T10:30:00Z",
  "estimated_delivery": "2024-01-15T10:30:05Z"
}
```

### 2. Get Notification Status

**Endpoint:** `GET /api/v1/notifications/{notification_id}`

**Response:**
```json
{
  "notification_id": "notif_abc123",
  "user_id": "12345",
  "channel": "email",
  "status": "delivered",
  "queued_at": "2024-01-15T10:30:00Z",
  "sent_at": "2024-01-15T10:30:02Z",
  "delivered_at": "2024-01-15T10:30:03Z",
  "retry_count": 0,
  "error": null
}
```

### 3. Batch Send Notifications

**Endpoint:** `POST /api/v1/notifications/batch`

**Request:**
```json
{
  "notifications": [
    {
      "user_id": "12345",
      "channel": "email",
      "template_id": "welcome",
      "variables": {}
    },
    {
      "user_id": "67890",
      "channel": "sms",
      "template_id": "verification",
      "variables": {
        "code": "123456"
      }
    }
  ]
}
```

**Response:**
```json
{
  "batch_id": "batch_xyz789",
  "total": 2,
  "queued": 2,
  "failed": 0,
  "notification_ids": [
    "notif_abc123",
    "notif_def456"
  ]
}
```

## Database Design

### Choice: PostgreSQL (SQL)

**Schema:**

```sql
-- Notifications table
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    notification_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL, -- email, sms, push, in_app
    template_id VARCHAR(255) NOT NULL,
    variables JSONB,
    status VARCHAR(50) NOT NULL, -- queued, processing, sent, delivered, failed, bounced
    priority VARCHAR(20) DEFAULT 'normal', -- urgent, normal, low
    scheduled_at TIMESTAMP,
    queued_at TIMESTAMP NOT NULL,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    failed_at TIMESTAMP,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    external_id VARCHAR(255), -- ID from external service (email provider, SMS gateway)
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_channel ON notifications(channel);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Notification preferences (could be in separate service)
CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    notification_type VARCHAR(100) NOT NULL,
    enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, channel, notification_type)
);

CREATE INDEX idx_preferences_user_id ON notification_preferences(user_id);

-- Templates (could be in separate service)
CREATE TABLE notification_templates (
    id BIGSERIAL PRIMARY KEY,
    template_id VARCHAR(255) UNIQUE NOT NULL,
    channel VARCHAR(50) NOT NULL,
    subject VARCHAR(500), -- for email
    body TEXT NOT NULL,
    variables JSONB, -- expected variables
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_templates_template_id ON notification_templates(template_id);
CREATE INDEX idx_templates_channel ON notification_templates(channel);
```

## Component Design

### 1. API Layer

**Responsibilities:**
- Validate incoming requests
- Check user preferences
- Enqueue notification jobs
- Return immediate response to client

**Key Classes:**
- `NotificationsController` - Handle HTTP requests
- `NotificationService` - Business logic for creating notifications
- `NotificationValidator` - Validate notification data

### 2. Queue Layer (Sidekiq)

**Queue Strategy:**
- **Priority Queue** - For urgent notifications (transactional, time-sensitive)
- **Normal Queue** - For standard notifications
- **Low Priority Queue** - For marketing/bulk notifications
- **Dead Letter Queue** - For permanently failed notifications

**Job Classes:**
- `SendNotificationJob` - Main job for processing notifications
- `RetryNotificationJob` - Handle retries with exponential backoff
- `ProcessBatchNotificationJob` - Handle batch notifications

### 3. Channel Handlers

**Email Handler:**
- Integrate with email provider (SendGrid, AWS SES, etc.)
- Handle HTML/text templates
- Track delivery status via webhooks
- Handle bounces and unsubscribes

**SMS Handler:**
- Integrate with SMS gateway (Twilio, AWS SNS, etc.)
- Handle character limits
- Track delivery receipts
- Handle delivery failures

**Push Notification Handler:**
- Integrate with FCM (Android) and APNs (iOS)
- Handle device tokens
- Support rich notifications
- Handle token invalidation

**In-App Handler:**
- Store notifications in database
- Support real-time delivery via WebSockets (future)
- Mark as read/unread

### 4. Retry Mechanism

**Strategy:**
- Exponential backoff: 1s, 2s, 4s, 8s, 16s
- Maximum retries: 3 attempts (configurable)
- Retry only on transient failures (network errors, rate limits)
- Permanent failures (invalid email, blocked number) go to dead letter queue

**Implementation:**
```ruby
# Pseudo-code
def retry_with_backoff(notification, attempt)
  return if attempt > notification.max_retries
  
  delay = 2 ** attempt # exponential backoff
  sleep(delay)
  
  result = send_notification(notification)
  
  if result.success?
    update_status(notification, 'sent')
  elsif result.transient_failure?
    retry_with_backoff(notification, attempt + 1)
  else
    move_to_dead_letter_queue(notification)
  end
end
```

### 5. User Preferences Service

**Responsibilities:**
- Check if user has opted in for channel/notification type
- Respect quiet hours (timezone-aware)
- Check rate limits per user
- Cache preferences for performance

**Why Cache is Essential:**
- **High read frequency**: With 1M notifications/day and 10K/minute peak, each notification requires preference checks
- **Read-heavy workload**: Preferences change infrequently (write-rarely, read-often pattern)
- **Latency reduction**: Database queries add ~5-10ms; Redis cache adds ~1-2ms
- **Database load reduction**: Without cache, 1M+ preference queries/day would strain the database
- **Cost efficiency**: Redis is cheaper than scaling database read replicas for this use case

**Implementation:**
- Query `notification_preferences` table on cache miss
- Cache in Redis with key pattern: `pref:{user_id}:{channel}:{notification_type}`
- TTL: 1 hour (ensures eventual consistency, handles preference updates)
- Invalidate cache immediately on preference updates (write-through pattern)
- Cache structure: Store serialized preference object with all relevant fields (enabled, quiet_hours, timezone)

## Data Flow

### Send Notification Flow

1. **Client Request**
   - Client sends POST request to `/api/v1/notifications`
   - API validates request (user_id, channel, template_id)

2. **Preference Check**
   - Query user preferences from cache/database
   - Check if user has opted in for channel
   - Check quiet hours (if applicable)
   - If not allowed, return error immediately

3. **Create Notification Record**
   - Insert notification into database with status 'queued'
   - Generate unique notification_id

4. **Enqueue Job**
   - Enqueue `SendNotificationJob` to appropriate Sidekiq queue
   - Job includes notification_id and all necessary data

5. **Return Response**
   - Return 202 Accepted with notification_id
   - Client can poll for status later

6. **Worker Processing**
   - Worker picks up job from queue
   - Update notification status to 'processing'
   - Load template and render with variables
   - Call appropriate channel handler

7. **Channel Handler**
   - Send notification via external service
   - Update notification status to 'sent'
   - Store external_id (provider's message ID)

8. **Delivery Confirmation**
   - External service sends webhook (if supported)
   - Update notification status to 'delivered'
   - Log delivery timestamp

### Retry Flow

1. **Failure Detection**
   - Channel handler catches exception
   - Determine if failure is transient or permanent

2. **Transient Failure**
   - Increment retry_count
   - If retry_count < max_retries:
     - Schedule retry with exponential backoff
     - Update status to 'queued' (for retry)
   - If retry_count >= max_retries:
     - Move to dead letter queue
     - Update status to 'failed'

3. **Permanent Failure**
   - Move to dead letter queue immediately
   - Update status to 'failed'
   - Log error message

## Scalability Considerations

### Horizontal Scaling

1. **API Servers**
   - Stateless API servers can scale horizontally
   - Load balancer distributes requests

2. **Workers**
   - Multiple Sidekiq worker processes
   - Each worker can process jobs independently
   - Scale workers based on queue depth

3. **Database**
   - Read replicas for querying notification status
   - Primary database for writes
   - Partition notifications table by date (if needed)

### Queue Management

1. **Queue Isolation**
   - Separate queues per channel prevent one channel's issues from affecting others
   - Priority queues ensure urgent notifications are processed first

2. **Rate Limiting**
   - Implement rate limiting per external service
   - Use Redis to track rate limits
   - Queue jobs if rate limit exceeded

3. **Batch Processing**
   - Group notifications by channel for efficiency
   - Reduce API calls to external services
   - Process in batches of 100-1000 notifications

## Reliability Considerations

### Fault Tolerance

1. **External Service Failures**
   - Circuit breakers for external services
   - Graceful degradation (log error, retry later)
   - Health checks for external services

2. **Database Failures**
   - Primary-replica setup for high availability
   - Retry database operations on transient failures
   - Queue jobs if database is temporarily unavailable

3. **Worker Failures**
   - Sidekiq automatically retries failed jobs
   - Dead letter queue for permanently failed jobs
   - Monitoring and alerting on worker failures

### Data Durability

1. **Notification Persistence**
   - All notifications stored in database before queuing
   - Status updates are transactional
   - Support replay/re-send from database

2. **Audit Trail**
   - Log all status changes
   - Store error messages and stack traces
   - Support compliance requirements

## Performance Optimizations

1. **Caching**
   - **User preferences in Redis**: Critical for performance given high read frequency (1M+ checks/day)
     - Key pattern: `pref:{user_id}:{channel}:{notification_type}`
     - TTL: 1 hour with immediate invalidation on updates
     - Reduces database load by ~95% for preference lookups
   - **Notification templates in Redis**: Templates change infrequently, perfect for caching
     - Key pattern: `template:{template_id}`
     - TTL: 24 hours with invalidation on template updates
   - **Overall impact**: Reduces database queries significantly, improves API response time

2. **Batch Operations**
   - Batch database inserts for bulk notifications
   - Batch API calls to external services
   - Reduce network overhead

3. **Async Processing**
   - All delivery is asynchronous
   - API returns immediately after enqueuing
   - Non-blocking for client applications

## Monitoring and Observability

### Key Metrics

1. **Throughput**
   - Notifications queued per second
   - Notifications sent per second
   - Notifications delivered per second

2. **Latency**
   - Time from queue to sent (p50, p95, p99)
   - Time from sent to delivered (p50, p95, p99)

3. **Success Rates**
   - Delivery success rate per channel
   - Retry success rate
   - Dead letter queue size

4. **Queue Metrics**
   - Queue depth per priority level
   - Worker utilization
   - Job processing time

### Logging

- Log all notification lifecycle events
- Log external service API calls and responses
- Log errors with full context
- Structured logging for easy querying

### Alerting

- Alert on high failure rates
- Alert on queue depth exceeding thresholds
- Alert on external service downtime
- Alert on worker process failures
