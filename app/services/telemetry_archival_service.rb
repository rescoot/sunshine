class TelemetryArchivalService
  # Number of months to keep in the main telemetry table
  MONTHS_TO_KEEP = 3

  class << self
    def archive_old_telemetries
      cutoff_date = MONTHS_TO_KEEP.months.ago.beginning_of_month

      # Create archive table if it doesn't exist
      ensure_archive_table_exists

      # Count records to be archived
      count = Telemetry.where("created_at < ?", cutoff_date).count

      return { archived: 0, message: "No telemetries to archive" } if count.zero?

      # Archive in batches to avoid memory issues
      batch_size = 1000
      total_archived = 0

      Telemetry.where("created_at < ?", cutoff_date).find_in_batches(batch_size: batch_size) do |batch|
        # Insert into archive table
        values = batch.map do |telemetry|
          attributes = telemetry.attributes
          # Convert attributes to SQL values string
          "(#{attributes.values.map { |v| ActiveRecord::Base.connection.quote(v) }.join(', ')})"
        end

        columns = batch.first.attributes.keys.join(", ")

        # Insert in a single SQL statement for efficiency
        ActiveRecord::Base.connection.execute(
          "INSERT INTO telemetries_archive (#{columns}) VALUES #{values.join(', ')}"
        )

        # Delete from main table
        Telemetry.where(id: batch.map(&:id)).delete_all

        total_archived += batch.size
        Rails.logger.info "Archived #{total_archived} of #{count} telemetries"
      end

      # Vacuum the database to reclaim space
      ActiveRecord::Base.connection.execute("VACUUM")

      { archived: total_archived, message: "Successfully archived #{total_archived} telemetries" }
    end

    def ensure_archive_table_exists
      unless ActiveRecord::Base.connection.table_exists?("telemetries_archive")
        # Get the schema from the main table
        columns = ActiveRecord::Base.connection.columns("telemetries")
        column_definitions = columns.map do |col|
          type = col.sql_type
          nullable = col.null ? "" : " NOT NULL"
          default = col.default.nil? ? "" : " DEFAULT #{ActiveRecord::Base.connection.quote(col.default)}"
          "#{col.name} #{type}#{nullable}#{default}"
        end.join(", ")

        # Create the archive table with the same schema
        ActiveRecord::Base.connection.execute(
          "CREATE TABLE telemetries_archive (#{column_definitions})"
        )

        # Add indexes to the archive table
        ActiveRecord::Base.connection.execute(
          "CREATE INDEX index_telemetries_archive_on_scooter_id ON telemetries_archive (scooter_id)"
        )
        ActiveRecord::Base.connection.execute(
          "CREATE INDEX index_telemetries_archive_on_created_at ON telemetries_archive (created_at)"
        )
      end
    end

    def fetch_archived_telemetries(scooter_id, start_date, end_date, limit = 1000)
      return [] unless ActiveRecord::Base.connection.table_exists?("telemetries_archive")

      sql = <<-SQL
        SELECT * FROM telemetries_archive
        WHERE scooter_id = ? AND created_at BETWEEN ? AND ?
        ORDER BY created_at DESC
        LIMIT ?
      SQL

      ActiveRecord::Base.connection.exec_query(
        sql, "SQL", [ [ nil, scooter_id ], [ nil, start_date ], [ nil, end_date ], [ nil, limit ] ]
      ).to_a
    end
  end
end
