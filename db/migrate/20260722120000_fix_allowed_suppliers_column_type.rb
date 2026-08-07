class FixAllowedSuppliersColumnType < ActiveRecord::Migration[8.1]
  # An early deploy ran the original version of AddPermissionsToUsers, which
  # created `allowed_suppliers` as a native Postgres array column. The
  # migration file was later fixed to use :text (for SQLite compatibility),
  # but that fix never reaches an already-migrated database — Rails only
  # replays a migration's *current* code on databases that haven't applied
  # that version yet. Production kept the native array column while the
  # User model moved to `serialize ..., coder: JSON, type: Array`, which
  # raises ColumnNotSerializableError on any query touching a User — this
  # is what took down login. Convert the column to text if (and only if)
  # it is still the old native array type.
  def up
    column = connection.columns(:users).find { |c| c.name == "allowed_suppliers" }
    return unless column && column.sql_type_metadata.type == :string && column.array?

    execute <<~SQL
      ALTER TABLE users
      ALTER COLUMN allowed_suppliers TYPE text
      USING array_to_json(allowed_suppliers)::text,
      ALTER COLUMN allowed_suppliers SET DEFAULT '[]'
    SQL
  end

  def down
    # Data fix only — no rollback to the native array type.
  end
end
