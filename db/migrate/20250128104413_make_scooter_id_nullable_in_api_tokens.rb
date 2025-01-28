class MakeScooterIdNullableInApiTokens < ActiveRecord::Migration[8.0]
  def change
    change_column_null :api_tokens, :scooter_id, true
  end
end
