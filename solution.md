# Notification System — Database Solution

Let's think through this step by step. A notification system isn't just "send a message" — it's a complex workflow of events, preferences, delivery channels, and status tracking. Let's build it piece by piece.

## 02 — Who's getting these notifications?

First, we need users. But not just any user table — we need to think about notification preferences upfront.

## 03 — Schema · Users

**Schema:** 1 table  
**Users:** 6 cols

| Column | Type |
|---|---|
| `user_id` | `INT` |
| `email` | `VARCHAR(255)` |
| `phone` | `VARCHAR(20)` |
| `push_token` | `VARCHAR(500)` |
| `unread_count` | `INT` |
| `created_at` | `TIMESTAMP` |

**Why `unread_count` here?**

The requirements say we need sub-100ms queries for unread counts. With millions of notifications, counting `WHERE is_read = false` every time would be too slow. We'll update this counter whenever notifications are marked read/unread.

## 04 — What types of things can trigger notifications?

Notifications don't just appear — they're triggered by events. A like, a comment, a friend request. But here's the tricky part: different event types have different data. A "like" event needs to know which post. A "friend request" needs to know which user.

## 05 — Schema · Notification Types

**Schema:** 1 table  
**Notification Types:** 5 cols

| Column | Type |
|---|---|
| `type_id` | `INT` |
| `type_name` | `VARCHAR(100)` |
| `display_template` | `TEXT` |
| `default_channels` | `JSON` |
| `is_active` | `BOOLEAN` |

The `display_template` uses placeholders that get filled in later. The `default_channels` JSON tells us which channels this type of notification typically uses (though users can override this in their preferences).

## 06 — How do users control what they get?

Users want granular control: "Send me post likes via push instantly, but email me a weekly digest of comments." That's per-type, per-channel, per-frequency preferences.

## 07 — Schema · User Notification Preferences

**Schema:** 1 table  
**User Notification Preferences:** 6 cols

| Column | Type |
|---|---|
| `preference_id` | `INT` |
| `user_id` | `INT` |
| `type_id` | `INT` |
| `channel` | `ENUM` |
| `frequency` | `ENUM` |
| `updated_at` | `TIMESTAMP` |

`UNIQUE(user_id, type_id, channel)` — each user gets exactly one preference per type per channel. No duplicates allowed.

## 08 — When something happens, we need to track it

Before we create notifications, we need to capture the events that trigger them. This is our source of truth for "what happened when."

## 09 — Schema · Events

**Schema:** 1 table  
**Events:** 8 cols

| Column | Type |
|---|---|
| `event_id` | `INT` |
| `event_type` | `VARCHAR(100)` |
| `actor_id` | `INT` |
| `subject_object_type` | `VARCHAR(100)` |
| `subject_object_id` | `INT` |
| `event_data` | `JSON` |
| `created_at` | `TIMESTAMP` |
| `processed_at` | `TIMESTAMP` |

This is our polymorphic reference. Instead of separate columns for post_id, comment_id, user_id, we use subject_object_type + subject_object_id. A "like" event has subject_object_type = 'post' and subject_object_id = 123. The event_data JSON stores extra context like the post title or comment text.

`UNIQUE(event_type, actor_id, subject_object_type, subject_object_id, DATE(created_at))` — prevents duplicate events for the same action on the same day.

## 10 — From events to actual notifications

Now we create notifications — the actual messages sent to users. One event might create multiple notifications (if multiple users should be notified) or batch into digest notifications.

## 11 — Schema · Notifications

**Schema:** 1 table  
**Notifications:** 11 cols

| Column | Type |
|---|---|
| `notification_id` | `INT` |
| `recipient_id` | `INT` |
| `type_id` | `INT` |
| `event_id` | `INT` |
| `campaign_id` | `INT` |
| `title` | `VARCHAR(255)` |
| `message` | `TEXT` |
| `data` | `JSON` |
| `is_digest` | `BOOLEAN` |
| `scheduled_for` | `TIMESTAMP` |
| `created_at` | `TIMESTAMP` |

One event can create multiple notifications (if multiple users care about it). The message field contains the final rendered text with all placeholders filled in. scheduled_for handles digest notifications that get sent later.

## 12 — Tracking delivery across multiple channels

Here's where it gets interesting. One notification might go to in-app AND push AND email. Each channel has its own delivery status and retry logic. So we need a separate table to track each delivery attempt.

## 13 — Schema · Notification Deliveries

**Schema:** 1 table  
**Notification Deliveries:** 10 cols

| Column | Type |
|---|---|
| `delivery_id` | `INT` |
| `notification_id` | `INT` |
| `channel` | `ENUM` |
| `status` | `ENUM` |
| `attempt_count` | `INT` |
| `next_retry_at` | `TIMESTAMP` |
| `external_id` | `VARCHAR(255)` |
| `error_message` | `TEXT` |
| `sent_at` | `TIMESTAMP` |
| `delivered_at` | `TIMESTAMP` |

`UNIQUE(notification_id, channel)` — each notification gets exactly one delivery record per channel.

This table powers the retry logic. Failed email deliveries get next_retry_at set to "now + exponential backoff delay" and status = 'failed'. A background job picks up records where next_retry_at < NOW() and retries them.

## 14 — Managing in-app notification states

In-app notifications are special. Users can mark them read, archive them, or delete them. We need to track these states without losing the notification entirely (in case they want to unarchive later).

## 15 — Schema · In-App Notification States

**Schema:** 1 table  
**In-App Notification States:** 8 cols

| Column | Type |
|---|---|
| `state_id` | `INT` |
| `notification_id` | `INT` |
| `is_read` | `BOOLEAN` |
| `is_archived` | `BOOLEAN` |
| `is_deleted` | `BOOLEAN` |
| `read_at` | `TIMESTAMP` |
| `archived_at` | `TIMESTAMP` |
| `deleted_at` | `TIMESTAMP` |

This table only has rows for in-app notifications. Push/email/SMS notifications don't have read/unread states — once delivered, they're done.

When a user marks a notification read, we update is_read = true AND decrement the unread_count in the Users table. Both operations happen in a transaction to keep the count accurate.

## 16 — Supporting bulk campaigns

Sometimes you want to send the same message to thousands of users — "New feature launched!" or "System maintenance tonight." These are campaigns.

## 17 — Schema · Campaigns

**Schema:** 1 table  
**Campaigns:** 12 cols

| Column | Type |
|---|---|
| `campaign_id` | `INT` |
| `title` | `VARCHAR(255)` |
| `message_title` | `VARCHAR(255)` |
| `message_body` | `TEXT` |
| `channels` | `JSON` |
| `target_criteria` | `JSON` |
| `status` | `ENUM` |
| `scheduled_for` | `TIMESTAMP` |
| `created_by` | `INT` |
| `created_at` | `TIMESTAMP` |
| `started_at` | `TIMESTAMP` |
| `completed_at` | `TIMESTAMP` |

The `target_criteria` JSON lets you specify things like "only users who signed up this month" or "only users in the US." When the campaign runs, it creates individual notifications for each matching user.

## 18 — Batching events into digest notifications

For digest notifications ("Here's your weekly summary"), we need to track which events have been included in which digests, so we don't send duplicates.

## 19 — Schema · Digest Inclusions

**Schema:** 1 table  
**Digest Inclusions:** 4 cols

| Column | Type |
|---|---|
| `inclusion_id` | `INT` |
| `notification_id` | `INT` |
| `event_id` | `INT` |
| `created_at` | `TIMESTAMP` |

`UNIQUE(notification_id, event_id)` — each event can only be included once per digest notification.

When creating a weekly digest, the system finds all unprocessed events for a user in the past week, creates one digest notification, and records which events were included. Next week's digest won't include those same events.

## 20 — Let's check — can we answer the key business questions?

### "What are this user's unread notifications?"

```sql
SELECT n.* FROM notifications n
JOIN in_app_notification_states s ON n.notification_id = s.notification_id
WHERE n.recipient_id = ? AND s.is_read = false AND s.is_deleted = false;
```

### "Should we send this notification to this user?"

```sql
SELECT frequency FROM user_notification_preferences
WHERE user_id = ? AND type_id = ? AND channel = ?;
```

If frequency = 'off', don't send. If frequency = 'instant', send now. If frequency = 'weekly', queue for next digest.

### "Which email deliveries need retry?"

```sql
SELECT * FROM notification_deliveries
WHERE channel = 'email' AND status = 'failed' AND next_retry_at <= NOW();
```

### "How many notifications has this campaign sent?"

```sql
SELECT COUNT(*) FROM notifications WHERE campaign_id = ?;
```

### "Update unread count after marking notification read"

```sql
BEGIN;
UPDATE in_app_notification_states SET is_read = true WHERE notification_id = ?;
UPDATE users SET unread_count = unread_count - 1 WHERE user_id = ?;
COMMIT;
```

All the core workflows are supported. The model handles polymorphic events, multi-channel delivery, user preferences, retry logic, campaigns, and digest batching.

## 21 — Summary: A notification system that actually works

9 tables working together:

- **Users** → store basic info and denormalized unread counts
- **Notification Types** → define templates and default channels
- **User Notification Preferences** → granular per-type/channel/frequency control
- **Events** → polymorphic source of truth for "what happened"
- **Notifications** → individual messages created for specific users
- **Notification Deliveries** → track status per channel with retry logic
- **In-App Notification States** → handle read/unread/archive/delete states
- **Campaigns** → bulk sending to multiple users
- **Digest Inclusions** → prevent duplicate events in digest notifications

The key insight is separating concerns: events are different from notifications, notifications are different from deliveries, and each channel has its own lifecycle. This separation makes the system flexible enough to handle instant notifications, batched digests, multi-channel delivery, and complex user preferences while maintaining good performance at scale.
