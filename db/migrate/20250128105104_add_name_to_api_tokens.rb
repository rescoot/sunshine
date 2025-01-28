class AddNameToApiTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :api_tokens, :name, :string
  end
end
