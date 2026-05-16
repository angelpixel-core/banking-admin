class CreateOutboxEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbox_events, id: :uuid do |t|
      t.string :event_name, null: false
      t.string :event_version, null: false
      t.string :event_id, null: false
      t.datetime :occurred_at, null: false
      t.string :correlation_id
      t.string :producer, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :state, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :next_attempt_at
      t.datetime :published_at
      t.text :last_error

      t.timestamps
    end

    add_index :outbox_events, :event_id, unique: true
    add_index :outbox_events, %i[state next_attempt_at]
    add_index :outbox_events, :correlation_id
  end
end
