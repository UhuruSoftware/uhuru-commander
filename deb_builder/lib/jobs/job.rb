require 'fileutils'
require 'yaml'
require 'erb'
require "cli"
require File.expand_path('../../packages/package.rb', __FILE__)

module Uhuru
  module BOSH
    module Converter
      class Job
        DEB_JOB_PREFIX = 'uhuru-bosh-job-'

        attr_accessor :spec


        def self.create_jobs(target_dir, source_dir)

          FileUtils.rm_rf target_dir
          FileUtils.mkdir_p target_dir

          all_jobs = []

          Dir.glob(File.join(source_dir, '*')).each do |dir|
            if Dir.exist?(dir) && dir != '.' && dir != '..'
              pc = Uhuru::BOSH::Converter::Job.new(dir, target_dir)

              pc.setup_work_dir
              pc.create_control_file
              pc.copy_bits
              pc.generate_postinst
              pc.generate_postrm
              pc.create_deb

              all_jobs << pc.spec['name']
            end
          end

          puts 'Creating master package ...'

          work_directory = File.join(target_dir, 'uhuru-ucc')
          debian_dir = File.join(work_directory, 'DEBIAN')
          control_file = File.join(debian_dir, 'control')

          FileUtils.mkdir_p work_directory
          FileUtils.mkdir_p debian_dir

          erb_file = File.join(File.expand_path('..', __FILE__), 'uhuru-ucc-control.erb')
          template = ERB.new File.new(erb_file).read

          job_version = Job.version
          job_size = 0

          job_dependencies = all_jobs.map {|name| "#{name} (=#{Job.version})"}.join(', ')

          job_short_description = 'Uhuru Cloud Commander'

          File.open(control_file, 'w') do |file|
            file.write(template.result(binding))
          end

          `cd #{target_dir} ; dpkg-deb --build uhuru-ucc`

          puts 'Done.'
        end

        def self.version
          '1.0.0'
        end

        def initialize(job_directory, work_directory)
          puts "Processing job #{job_directory}..."

          @directory = job_directory

          load_package_spec

          @work_directory = File.join(work_directory, @spec['name'])
        end

        def self.generate_name(name)
          "#{DEB_JOB_PREFIX}#{name.gsub(/_/, '-')}"
        end

        def load_package_spec
          puts 'Loading BOSH job spec...'

          spec_file = File.join(@directory, 'spec')
          @spec = YAML.load_file(spec_file)

          @spec['original_name'] = @spec['name']
          @spec['name'] = Job.generate_name(@spec['name'])
        end

        def setup_work_dir
          puts 'Setting up working directory...'
          @struct = {}
          @struct['debian_dir'] = File.join(@work_directory, 'DEBIAN')
          @struct['control_file'] = File.join(@struct['debian_dir'], 'control')
          @struct['postinst_file'] = File.join(@struct['debian_dir'], 'postinst')
          @struct['postrm_file'] = File.join(@struct['debian_dir'], 'postrm')
          @struct['target_bits_dir'] = "usr/src/uhuru/#{@spec['name']}"
          @struct['bits_dir'] = File.join(@work_directory, @struct['target_bits_dir'])

          FileUtils.mkdir_p @work_directory
          FileUtils.mkdir_p @struct['bits_dir']
          FileUtils.mkdir_p @struct['debian_dir']
        end

        def create_control_file
          puts 'Creating control file...'
          erb_file = File.join(File.expand_path('..', __FILE__), 'control.erb')
          template = ERB.new File.new(erb_file).read

          job_name = @spec['name']
          job_version = Job.version
          job_size = 0

          job_dependencies = ''

          unless @spec['packages'] == nil
            job_dependencies = @spec['packages'].map {|name| "#{Package.generate_name(name)} (=#{Job.version})"}.join(', ')
          end

          job_short_description = "This is an Uhuru Cloud Commander job (job name is #{@spec['original_name']})"

          File.open(@struct['control_file'], 'w') do |file|
            file.write(template.result(binding))
          end
        end

        def copy_bits
          FileUtils.cp_r(File.join(@directory, 'templates'), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.join(@directory, 'spec'), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.join(@directory, 'monit'), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../generate_templates.rb', __FILE__), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../defaults.yml', __FILE__), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../../../../modules/private-bosh/bosh_common/lib/common/properties', __FILE__), @struct['bits_dir'], :remove_destination => true)
        end

        def generate_postrm
          puts 'Generating postrm file...'

          erb_file = File.join(File.expand_path('..', __FILE__), 'postrm.erb')
          template = ERB.new File.new(erb_file).read

          job_name = @spec['original_name']
          job_version = Job.version

          File.open(@struct['postrm_file'], 'w') do |file|
            file.write(template.result(binding))
          end

          `chmod 755 #{@struct['postrm_file']}`
        end

        def generate_postinst
          puts 'Generating postinst file...'
          erb_file = File.join(File.expand_path('..', __FILE__), 'postinst.erb')
          template = ERB.new File.new(erb_file).read

          job_name = @spec['original_name']
          job_version = Job.version
          target_bits_dir = @struct['target_bits_dir']

          File.open(@struct['postinst_file'], 'w') do |file|
            file.write(template.result(binding))
          end

          `chmod 755 #{@struct['postinst_file']}`
        end

        def create_deb
          puts 'Building deb package...'

          deb_dir = File.expand_path('..', @work_directory)
          `cd #{deb_dir} ; dpkg-deb --build #{@spec['name']}`
        end
      end
    end
  end
end

