require 'uri'
require 'zlib'
require 'archive/tar/minitar'

module Uhuru
  module BoshCommander
    module Versioning
      STATE_REMOTE_ONLY = 1
      STATE_DOWNLOADING = 2
      STATE_LOCAL = 3
      STATE_LOCAL_PREPARING = 4
      STATE_AVAILABLE = 5
      STATE_DEPLOYED = 6

      class Version


        BITS_FILENAME = 'bits'

        attr_accessor :product
        attr_accessor :version
        attr_accessor :dependencies
        attr_accessor :deployments
        attr_accessor :location
        attr_accessor :description
        attr_accessor :size
        attr_accessor :missing

        attr_accessor :version_major
        attr_accessor :version_minor
        attr_accessor :version_build
        attr_accessor :version_type
        attr_accessor :version_location

        def initialize(product, version, details)
          @product = product
          @version = version
          @blob = details['location']
          @description = details['description']
          @dependencies = details['dependencies']
          @location = details['location']
          @size = details['location']['size']
          @missing = details['location']['missing']
          @deployments = nil
          get_version_identifiers
        end

        def get_version_identifiers
          identifiers = version.split('.')

          @version_major = identifiers[0]
          @version_minor = identifiers[1]
          @version_build = identifiers[2]
          @version_type = identifiers[3]
          @version_location = identifiers[4]
        end

        def version_dir
          products_dir = Product.version_directory
          product_dir = File.join(products_dir, @product.name)
          File.join(product_dir, @version.to_s)
        end

        def bits_full_local_path
          File.join(version_dir, BITS_FILENAME)
        end

        def bits_full_local_path_unpacked
          "#{bits_full_local_path}.unpacked"
        end

        def bits_full_local_path_dl
          "#{bits_full_local_path}.dl"
        end

        def get_state(stemcell_list = nil, release_list = nil, deployment_list = nil)
          state = STATE_REMOTE_ONLY

          if File.exist?(bits_full_local_path_dl)
            state = STATE_DOWNLOADING
          end

          if File.exist?(bits_full_local_path) || Dir.exist?(bits_full_local_path)
            state = STATE_LOCAL
          end

          if @product.type == 'ucc'
            if $config[:version] == @version
              state = STATE_DEPLOYED
            end
          elsif @product.type == 'stemcell'
            found_on_bosh = ( stemcell_list || Uhuru::BoshCommander::Stemcell.new().list_stemcells).any? do |stemcell|
              (stemcell['name'] == @product.name) && (stemcell['version'] == @version)
            end

            if found_on_bosh
              state = STATE_AVAILABLE
              deployments = deployment_list || Deployment.get_director_deployments
              deployments.each do |deployment|
                deployment["stemcells"].each do |stemcell|
                  if (stemcell["name"] == @product.name) &&
                      (stemcell["version"] == @version)
                    state = STATE_DEPLOYED
                    break
                  end
                end
                if (state == STATE_DEPLOYED)
                  break
                end
              end
            end

          elsif @product.type == 'software'
            if (state == STATE_LOCAL)

              bosh_releases = release_list || Uhuru::BoshCommander::Release.new().list_releases

              deployment_erb = File.read(File.join(bits_full_local_path, 'config', "#{@product.name}.yml.erb"))
              deployment_rendered = ERB.new(deployment_erb).result()
              deployment_yaml = YAML.load(deployment_rendered)

              releases = []
              if (deployment_yaml["release"])
                releases << deployment_yaml["release"]
              else
                deployment_yaml["releases"].each do |release|
                  releases << release
                end

              end

              releases.each do |release|
                bosh_releases.each do |bosh_release|
                  if (bosh_release['name'] == release['name'])
                    bosh_release['release_versions'].each do |release_version|
                      if release_version['version'] == @version.to_s
                        if (release_version['currently_deployed'])
                          state = STATE_DEPLOYED
                        else
                          state = STATE_AVAILABLE
                        end
                        break
                      end
                    end
                  end
                end
                if (state !=  STATE_DEPLOYED)
                  break
                end
              end
            end
          end

          state
        end

        def download_from_blobstore
          Thread.new do
            blobstore_client = Product.get_blobstore_client
            blobstore_id = @location['object_id']

            FileUtils.mkdir_p version_dir

            if blobstore_client.exists?(blobstore_id)
              open_mode = "wb"
              retry_count = 0
              done = false

              while !done && retry_count < 5
                File.open(bits_full_local_path_dl, open_mode) do |file|
                  begin
                    blobstore_client.get(blobstore_id, file)

                    raise "Download interruped for #{blobstore_id} at #{file.size} bytes out of #{@location['size']} bytes." if file.size < @location['size']

                    done = true
                  rescue => e
                    open_mode = "ab"
                    retry_count += 1
                    $logger.warn "There was an error while downloading #{product.name} v#{version}. Retrying... ##{retry_count}. Error was #{e.to_s}"
                    sleep 5
                  end
                end
              end

              unless done
                $logger.error "Could not download #{product.name} v#{version}."
                FileUtils.rm_f bits_full_local_path_dl
              end
            else
              $logger.warn "Could not find bits for #{product.name} v#{version}."
            end

            if @location['sha'] != Digest::SHA1.file(bits_full_local_path_dl).hexdigest
              $logger.error "Download of #{product.name} v#{version} failed signature check."
              FileUtils.rm_f bits_full_local_path_dl
            else
              begin
                if @product.type != Product::TYPE_STEMCELL
                  FileUtils.mkdir_p bits_full_local_path_unpacked
                  tgz = Zlib::GzipReader.new(File.open(bits_full_local_path_dl, 'rb'))
                  Minitar.unpack(tgz, bits_full_local_path_unpacked)
                  FileUtils.mv bits_full_local_path_unpacked, bits_full_local_path, :force => true
                  FileUtils.rm_f bits_full_local_path_dl
                else
                  FileUtils.mv bits_full_local_path_dl, bits_full_local_path, :force => true
                end
              rescue => e
                $logger.error "Could not unpack #{product.name} v#{version}."
                FileUtils.rm_f bits_full_local_path_unpacked
                FileUtils.rm_f bits_full_local_path
                FileUtils.rm_f bits_full_local_path_dl
              end
            end
          end
        end

        def download_progress
          if File.exist?(bits_full_local_path_dl)
            if Dir.exist?(bits_full_local_path_unpacked)
              [100, 'Unpacking ...']
            else
              total_size = @location['size']
              dl_size = File.size(bits_full_local_path_dl)
              [((dl_size.to_f / total_size.to_f) * 100).to_i, "#{dl_size / 1048576}MB out of #{total_size / 1048576}MB"]
            end
          else
            if Dir.exist?(bits_full_local_path_unpacked) || File.exist?(bits_full_local_path)
              [100, 'Done']
            else
              [0, 'N/A']
            end
          end
        end

        def delete_bits
          if get_state == STATE_LOCAL
            FileUtils.rm_rf bits_full_local_path
          else
            raise "Cannot remove bits for #{@product.name} version #{@version} since it's in use."
          end
        end

        def dependencies_ok?
          is_ok = true
          @dependencies.each do |dependency|
            product_name = dependency['dependency']
            versions = dependency['version']
            product = Product.get_products[product_name]

            if product
              is_ok = is_ok && versions.any? do |version|
                (product.versions[version] != nil) && (product.versions[version].get_state == STATE_AVAILABLE || product.versions[version].get_state == STATE_DEPLOYED)
              end
            else
              is_ok = false
            end
          end
          is_ok
        end

        #
        #   operator overloading for versioning objects
        #

        def <=>(other_version)
          self < other_version ? -1 : self == other_version ? 0 : 1
        end

        def ==(other_version)
          if other_version != nil
            if @version_major.to_i == other_version.version_major.to_i &&
                @version_minor.to_i == other_version.version_minor.to_i &&
                @version_build.to_i == other_version.version_build.to_i &&
                version_type_to_integer(@version_type) == version_type_to_integer(other_version.version_type) &&
                version_location_to_integer(@version_location) == version_location_to_integer(other_version.version_location)
              true
            else
              false
            end
          else
            false
          end
        end

        def <(other_version)
          if @version_major.to_i < other_version.version_major.to_i
            true
          elsif (@version_major.to_i == other_version.version_major.to_i) &&
              (@version_minor.to_i < other_version.version_minor.to_i)
            true
          elsif (@version_major.to_i == other_version.version_major.to_i) &&
              (@version_minor.to_i == other_version.version_minor.to_i) &&
              (@version_build.to_i < other_version.version_build.to_i)
            true
          elsif (@version_major.to_i == other_version.version_major.to_i) &&
              (@version_minor.to_i == other_version.version_minor.to_i) &&
              (@version_build.to_i == other_version.version_build.to_i) &&
              (version_type_to_integer(@version_type) < version_type_to_integer(other_version.version_type))
            true
          elsif (@version_major.to_i == other_version.version_major.to_i) &&
              (@version_minor.to_i == other_version.version_minor.to_i) &&
              (@version_build.to_i == other_version.version_build.to_i) &&
              (version_type_to_integer(@version_type) == version_type_to_integer(other_version.version_type)) &&
              (version_location_to_integer(@version_location) < version_location_to_integer(other_version.version_location))
            true
          else
            false
          end
        end

        def >(other_version)
          (!(self < other_version)) && (self != other_version)
        end

        private

        #returns a numeric value for the given type
        def version_type_to_integer(type = nil)

          version_type_values = {
              :f => 7,
              :rc => 6,
              :b => 5,
              :a => 4,
              :nb => 3,
              :pre => 2,
              :dev => 1
          }

          version_type_values[type.to_s.to_sym] || 0
        end

        #returns a numeric value for the giver location
        def version_location_to_integer(location = nil)
          version_location_values = {
              :r => 2,
              :a => 1
          }

          version_location_values[location.to_s.to_sym] || location.to_i
        end
      end
    end
  end
end
