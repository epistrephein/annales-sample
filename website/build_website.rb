#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates index.html from metrics.yml and the CSV slices directory.
# Run from the project root:  ruby website/build_website.rb

require "yaml"
require "erb"
require "csv"
require "cgi"
require "time"

ROOT_DIR      = Pathname.new(__dir__).parent
CSV_DIR       = ROOT_DIR.join("slices/csv")
METRICS_FILE  = ROOT_DIR.join("metrics/metrics.yml")
TEMPLATE_FILE = ROOT_DIR.join("website/template.erb")
OUTPUT_FILE   = ROOT_DIR.join("index.html")

METRICS  = YAML.load_file(METRICS_FILE)
RNG_SEED = 21275

MONTH_NAMES = %w[_ January February March April May June July
                 August September October November December].freeze

# Format number with commas as thousands separators
def format_number(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

# Escape HTML special characters in a string
def escape_html(string)
  CGI.escapeHTML(string.to_s)
end

# Read random seeded N data rows from a CSV file (returns [headers, rows])
def read_csv_sample(path, count = 5, seed = RNG_SEED)
  rows = CSV.read(path, headers: true)
  rng = Random.new(seed)

  sample = rows.each.to_a.sample([count, rows.length].min, random: rng)
  sample.sort_by! { |row| row["id"].to_i }

  [rows.headers, sample]
end

# Collect CSV slices grouped by source
csv_files = Dir.glob(CSV_DIR.join("*.csv")).map { |f| File.basename(f) }.sort
csv_by_source = csv_files.group_by { |f| f.split("-").first }

# Collect all years across both sources
all_years = (METRICS["ansa"]["yearly"].keys + METRICS["bbc"]["yearly"].keys).uniq.sort

# Read sample rows for the data preview section
ansa_headers, ansa_sample = read_csv_sample(CSV_DIR.join("ansa-2017-11.csv"))
bbc_headers, bbc_sample = read_csv_sample(CSV_DIR.join("bbc-2022-03.csv"))

snapshot_date = Time.parse(METRICS["snapshot_timestamp"]).strftime("%d %B %Y")

template = ERB.new(TEMPLATE_FILE.read, trim_mode: "-")
html = template.result(binding)

OUTPUT_FILE.write(html)
puts "Built #{OUTPUT_FILE}"
