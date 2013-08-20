require 'yaml'
require 'fileutils'
require 'erb'

module UhuruProductBuilder
  class Packager

    class Plugin
      # @param [Object] block
      def self.define(&block)
        version = ''

        block.call

        version
      end
    end

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
    end

    private

    def prepare_destination_dir
      Dir.mkdir_p @target_directory
      Dir.rm_rf File.join(@target_directory, '*')
    end

    def copy_ucc_plugin
      File.cp_r(File.join(copy_ucc_plugin, '*'), @target_directory)
    end

    def set_plugin_version
      File.open(File.join(@target_directory, 'plugin.rb'), 'w') do |file|
        template = ERB.new(File.read(File.join(@target_directory, 'plugin.rb.erb')))
        @version = eval(template)
        file.write(template.result(binding))
      end
    end


  end
end

UhuruProductBuilder::Packager.new("/home/vladi/Desktop/beetmaster", "/home/vladi/Desktop/code/private-cf-release/ucc-plugin").test