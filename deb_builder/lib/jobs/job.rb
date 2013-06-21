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

        def self.create_jobs(target_dir, release_dir, release_file)

          all_jobs = []
          @release = YAML.load_file(release_file)

          @release['jobs'].each do |job|
            job_dir = File.join(release_dir, '.dev_builds', 'jobs', job['name'])
            job_final_dir = File.join(release_dir, '.final_builds', 'jobs', job['name'])

            pc = Uhuru::BOSH::Converter::Job.new(job_dir, job_final_dir, target_dir, job)

            pc.setup_work_dir
            pc.copy_bits
            pc.create_control_file
            pc.generate_postinst
            pc.generate_postrm
            pc.create_deb
            all_jobs << pc.spec['name']

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

          job_dependencies = all_jobs.map {|name| "#{name} (=#{Job.version})"}.uniq.join(', ')

          job_short_description = 'Uhuru Cloud Commander'

          File.open(control_file, 'w') do |file|
            file.write(template.result(binding))
          end

          `cd #{target_dir} ; dpkg-deb --build uhuru-ucc`

          puts 'Done.'
        end

        def self.version
          $config['version']
        end

        def initialize(job_directory, job_final_directory, work_directory, job_manifest)
          puts "Processing job #{job_directory}..."

          @job_meta = job_manifest
          @directory = job_directory
          @directory_final = job_final_directory

          load_job_spec

          @work_directory = File.join(work_directory, @spec['name'])
        end

        def self.generate_name(name)
          "#{DEB_JOB_PREFIX}#{name.gsub(/_/, '-')}"
        end

        def load_job_spec
          puts 'Loading BOSH job spec...'

          spec_file = File.join(@directory, 'spec')
          @spec = {}

          @spec['original_name'] = @job_meta['name']
          @spec['name'] = Job.generate_name(@job_meta['name'])
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

          deps = @spec['packages']
          deps << 'ruby'

          unless @spec['packages'] == nil
            job_dependencies = @spec['packages'].map {|name| "#{Package.generate_name(name)} (=#{Job.version})"}.uniq.join(', ')
          end

          job_short_description = "This is an Uhuru Cloud Commander job (job name is #{@spec['original_name']})"

          File.open(@struct['control_file'], 'w') do |file|
            file.write(template.result(binding))
          end
        end

        def copy_bits
          #FileUtils.cp_r(File.join(@directory, 'templates'), @struct['bits_dir'], :remove_destination => true)
          #FileUtils.cp_r(File.join(@directory, 'spec'), @struct['bits_dir'], :remove_destination => true)
          #FileUtils.cp_r(File.join(@directory, 'monit'), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../generate_templates.rb', __FILE__), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../defaults.yml', __FILE__), @struct['bits_dir'], :remove_destination => true)
          FileUtils.cp_r(File.expand_path('../../../../modules/private-bosh/bosh_common/lib/common/properties', __FILE__), @struct['bits_dir'], :remove_destination => true)

          tgz_file = File.join(@directory, "#{@job_meta['version']}.tgz")

          if File.exist?(tgz_file)
            `tar zxf #{tgz_file} -C #{@struct['bits_dir']}`
          else
            tgz_file = File.join(@directory_final, "#{@job_meta['version']}.tgz")
            `tar zxf #{tgz_file} -C #{@struct['bits_dir']}`
          end

          job_mf_file = File.join(@struct['bits_dir'], 'job.MF')
          spec_file = File.join(@struct['bits_dir'], 'spec')

          FileUtils.mv job_mf_file, spec_file

          @spec['packages'] = YAML.load_file(spec_file)['packages']
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

