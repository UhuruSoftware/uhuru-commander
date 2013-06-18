require 'fileutils'
require 'yaml'
require 'erb'
require "cli"

module Uhuru
  module BOSH
    module Converter
      class Package
        DEB_PACKAGE_PREFIX = 'uhuru-bosh-package-'


        def self.create_packages(target_dir, source_dir, release_file)
          FileUtils.rm_rf target_dir
          FileUtils.mkdir_p target_dir

          Dir.glob(File.join(source_dir, '*')).each do |dir|
            if Dir.exist?(dir) && dir != '.' && dir != '..'
              pc = Uhuru::BOSH::Converter::Package.new(dir, target_dir, release_file)

              pc.setup_work_dir
              pc.create_control_file
              pc.copy_bits
              pc.generate_postinst
              pc.generate_postrm
              pc.create_deb
            end
          end
        end

        def version
          '1.0.0'
        end

        def get_blobstore_client
          bsc_provider= $config['blobstore_provider']
          bsc_options= $config['blobstore_options']

          Bosh::Blobstore::Client.create(bsc_provider, bsc_options)
        end

        def initialize(package_directory, work_directory, release_yml)
          puts "Processing package #{package_directory}..."

          @directory = package_directory

          load_package_spec

          @work_directory = File.join(work_directory, @spec['name'])
          @release = YAML.load_file(release_yml)
        end

        def self.generate_name(name)
          "#{DEB_PACKAGE_PREFIX}#{name.gsub(/_/, '-')}"
        end

        def load_package_spec
          puts 'Loading BOSH package spec...'

          spec_file = File.join(@directory, 'spec')
          @spec = YAML.load_file(spec_file)

          @spec['original_name'] = @spec['name']
          @spec['name'] = Package.generate_name(@spec['name'])
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

          package_name = @spec['name']
          package_version = version
          package_size = 0

          package_dependencies = ''

          unless @spec['dependencies'] == nil
            package_dependencies = @spec['dependencies'].map {|name| "#{Package.generate_name(name)} (=#{version})"}.join(', ')
          end

          package_short_description = "This is a dependency package for Uhuru Cloud Commander (package name is #{@spec['original_name']})"

          File.open(@struct['control_file'], 'w') do |file|
            file.write(template.result(binding))
          end
        end

        def copy_bits
          puts 'Copying bits...'

          source_dir = File.join(File.expand_path('../../src', @directory), @spec['original_name'])
          final_index = Bosh::Cli::VersionsIndex.new(
              File.join(File.expand_path('../../.final_builds/packages/', @directory), @spec['original_name']))

          if Dir.exist?(source_dir)
            FileUtils.cp_r source_dir, @struct['bits_dir'], :remove_destination => true
          end



          package = @release['packages'].find do |package|
            package['name'] == @spec['original_name']
          end

          blob_file = File.join(@struct['bits_dir'], 'blob.tar.gz')

          if package

            blobstore_id = final_index.find_by_checksum(package['sha1'])['blobstore_id']

            blobstore_client = get_blobstore_client

            if blobstore_client.exists?(blobstore_id)
              puts 'Downloading blob...'
              File.open(blob_file, "w") do |file|
                blobstore_client.get(blobstore_id, file)
              end

              puts 'Extracting blob...'
              `tar zxf #{blob_file} -C #{@struct['bits_dir']}`
              FileUtils.rm_f(blob_file)
            end
          end
        end

        def generate_postrm
          puts 'Generating postrm file...'

          erb_file = File.join(File.expand_path('..', __FILE__), 'postrm.erb')
          template = ERB.new File.new(erb_file).read

          package_name = @spec['original_name']
          package_version = version

          File.open(@struct['postrm_file'], 'w') do |file|
            file.write(template.result(binding))
          end

          `chmod 755 #{@struct['postrm_file']}`
        end

        def generate_postinst
          puts 'Generating postinst file...'
          erb_file = File.join(File.expand_path('..', __FILE__), 'postinst.erb')
          template = ERB.new File.new(erb_file).read

          package_name = @spec['original_name']
          package_version = version
          target_bits_dir = @struct['target_bits_dir']
          packaging = File.open(File.join(@directory, 'packaging'), 'r').read

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