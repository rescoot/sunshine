class CreateAchievementSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :achievement_definitions do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :achievement_type, null: false
      t.float :threshold, null: false
      t.string :icon, null: false
      t.integer :points, default: 10
      t.string :badge_color, default: "blue"

      t.timestamps
    end

    add_index :achievement_definitions, :achievement_type

    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement_definition, null: false, foreign_key: true
      t.datetime :earned_at
      t.float :progress, default: 0.0

      t.timestamps

      t.index [ :user_id, :achievement_definition_id ], unique: true
    end
  end
end
