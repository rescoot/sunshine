class CreateUserFeatureFlags < ActiveRecord::Migration[7.0]
  def change
    create_table :user_feature_flags do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feature_flag, null: false, foreign_key: true
      t.boolean :enabled, null: false
      t.timestamps
    end

    add_index :user_feature_flags, [ :user_id, :feature_flag_id ], unique: true
  end
end
