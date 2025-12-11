class CreateShortUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :short_urls do |t|
      t.string :short_code, limit: 6, null: false
      t.text :original_url, null: false
      t.bigint :click_count, default: 0, null: false
      t.timestamp :last_accessed

      t.timestamps
    end

    add_index :short_urls, :short_code, unique: true, name: 'idx_short_code'
    add_index :short_urls, :created_at, name: 'idx_created_at'
  end
end