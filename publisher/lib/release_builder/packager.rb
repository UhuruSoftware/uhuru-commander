require 'yaml'
require 'fileutils'
require 'erb'
require 'tempfile'

module UhuruProductBuilder
  class Packager

    def initialize(target_directory, ucc_plugin_path)
      @target_directory = target_directory
      @ucc_plugin_path = ucc_plugin_path

      unless ENV['BUILD_NUMBER']
        ENV['BUILD_NUMBER'] = '0'
      end
    end

    def test
      prepare_destination_dir
      copy_ucc_plugin
      set_plugin_version
      package_bits
    end

    private

    def prepare_destination_dir
      FileUtils.mkdir_p @target_directory
      FileUtils.rm_rf Dir.glob(File.join(@target_directory, '*'))
    end

    def copy_ucc_plugin
      FileUtils.cp_r(Dir.glob(File.join(@ucc_plugin_path, '*')), @target_directory)
    end

    def set_plugin_version
      File.open(File.join(@target_directory, 'plugin.rb'), 'w') do |file|
        template = ERB.new(File.read(File.join(@target_directory, 'plugin.rb.erb')))
        result = template.result(binding)
        eval(result)
        file.write(result)
      end
    end

    def package_bits
      bits_file = Tempfile.new('bits').path
      `tar -czvf #{bits_file} -C #{@target_directory} .`

      prepare_destination_dir

      FileUtils.mv(bits_file, @target_directory)
    end

    # The following methods are exposed so we can load the plugin file in memory and grab the version.

    def name(_)

    end

    def file(_)

    end

    def object(_)

    end

    def version(ver)
      @version = ver
    end

    class Plugin
      # @param [Object] block
      def self.define(&block)
        block.call
      end
    end
  end
end

UhuruProductBuilder::Packager.new("/home/vladi/Desktop/beetmaster", "/home/vladi/Desktop/code/private-cf-release/ucc-plugin").test