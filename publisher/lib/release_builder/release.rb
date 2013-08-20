require 'yaml'
require 'fileutils'

module UhuruProductBuilder
  class Release
    def initialize(release_name, tarball_name, version, release_dir, destination_dir)
      @release_name = release_name
      @tarball_name = tarball_name
      @release_dir = release_dir
      @destination_dir = destination_dir
      @version = version

    end

    def build
      Dir.chdir @release_dir

      set_release_name
      cleanup_release_dir
      update_git_submodules
      create_release
      change_release_version
      copy_to_destination
    end

    private

    def set_release_name
      config_file = File.join(@release_dir, 'config', 'dev.yml')
      dev_release_config_hash = {}
      dev_release_config_hash['dev_name'] = @release_name
      File.write(config_file, dev_release_config_hash.to_yaml)
    end

    def update_git_submodules
      `git submodule update --init --recursive`
    end

    def cleanup_release_dir
      Dir.rm_rf('dev_releases/*')
    end

    def create_release
      `bosh --non-interactive create release --with-tarball --force`

      File.mv('dev_releases/*.tgz', "dev_releases/#{@release_tarball}.tgz")
    end

    def change_release_version
      %x(

gunzip dev_releases/#{ @release_tarball }.tgz

cd dev_releases

tar xf dev_releases/#{ @release_tarball }.tar ./release.MF
cd ${CF_RELEASE_DIR}

if [ -e dev_releases/release.MF ]; then
    release_manifest_line_count=`cat dev_releases/release.MF | wc -l`
    head -n $(( ${release_manifest_line_count} - 1 )) dev_releases/release.MF > dev_releases/release.MF.tmp
fi

echo "version: ${CURRENT_VERSION}" >> dev_releases/release.MF.tmp
mv -f dev_releases/release.MF.tmp dev_releases/release.MF

tar --delete -f dev_releases/#{ @release_tarball }.tar ./release.MF
cd dev_releases
tar --append -f dev_releases/#{ @release_tarball }.tar ./release.MF
cd ${CF_RELEASE_DIR}

gzip -9 dev_releases/#{ @release_tarball }.tar
mv dev_releases/#{ @release_tarball }.tar.gz dev_releases/#{ @release_tarball }.tgz
      )

      Dir.chdir @release_dir
    end

    def copy_to_destination
      File.cp "dev_releases/#{ @release_tarball }.tgz", @destination_dir
    end
  end
end
