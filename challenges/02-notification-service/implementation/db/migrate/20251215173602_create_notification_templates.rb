class CreateNotificationTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_templates do |t|
      t.string :template_id, null: false, limit: 255
      t.string :channel, null: false, limit: 50
      t.string :subject, limit: 500
      t.text :body, null: false
      t.jsonb :variables
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :notification_templates, :template_id, unique: true, name: 'idx_templates_template_id'
    add_index :notification_templates, :channel, name: 'idx_templates_channel'
  end
end