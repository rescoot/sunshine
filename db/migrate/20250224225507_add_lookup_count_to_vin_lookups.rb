class AddLookupCountToVinLookups < ActiveRecord::Migration[8.0]
  def change
    add_column :vin_lookups, :lookup_count, :integer, default: 0, null: false

    # Add an index on lookup_count for potential sorting/filtering
    add_index :vin_lookups, :lookup_count

    # Update existing records to have a lookup_count of 1
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE vin_lookups SET lookup_count = 1
        SQL
      end
    end
  end
end
