# frozen_string_literal: true

require "bundler/setup"

desc "Compute metrics from the database"
task :metrics do
  sh "ruby metrics/compute_metrics.rb"
end

desc "Generate charts from the metrics"
task :charts do
  sh "python charts/plot_charts.py"
end

desc "Slice the database"
task :slices do
  sh "ruby slices/slice_database.rb"
end

desc "Build the website"
task :website do
  sh "ruby website/build_website.rb"
end

desc "Run the full build pipeline"
task build: [:metrics, :charts, :slices, :website]

task default: :build
