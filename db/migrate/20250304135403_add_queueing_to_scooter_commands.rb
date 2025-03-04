class AddQueueingToScooterCommands < ActiveRecord::Migration[8.0]
  def change
    add_column :scooter_commands, :request_id, :string
    add_column :scooter_commands, :status, :string, default: "pending"
    add_column :scooter_commands, :queued, :boolean, default: false
    add_column :scooter_commands, :processed_at, :datetime
    add_column :scooter_commands, :expires_at, :datetime
    add_column :scooter_commands, :queueable, :boolean, default: true
    add_column :scooter_commands, :queue_ttl, :integer, default: 3600 # 1 hour in seconds

    add_index :scooter_commands, :request_id
    add_index :scooter_commands, [ :scooter_id, :queued, :status ], name: "index_scooter_commands_on_queue_status"
    add_index :scooter_commands, :expires_at
  end
end
