class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :scooter, null: false, foreign_key: true

      t.string :token_digest
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
  end
end
