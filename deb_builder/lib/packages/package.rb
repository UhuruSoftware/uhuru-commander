require 'fileutils'
require 'yaml'
require 'erb'
require "cli"

module Uhuru
  module BOSH
    module Converter
      class Package
        DEB_PACKAGE_PREFIX = 'uhuru-bosh-package-'


        def self.create_packages(target_dir, release_dir, release_file)
          @release = YAML.load_file(release_file)

          @release['packages'].each do |package|
            package_dir = File.join(release_dir, '.dev_builds', 'packages', package['name'])
            package_final_dir = File.join(release_dir, '.final_builds', 'packages', package['name'])

            pc = Uhuru::BOSH::Converter::Package.new(package_dir, package_final_dir, target_dir, package)

            pc.setup_work_dir
            pc.create_control_file
            pc.copy_bits
            pc.generate_postinst
            pc.generate_postrm
            pc.create_deb
          end
        end

        def version
          $config['version']
        end

        def get_blobstore_client
          bsc_provider= $config['blobstore_provider']
          bsc_options= $config['blobstore_options']

          Bosh::Blobstore::Client.create(bsc_provider, bsc_options)
        end

        def initialize(package_directory, package_final_directory, work_directory, package_meta)
          puts "Processing package #{package_directory}..."

          @directory = package_directory
          @directory_final = package_final_directory
          @package_meta = package_meta
          load_package_spec
          @work_directory = File.join(work_directory, @spec['name'])
        end

        def self.generate_name(name)
          "#{DEB_PACKAGE_PREFIX}#{name.gsub(/_/, '-')}"
        end

        def load_package_spec
          puts 'Loading BOSH package spec...'

          @spec = {}

          @spec['original_name'] = @package_meta['name']
          @spec['name'] = Package.generate_name(@package_meta['name'])
          @spec['dependencies'] = @package_meta['dependencies']
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
          package_size = $config['deb_sizes']['package'][@spec['original_name']] || 0

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

          tgz_file = File.join(@directory, "#{@package_meta['version']}.tgz")

          if File.exist?(tgz_file)
            `tar zxf #{tgz_file} -C #{@struct['bits_dir']}`
          else
            tgz_file = File.join(@directory_final, "#{@package_meta['version']}.tgz")
            `tar zxf #{tgz_file} -C #{@struct['bits_dir']}`
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

          blob_packaging_file = File.join(@struct['bits_dir'], 'packaging')
          if File.exist?(blob_packaging_file)
            packaging = File.open(blob_packaging_file, 'r').read
          else
            packaging = File.open(File.join(@directory, 'packaging'), 'r').read
          end

          File.open(@struct['postinst_file'], 'w') do |file|
            file.write(template.result(binding))
          end

          `chmod 755 #{@struct['postinst_file']}`
        end

        def create_deb
          puts 'Building deb package...'

          deb_dir = File.expand_path('..', @work_directory)
          `cd #{deb_dir} ; dpkg-deb --build #{@spec['name']} .`
        end
      end
    end
  end
end