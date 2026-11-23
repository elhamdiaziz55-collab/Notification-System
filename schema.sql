CREATE TABLE "notification" (
	"id" INTEGER NOT NULL UNIQUE,
	"type_id" INTEGER NOT NULL,
	"receptionist_id" INTEGER NOT NULL,
	"campaign_id" INTEGER,
	"event_id" INTEGER,
	"scheduled_for" TIMESTAMP,
	"is_digest" BOOLEAN NOT NULL,
	"title" VARCHAR(255),
	"message" TEXT,
	"data" JSONB,
	PRIMARY KEY("id")
);

CREATE TABLE "user" (
	"user_id" INTEGER NOT NULL UNIQUE,
	"email" VARCHAR(255) NOT NULL UNIQUE,
	"phone" TEXT NOT NULL UNIQUE,
	"created_at" TIMESTAMP NOT NULL,
	"unread_count" INTEGER,
	PRIMARY KEY("user_id")
);

CREATE TABLE "PREFERENCE" (
	"preference_id" INTEGER NOT NULL UNIQUE,
	"user_id" INTEGER NOT NULL,
	"type_id" INTEGER NOT NULL,
	"frequency" TEXT NOT NULL,
	"channel" TEXT,
	"updated_at" TIMESTAMP,
	PRIMARY KEY("preference_id")
);

CREATE TABLE "event" (
	"event_id" INTEGER NOT NULL UNIQUE,
	"event_type" VARCHAR(255),
	"actor_id" INTEGER,
	"subject_object_type" VARCHAR(255),
	"subject_object_id" INTEGER,
	"event_data" JSONB,
	"created_at" TIMESTAMP,
	"processed_at" TIMESTAMP,
	PRIMARY KEY("event_id")
);

CREATE TABLE "Notification Types" (
	"type_id" INTEGER NOT NULL UNIQUE,
	"type_name" VARCHAR(255),
	"display_template" TEXT,
	"default_channels" JSONB,
	"is_active" BOOLEAN,
	PRIMARY KEY("type_id")
);

CREATE TABLE "Notification Deliveries" (
	"delivery_id" INTEGER NOT NULL UNIQUE,
	"notification_id" INTEGER,
	"channel" TEXT NOT NULL,
	"status" TEXT NOT NULL,
	"attempt_count" VARCHAR(255),
	"external_id" VARCHAR(255),
	"next_retry_at" TIMESTAMP,
	"error_message" TEXT,
	"sent_at" TIMESTAMP,
	"delivered_at" TIMESTAMP,
	PRIMARY KEY("delivery_id")
);

CREATE TABLE "In App Notification States" (
	"state_id" INTEGER NOT NULL UNIQUE,
	"notification_id" INTEGER NOT NULL,
	"is_read" BOOLEAN NOT NULL,
	"is_archived" BOOLEAN NOT NULL,
	"is_deleted" BOOLEAN NOT NULL,
	"read_at" TIMESTAMP,
	"archived_at" TIMESTAMP,
	"deleted_at" VARCHAR(255),
	PRIMARY KEY("state_id")
);

CREATE TABLE "Campaigns" (
	"campaign_id" INTEGER NOT NULL UNIQUE,
	"title" VARCHAR(255) NOT NULL,
	"message_title" VARCHAR(255) NOT NULL,
	"message_body" VARCHAR(255),
	"channels" JSONB,
	"target_criteria" JSONB,
	"scheduled_for" TIMESTAMP,
	"created_by" INTEGER NOT NULL,
	"created_at" TIMESTAMP,
	"started_at" TIMESTAMP,
	"comleted_at" TIMESTAMP,
	PRIMARY KEY("campaign_id")
);

CREATE TABLE "Digest Inclusions" (
	"inclusion_id" INTEGER NOT NULL UNIQUE,
	"notification_id" INTEGER NOT NULL,
	"event_id" INTEGER NOT NULL,
	PRIMARY KEY("inclusion_id")
);

ALTER TABLE "notification"
ADD FOREIGN KEY("type_id") REFERENCES "Notification Types"("type_id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "notification"
ADD FOREIGN KEY("receptionist_id") REFERENCES "user"("user_id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "notification"
ADD FOREIGN KEY("campaign_id") REFERENCES "Campaigns"("campaign_id")
ON UPDATE NO ACTION ON DELETE SET NULL;

ALTER TABLE "notification"
ADD FOREIGN KEY("event_id") REFERENCES "event"("event_id")
ON UPDATE NO ACTION ON DELETE SET NULL;

ALTER TABLE "PREFERENCE"
ADD FOREIGN KEY("user_id") REFERENCES "user"("user_id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "PREFERENCE"
ADD FOREIGN KEY("type_id") REFERENCES "Notification Types"("type_id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "event"
ADD FOREIGN KEY("actor_id") REFERENCES "user"("user_id")
ON UPDATE NO ACTION ON DELETE SET NULL;

ALTER TABLE "Notification Deliveries"
ADD FOREIGN KEY("notification_id") REFERENCES "notification"("id")
ON UPDATE NO ACTION ON DELETE SET NULL;

ALTER TABLE "In App Notification States"
ADD FOREIGN KEY("notification_id") REFERENCES "notification"("id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "Digest Inclusions"
ADD FOREIGN KEY("notification_id") REFERENCES "notification"("id")
ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "Digest Inclusions"
ADD FOREIGN KEY("event_id") REFERENCES "event"("event_id")
ON UPDATE NO ACTION ON DELETE CASCADE;

-- Indexes on foreign key columns
CREATE INDEX "idx_notification_type_id" ON "notification"("type_id");
CREATE INDEX "idx_notification_receptionist_id" ON "notification"("receptionist_id");
CREATE INDEX "idx_notification_campaign_id" ON "notification"("campaign_id");
CREATE INDEX "idx_notification_event_id" ON "notification"("event_id");
CREATE INDEX "idx_preference_user_id" ON "PREFERENCE"("user_id");
CREATE INDEX "idx_preference_type_id" ON "PREFERENCE"("type_id");
CREATE INDEX "idx_event_actor_id" ON "event"("actor_id");
CREATE INDEX "idx_notification deliveries_notification_id" ON "Notification Deliveries"("notification_id");
CREATE INDEX "idx_in app notification states_notification_id" ON "In App Notification States"("notification_id");
CREATE INDEX "idx_digest inclusions_notification_id" ON "Digest Inclusions"("notification_id");
CREATE INDEX "idx_digest inclusions_event_id" ON "Digest Inclusions"("event_id");

-- Relationships as drawn
-- Notification Types.type_id -> notification.type_id (one-to-many)
-- Notification Types.type_id -> PREFERENCE.type_id (one-to-many)
-- PREFERENCE.user_id -> user.user_id (one-to-many)
-- event.event_id -> notification.event_id (one-to-many)
-- notification.receptionist_id -> user.user_id (one-to-many)
-- event.actor_id -> user.user_id (one-to-many)
-- notification.id -> In App Notification States.notification_id (one-to-one)
-- Notification Deliveries.notification_id -> notification.id (one-to-many)
-- Campaigns.campaign_id -> notification.campaign_id (one-to-many)
-- notification.id -> Digest Inclusions.notification_id (one-to-many)
-- event.event_id -> Digest Inclusions.event_id (one-to-many)