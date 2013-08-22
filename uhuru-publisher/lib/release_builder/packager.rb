require 'yaml'
require 'fileutils'
require 'erb'
require 'tempfile'
require File.expand_path('../release.rb', __FILE__)
require 'rdoc'

module UhuruProductBuilder
  class Packager

    def initialize(target_directory, ucc_plugin_path, product_name, release_type)
      @release_type = release_type
      @product_name = product_name
      @target_directory = target_directory
      @ucc_plugin_path = ucc_plugin_path
      @releases = []

      unless ENV['BUILD_NUMBER']
        ENV['BUILD_NUMBER'] = '0'
      end
    end

    def add_release(release_name, tarball_name, release_dir, git_repo = nil)
      @releases << [release_name, tarball_name, release_dir, git_repo]
    end

    def build
      prepare_destination_dir
      copy_ucc_plugin
      set_plugin_version
      build_releases
      package_bits
      publish
    end

    private

    def build_releases
      @releases.each do |release_name, tarball_name, release_dir, git_repo|
        if git_repo
          repo_path = clone_repo(git_repo, release_dir)
          release = UhuruProductBuilder::Release.new(release_name, tarball_name, @version, repo_path, @target_directory)
          release.build

        else
          release = UhuruProductBuilder::Release.new(release_name, tarball_name, @version, release_dir, @target_directory)
          release.build
        end
      end
    end

    def clone_repo(git_repo, repo_name)
      puts "Cloning repo '#{git_repo}'".green

      repo_path = File.expand_path("../#{repo_name}", @ucc_plugin_path)
      Dir.chdir(File.expand_path('../', @ucc_plugin_path))

      puts `
git clone #{git_repo}
cd #{repo_name}
git fetch --all
git reset --hard origin/master
`
      repo_path
    end

    def prepare_destination_dir
      puts "Preparing destination directory '#{@target_directory}'".green

      FileUtils.mkdir_p @target_directory
      FileUtils.rm_rf Dir.glob(File.join(@target_directory, '*'))
    end

    def copy_ucc_plugin
      puts "Copying ucc plugin from '#{@ucc_plugin_path}'".green
      FileUtils.cp_r(Dir.glob(File.join(@ucc_plugin_path, '*')), @target_directory)
    end

    def set_plugin_version
      puts "Configuring version...".green

      File.open(File.join(@target_directory, 'plugin.rb'), 'w') do |file|
        template = ERB.new(File.read(File.join(@target_directory, 'plugin.rb.erb')))
        result = template.result(binding)
        eval(result)
        file.write(result)
      end

      FileUtils.rm_f(File.join(@target_directory, 'plugin.rb.erb'))
      puts "  Version is '#{@version}'".green
    end

    def package_bits
      puts "Packaging bits... This will take some time.".yellow

      bits_file = Tempfile.new('bits').path
      puts `tar -czvf #{bits_file} -C #{@target_directory} .`

      prepare_destination_dir

      FileUtils.mv(bits_file, File.join(@target_directory, 'bits.tgz'))
    end

    def description
      description = ""

      changelog_path = File.join(@ucc_plugin_path, 'Changelog')

      top_level = RDoc::TopLevel.new(changelog_path)
      rdoc_options = RDoc::Options.new

      parser = RDoc::Parser::ChangeLog.new(top_level, changelog_path, File.read(changelog_path), rdoc_options, nil)

      if (parser.parse_entries) && (parser.parse_entries[0])
        parser.parse_entries[0][1].each do |item|
          description = "#{description}<li>#{item}</li>"
        end
      end

      "<ul style='padding-left:16px'>#{description}</ul>"
    end

    def publish
      puts "Publishing bits to blobstore... This will take some time.".yellow

      bin = File.expand_path('../../../bin/uhuru-publisher', __FILE__)

      `#{bin} upload version -n #{@product_name} -r #{@version} -t #{@release_type} -d "#{description}" -f #{File.join(@target_directory, 'bits.tgz')}`


      YAML.load_file(File.join(@ucc_plugin_path, 'config', 'dependencies.yml')).each do |product, versions|
        versions.each do |version|
          `#{bin} add dependency -n #{@product_name} -r #{@version} -d #{product} -s #{version}`
        end
      end
      puts "Done.".yellow
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