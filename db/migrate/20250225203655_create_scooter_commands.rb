class CreateScooterCommands < ActiveRecord::Migration[8.0]
  def change
    create_table :scooter_commands do |t|
      t.references :scooter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :command
      t.json :params, default: {}

      t.timestamps
    end
  end
end
