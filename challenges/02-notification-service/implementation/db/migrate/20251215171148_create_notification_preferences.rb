class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.string :user_id, null: false, limit: 255
      t.string :channel, null: false, limit: 50
      t.string :notification_type, null: false, limit: 100
      t.boolean :enabled, default: true
      t.time :quiet_hours_start
      t.time :quiet_hours_end
      t.string :timezone, limit: 50

      t.timestamps
    end

    add_index :notification_preferences, :user_id, name: 'idx_preferences_user_id'
    add_index :notification_preferences, [:user_id, :channel, :notification_type], unique: true, name: 'index_notification_preferences_on_user_channel_type'
  end
end