class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :telegram_chat_id
      t.boolean :is_admin, default: false

      t.timestamps
    end
  end
end
