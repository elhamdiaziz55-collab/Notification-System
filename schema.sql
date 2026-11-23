
CREATE UNIQUE INDEX uq_events_daily_dedup
ON events (
    event_type,
    actor_id,
    subject_object_type,
    subject_object_id,
    ((created_at)::date)
);


CREATE TABLE notifications (
    notification_id INTEGER NOT NULL UNIQUE,
    type_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    campaign_id INTEGER,
    event_id INTEGER,
    scheduled_for TIMESTAMP,
    is_digest BOOLEAN NOT NULL,
    title VARCHAR(255),
    message TEXT,
    data JSONB,
    PRIMARY KEY(notification_id),
    UNIQUE(event_id, recipient_id)
);


CREATE TABLE users (
    user_id INTEGER NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL,
    unread_count INTEGER,
    PRIMARY KEY(user_id)
);


CREATE TABLE notification_preferences (
    preference_id INTEGER NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    frequency TEXT NOT NULL,
    channel VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP,
    PRIMARY KEY(preference_id),
    UNIQUE(user_id, type_id, channel)
);


CREATE TABLE events (
    event_id INTEGER NOT NULL UNIQUE,
    event_type VARCHAR(255),
    actor_id INTEGER,
    subject_object_type VARCHAR(255),
    subject_object_id INTEGER,
    event_data JSONB,
    created_at TIMESTAMP NOT NULL,
    processed_at TIMESTAMP,
    PRIMARY KEY(event_id)
);


CREATE TABLE notification_types (
    type_id INTEGER NOT NULL UNIQUE,
    type_name VARCHAR(255),
    display_template TEXT,
    default_channels JSONB,
    is_active BOOLEAN,
    PRIMARY KEY(type_id)
);


CREATE TABLE notification_deliveries (
    delivery_id INTEGER NOT NULL UNIQUE,
    notification_id INTEGER NOT NULL,
    channel TEXT NOT NULL,
    status TEXT NOT NULL,
    attempt_count INTEGER,
    external_id VARCHAR(255),
    next_retry_at TIMESTAMP,
    error_message TEXT,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    PRIMARY KEY(delivery_id),
    UNIQUE(notification_id, channel)
);


CREATE TABLE in_app_notification_states (
    state_id INTEGER NOT NULL UNIQUE,
    notification_id INTEGER NOT NULL,
    is_read BOOLEAN NOT NULL,
    is_archived BOOLEAN NOT NULL,
    is_deleted BOOLEAN NOT NULL,
    read_at TIMESTAMP,
    archived_at TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY(state_id),
    UNIQUE(notification_id)
);


CREATE TABLE campaigns (
    campaign_id INTEGER NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    message_title VARCHAR(255) NOT NULL,
    message_body VARCHAR(255),
    channels JSONB,
    target_criteria JSONB,
    scheduled_for TIMESTAMP,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    PRIMARY KEY(campaign_id)
);


CREATE TABLE digest_inclusions (
    inclusion_id INTEGER NOT NULL UNIQUE,
    notification_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    PRIMARY KEY(inclusion_id),
    UNIQUE(notification_id, event_id)
);


ALTER TABLE notifications
ADD FOREIGN KEY(type_id) REFERENCES notification_types(type_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE notifications
ADD FOREIGN KEY(recipient_id) REFERENCES users(user_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE notifications
ADD FOREIGN KEY(campaign_id) REFERENCES campaigns(campaign_id)
ON UPDATE NO ACTION ON DELETE SET NULL;


ALTER TABLE notifications
ADD FOREIGN KEY(event_id) REFERENCES events(event_id)
ON UPDATE NO ACTION ON DELETE SET NULL;


ALTER TABLE notification_preferences
ADD FOREIGN KEY(user_id) REFERENCES users(user_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE notification_preferences
ADD FOREIGN KEY(type_id) REFERENCES notification_types(type_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE events
ADD FOREIGN KEY(actor_id) REFERENCES users(user_id)
ON UPDATE NO ACTION ON DELETE SET NULL;


ALTER TABLE notification_deliveries
ADD FOREIGN KEY(notification_id) REFERENCES notifications(notification_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE in_app_notification_states
ADD FOREIGN KEY(notification_id) REFERENCES notifications(notification_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE digest_inclusions
ADD FOREIGN KEY(notification_id) REFERENCES notifications(notification_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE digest_inclusions
ADD FOREIGN KEY(event_id) REFERENCES events(event_id)
ON UPDATE NO ACTION ON DELETE CASCADE;


-- Indexes on foreign key columns

CREATE INDEX idx_notifications_type_id
ON notifications(type_id);

CREATE INDEX idx_notifications_recipient_id
ON notifications(recipient_id);

CREATE INDEX idx_notifications_campaign_id
ON notifications(campaign_id);

CREATE INDEX idx_notifications_event_id
ON notifications(event_id);

CREATE INDEX idx_notification_preferences_user_id
ON notification_preferences(user_id);

CREATE INDEX idx_notification_preferences_type_id
ON notification_preferences(type_id);

CREATE INDEX idx_events_actor_id
ON events(actor_id);

CREATE INDEX idx_notification_deliveries_notification_id
ON notification_deliveries(notification_id);

CREATE INDEX idx_in_app_notification_states_notification_id
ON in_app_notification_states(notification_id);

CREATE INDEX idx_digest_inclusions_notification_id
ON digest_inclusions(notification_id);

CREATE INDEX idx_digest_inclusions_event_id
ON digest_inclusions(event_id);


-- Relationships as drawn

-- notification_types.type_id -> notifications.type_id (one-to-many)
-- notification_types.type_id -> notification_preferences.type_id (one-to-many)
-- notification_preferences.user_id -> users.user_id (one-to-many)
-- events.event_id -> notifications.event_id (one-to-many)
-- notifications.recipient_id -> users.user_id (one-to-many)
-- events.actor_id -> users.user_id (one-to-many)
-- notifications.notification_id -> in_app_notification_states.notification_id (one-to-one)
-- notifications.notification_id -> notification_deliveries.notification_id (one-to-many)
-- campaigns.campaign_id -> notifications.campaign_id (one-to-many)
-- notifications.notification_id -> digest_inclusions.notification_id (one-to-many)
-- events.event_id -> digest_inclusions.event_id (one-to-many)
