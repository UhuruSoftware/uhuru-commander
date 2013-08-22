require 'yaml'
require 'fileutils'

module UhuruProductBuilder
  class Release
    def initialize(release_name, release_tarball, version, release_dir, destination_dir)
      @release_name = release_name
      @release_tarball = release_tarball
      @release_dir = release_dir
      @destination_dir = destination_dir
      @version = version

    end

    def build
      Dir.chdir @release_dir

      puts "Building release #{@release_name}".magenta
      puts "  Tarball name is:          #{@release_tarball}".cyan
      puts "  Release directory is:     #{@release_dir}".cyan
      puts "  Destination directory is: #{@destination_dir}".cyan
      puts "  Version is:               #{@version}".cyan

      set_release_name
      cleanup_release_dir
      update_git_submodules
      create_release
      change_release_version
      copy_to_destination
    end

    private

    def set_release_name
      puts "Changing release name to '#{@release_name}'".green

      config_file = File.join(@release_dir, 'config', 'dev.yml')
      dev_release_config_hash = {}
      dev_release_config_hash['dev_name'] = @release_name
      File.write(config_file, dev_release_config_hash.to_yaml)
    end

    def update_git_submodules
      puts "Updating git submodules... This could take a while.".yellow
      puts `git submodule update --init --recursive`
    end

    def cleanup_release_dir
      puts "Cleaning up dev releases directory.".green
      FileUtils.rm_rf(Dir.glob(File.join(Dir.pwd, 'dev_releases', '*')))
    end

    def create_release
      puts "Setting up a ucc version package to help with rebase.".green

      Dir.mkdir(File.join(@release_dir, 'packages', 'ucc_version_pack'))
      File.write(File.join(@release_dir, 'packages', 'ucc_version_pack', 'packaging'), 'set -e')
      File.write(File.join(@release_dir, 'packages', 'ucc_version_pack', 'pre_packaging'), 'set -e')
      ucc_version_pack_spec = {}
      ucc_version_pack_spec['name'] = 'ucc_version_pack'
      ucc_version_pack_spec['files'] = ['ucc_version_pack/**/*']
      File.write(File.join(@release_dir, 'packages', 'ucc_version_pack', 'spec'), ucc_version_pack_spec.to_yaml)

      Dir.mkdir(File.join(@release_dir, 'src', 'ucc_version_pack'))
      File.write(File.join(@release_dir, 'src', 'ucc_version_pack', 'version'), {'version' => @version}.to_yaml)

      puts "Creating BOSH release... This will take some time.".yellow

      puts `bosh --non-interactive create release --with-tarball --force`

      File.rename(
          Dir.glob(File.join(Dir.pwd, 'dev_releases', '*.tgz'))[0],
          File.join(Dir.pwd, 'dev_releases', "#{@release_tarball}.tgz"))

      puts "Cleaning up the ucc version package.".green
      FileUtils.rm_f(File.join(@release_dir, 'packages', 'ucc_version_pack'))
      FileUtils.rm_f(File.join(@release_dir, 'src', 'ucc_version_pack'))
    end

    def change_release_version
      puts "Changing release version to '#{@version}'".green

      puts "Changing version for '#{@release_name}'"

      dev_releases = File.join(@release_dir, 'dev_releases')

      Dir.chdir @release_dir
      `gunzip #{File.join(dev_releases, "#{@release_tarball}.tgz") } 2>&1`

      FileUtils.rm_f(Dir.glob(File.join(@release_dir, 'dev_releases', '*.tgz')))
      FileUtils.rm_f(Dir.glob(File.join(@release_dir, 'dev_releases', '*.yml')))
      FileUtils.rm_f(Dir.glob(File.join(@release_dir, 'dev_releases', '*.MF')))
      FileUtils.rm_f(Dir.glob(File.join(@release_dir, 'dev_releases', '*.tar.gz')))

      Dir.chdir dev_releases
      `tar xf #{ @release_tarball }.tar ./release.MF 2>&1`

      Dir.chdir @release_dir

      if File.exists?(File.join(dev_releases, 'release.MF'))
        manifest = YAML.load_file(File.join(dev_releases, 'release.MF'))
        manifest['version'] = @version
        File.write(File.join(dev_releases, 'release.MF'), manifest.to_yaml)
      end

      `tar --delete -f #{ File.join(dev_releases, "#{@release_tarball}.tar") } ./release.MF 2>&1`

      Dir.chdir dev_releases

      `tar --append -f #{ File.join(dev_releases, "#{@release_tarball}.tar") } ./release.MF 2>&1`

      Dir.chdir @release_dir
      `gzip -9 #{ File.join(dev_releases, "#{@release_tarball}.tar") } 2>&1`

      File.rename(
          File.join(dev_releases, "#{@release_tarball}.tar.gz"),
          File.join(dev_releases, "#{@release_tarball}.tgz"))
    end

    def copy_to_destination
      puts "Moving release to destination directory.".green
      FileUtils.move File.join(Dir.pwd, 'dev_releases', "#{@release_tarball }.tgz"), @destination_dir
    end
  end
end
