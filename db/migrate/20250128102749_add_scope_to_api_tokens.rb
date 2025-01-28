class AddScopeToApiTokens < ActiveRecord::Migration[8.0]
  def change
    add_reference :api_tokens, :user, null: true, foreign_key: true
    add_column :api_tokens, :scope, :string
    add_index :api_tokens, :scope

    reversible do |dir|
      dir.up do
        ApiToken.update_all(scope: 'scooter')
        change_column_null :api_tokens, :scope, false
      end
    end
  end
end
