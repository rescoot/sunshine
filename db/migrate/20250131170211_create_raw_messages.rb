class CreateRawMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :raw_messages do |t|
      t.string :imei, null: false, index: true
      t.string :topic, null: false
      t.json :payload
      t.datetime :received_at, null: false

      t.timestamps
    end
  end
end
