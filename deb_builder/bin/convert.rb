#!/usr/bin/env ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
$:.unshift(File.expand_path("../../lib", __FILE__))

require 'rubygems'
require 'bundler/setup'
require 'jobs/job.rb'
require 'packages/package.rb'


$config = YAML.load_file(File.expand_path('../../config/config.yml', __FILE__))


if ARGV[0] == 'packages'
  Uhuru::BOSH::Converter::Package.create_packages ARGV[1], ARGV[2], ARGV[3]
elsif ARGV[0] == 'jobs'
  Uhuru::BOSH::Converter::Job.create_jobs ARGV[1], ARGV[2]
elsif ARGV[0] == 'all'
else
  puts 'packages <target_dir> <source_dir> <release_file>'
  puts 'jobs <target_dir> <source_dir>'
end

