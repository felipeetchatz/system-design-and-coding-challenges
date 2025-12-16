class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    
    create_table :notifications do |t|
      t.uuid :notification_id, null: false
      t.string :user_id, null: false, limit: 255
      t.string :channel, null: false, limit: 50
      t.string :template_id, null: false, limit: 255
      t.jsonb :variables
      t.string :status, null: false, limit: 50
      t.string :priority, default: 'normal', limit: 20
      t.timestamp :scheduled_at
      t.timestamp :queued_at, null: false
      t.timestamp :sent_at
      t.timestamp :delivered_at
      t.timestamp :failed_at
      t.integer :retry_count, default: 0
      t.integer :max_retries, default: 3
      t.text :error_message
      t.string :external_id, limit: 255

      t.timestamps
    end

    add_index :notifications, :notification_id, unique: true
    add_index :notifications, :user_id, name: 'idx_notifications_user_id'
    add_index :notifications, :status, name: 'idx_notifications_status'
    add_index :notifications, :channel, name: 'idx_notifications_channel'
    add_index :notifications, :scheduled_at, name: 'idx_notifications_scheduled_at', where: 'scheduled_at IS NOT NULL'
    add_index :notifications, :created_at, name: 'idx_notifications_created_at'
  end
end
