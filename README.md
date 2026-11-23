# Notification System

## Problem

Design a relational database schema for a multi-channel notification
system that delivers event-triggered and scheduled notifications with
user preferences, delivery status tracking, and read/unread management.

## Business Context

### Notification triggers

Notifications are triggered by user actions (e.g., "user liked your
post", "someone replied to your comment", "your friend joined"). Each
trigger maps to an event type and can be configured by the user.

### Scheduled notifications

System sends digest notifications (e.g., weekly digest of likes, monthly
summary) on a schedule.

### Delivery channels

Notifications can be delivered via multiple channels: in-app (bell
icon), push (mobile), email, or SMS. Each notification may go to
multiple channels based on user preferences.

### Preference management

Users can control notification frequency (instant, daily digest, weekly,
off) per notification type and per channel.

### Read/unread status

In-app notifications have read/unread status. Users can mark as read,
archive, or delete in-app notifications.

### Retry logic

Failed push or email deliveries are retried with exponential backoff.

### Bulk sends

Campaigns send the same notification to multiple users (e.g., "New
feature announcement").

## Requirements

### Polymorphic notifications

Notifications reference different object types (posts, comments, users,
activities). The `data` column (JSON) contains context-specific fields.

### Preference enforcement

Before sending a notification, check the user's preferences for that
type + channel + frequency. Respect opt-outs.

### Multi-channel delivery

One notification event can be delivered across multiple channels (push +
email + in-app). Track delivery status independently per channel.

### Read status & archival

In-app notifications support read/unread and archive/delete states.
Archived notifications are hidden but retrievable; deleted are
soft-deleted.

### Digest aggregation

Scheduled notifications batch multiple events (e.g., weekly digest of
all likes) into a single notification.

### Retry mechanism

Failed deliveries (push, email, SMS) retry with exponential backoff;
track retry count and next retry time.

### Bulk campaign sends

Support sending the same notification to many users; track delivery per
(campaign, user, channel).

### Deduplication

Don't send duplicate notifications for the same event; if event is
already processed, skip.

## Constraints

-   Notification creation should be transactional; if preference check
    fails, don't create the notification.
-   In-app notifications are immediate (no retry logic); push/email/SMS
    use async retry queues.
-   Scheduled notifications are cron-triggered (daily, weekly, etc.);
    use a scheduled job to create notifications.
-   User preferences can change; notifications created before a
    preference change are unaffected.
-   Retention: Delete notification records after 90 days (hard delete or
    archive to cold storage).
-   Unread count per user must be queryable in \< 100ms; consider a
    denormalized `unread_count` in the users table.
