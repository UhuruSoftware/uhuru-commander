#!/usr/bin/env ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
$:.unshift(File.expand_path("../../lib", __FILE__))

require 'rubygems'
require 'bundler/setup'
require 'jobs/job.rb'
require 'packages/package.rb'


$config = YAML.load_file(File.expand_path('../../config/config.yml', __FILE__))


def do_packages(target_dir, release_version)
  `rm -rf #{target_dir}/uhuru-bosh-package-*`
  source_dir = File.expand_path('../../../modules/private-bosh/release', __FILE__)
  release_file = File.expand_path("../../../modules/private-bosh/release/dev_releases/bosh-#{release_version}.yml", __FILE__)

  Uhuru::BOSH::Converter::Package.create_packages target_dir, source_dir, release_file
end

def do_jobs(target_dir, release_version)
  `rm -rf #{target_dir}/uhuru-bosh-job-*`
  source_dir = File.expand_path('../../../modules/private-bosh/release', __FILE__)
  release_file = File.expand_path("../../../modules/private-bosh/release/dev_releases/bosh-#{release_version}.yml", __FILE__)

  Uhuru::BOSH::Converter::Job.create_jobs target_dir, source_dir, release_file
end

def do_web(target_dir)
  uhuru_utils_path = File.expand_path('../uhuru-utils.sh', __FILE__)
  source_dir = File.expand_path('../../../', __FILE__)

  `#{uhuru_utils_path} "#{source_dir}" "#{target_dir}" "#{$config['version']}"`
end


if ARGV[0] == 'packages'
  do_packages ARGV[1], ARGV[2]
elsif ARGV[0] == 'jobs'
  do_jobs ARGV[1], ARGV[2]
elsif ARGV[0] == 'web'
  do_web ARGV[1]
elsif ARGV[0] == 'all'
  do_packages ARGV[1], ARGV[2]
  do_jobs ARGV[1], ARGV[2]
  do_web ARGV[1]
else
  puts 'packages <target_dir> <release_version>'
  puts 'jobs <target_dir> <release_version>'
  puts 'web <target_dir>'
  puts 'all <target_dir> <release_version>'
end

