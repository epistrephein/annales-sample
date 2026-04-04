# frozen_string_literal: true

require "dotenv/load"
require "sequel"
require "yaml"
require "csv"

# Load database URL from environment variable
DB = Sequel.connect(ENV["DATABASE_URL"])

# Load slice definitions from YAML file
SLICES_YAML = File.join(__dir__, "slices.yml")
SLICES = YAML.load_file(SLICES_YAML)

# Output folder for generated CSVs
OUTPUT_DIR = File.join(__dir__, "csv")

# Create output directory if it doesn't exist
Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

# Ensure all times are handled in UTC
Sequel.database_timezone    = :utc
Sequel.application_timezone = :utc

SLICES.each do |table_name, year_months|
  dataset = DB.from(Sequel.identifier(table_name))

  year_months.each do |year, month|
    year  = year.to_i
    month = month.to_i

    # Inclusive start, exclusive end
    start_date =
      Time.utc(year, month, 1, 0, 0, 0)

    end_date =
      if month == 12
        Time.utc(year + 1, 1, 1, 0, 0, 0)
      else
        Time.utc(year, month + 1, 1, 0, 0, 0)
      end

    rows = dataset
      .where(Sequel[:published] >= start_date)
      .where(Sequel[:published] < end_date)
      .order(Sequel.asc(:published), Sequel.asc(:id))

    # Format filename as "table-YYYY-MM.csv"
    filename = format("%<table_name>s-%04<year>d-%02<month>d.csv",
                      table_name: table_name, year: year, month: month)
    output_file = File.join(OUTPUT_DIR, filename)

    CSV.open(output_file, "w", write_headers: true, headers: rows.columns) do |csv|
      rows.each do |row|
        csv << rows.columns.map { |column| row[column] }
      end
    end

    puts "Written #{filename}"
  end
end
