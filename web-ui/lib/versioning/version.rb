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

        def initialize(product, version, details)
          @product = product
          @version = version
          @blob = details['location']
          @description = details['description']
          @dependencies = details['dependencies']
          @location = details['location']
          @deployments = nil
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

        def get_state
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
            found_on_bosh = Uhuru::BoshCommander::Stemcell.new().list_stemcells.any? do |stemcell|
              (stemcell['name'] == @product.name) && (stemcell['version'] == @version)
            end

            if found_on_bosh
              state = STATE_AVAILABLE
              deployments = Deployment.get_director_deployments
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
            bosh_releases = Uhuru::BoshCommander::Release.new().list_releases

            bosh_releases.each do |release|
              if (release['name'] == @product.name)
                release['release_versions'].each do |release_version|
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
          end

          state
        end

        def download_from_blobstore
          Thread.new do
            blobstore_client = Product.get_blobstore_client
            blobstore_id = @location['object_id']

            FileUtils.mkdir_p version_dir

            if blobstore_client.exists?(blobstore_id)
              File.open(bits_full_local_path_dl, "w") do |file|
                blobstore_client.get(blobstore_id, file)
              end
            else
              raise "Could not find bits on blobstore."
            end

            if @product.type != Product::TYPE_STEMCELL
              FileUtils.mkdir_p bits_full_local_path_unpacked
              tgz = Zlib::GzipReader.new(File.open(bits_full_local_path_dl, 'rb'))
              Minitar.unpack(tgz, bits_full_local_path_unpacked)
              FileUtils.mv bits_full_local_path_unpacked, bits_full_local_path, :force => true
              FileUtils.rm_f bits_full_local_path_dl
            else
              FileUtils.mv bits_full_local_path_dl, bits_full_local_path, :force => true
            end
          end
        end

        def download_progress
          if File.exist?(bits_full_local_path_dl)
            total_size = @location['size']
            dl_size = File.size(bits_full_local_path_dl)
            [(dl_size / total_size) * 100, "Downloaded #{dl_size / 1048576}MB out of #{total_size / 1048576}MB"]
          else
            if Dir.exist?(bits_full_local_path_unpacked)
              if File.exist?(bits_full_local_path_dl)
                [100, 'Unpacking...']
              else
                [100, 'Done']
              end
            elsif File.exist?(bits_full_local_path)
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
      end
    end
  end
end
