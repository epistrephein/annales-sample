# frozen_string_literal: true

require "dotenv/load"
require "sequel"
require "yaml"

# Load database URL from environment variable
DB = Sequel.connect(ENV["DATABASE_URL"])

# Tables to process
TABLES = %w[ansa bbc].freeze

# Inclusive start, exclusive end
START_DATE = Time.utc(2017, 9, 1, 0, 0, 0)
END_DATE   = Time.utc(2026, 4, 1, 0, 0, 0)

# Output file for the generated metrics
OUTPUT_FILE = File.join(__dir__, "metrics.yml")

# Ensure all times are handled in UTC
Sequel.database_timezone    = :utc
Sequel.application_timezone = :utc

# Apply date filter once, reuse everywhere
def filtered_dataset(dataset, start_date:, end_date:)
  dataset
    .where(Sequel[:published] >= start_date)
    .where(Sequel[:published] < end_date)
end

# Count records grouped by year + month
def counts_by_month(dataset)
  year_expr  = Sequel.extract(:year, :published)
  month_expr = Sequel.extract(:month, :published)
  count_expr = Sequel.function(:count, Sequel.lit("*"))

  dataset
    .select(
      year_expr.as(:year),
      month_expr.as(:month),
      count_expr.as(:count)
    )
    .group(year_expr, month_expr)
    .order(year_expr, month_expr)
end

# Count records grouped by year
def counts_by_year(dataset)
  year_expr  = Sequel.extract(:year, :published)
  count_expr = Sequel.function(:count, Sequel.lit("*"))

  dataset
    .select(
      year_expr.as(:year),
      count_expr.as(:count)
    )
    .group(year_expr)
    .order(year_expr)
end

result = {}

TABLES.each do |table_name|
  # Build dataset safely from dynamic table name
  dataset  = DB.from(Sequel.identifier(table_name))
  filtered = filtered_dataset(dataset, start_date: START_DATE, end_date: END_DATE)

  # Nested hash: year => { month => count }
  monthly = Hash.new { |h, k| h[k] = {} }
  yearly  = {}

  # Fill monthly stats
  counts_by_month(filtered).each do |row|
    monthly[row[:year].to_i][row[:month].to_i] = row[:count]
  end

  # Fill yearly stats
  counts_by_year(filtered).each do |row|
    yearly[row[:year].to_i] = row[:count]
  end

  # Aggregate everything per table
  result[table_name] = {
    "total"   => filtered.count, # total rows in date range
    "yearly"  => yearly,
    "monthly" => monthly
  }
end

# Record the date this snapshot was computed
result["snapshot_timestamp"] = Time.now.utc.iso8601

# Write the result to a YAML file
File.write(OUTPUT_FILE, result.to_yaml)
puts "Written #{File.basename(OUTPUT_FILE)}"
