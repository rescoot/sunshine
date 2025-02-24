class CreateFeatureFlags < ActiveRecord::Migration[7.0]
  def change
    create_table :feature_flags do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :default_enabled, default: false
      t.timestamps
    end

    add_index :feature_flags, :key, unique: true
  end
end
