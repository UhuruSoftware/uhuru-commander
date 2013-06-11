require 'uri'

module Uhuru
  module BoshCommander
    module Versioning
      class Version
        STATE_REMOTE_ONLY = 1
        STATE_DOWNLOADING = 2
        STATE_LOCAL = 3
        STATE_LOCAL_PREPARING = 4
        STATE_AVAILABLE = 5
        STATE_DEPLOYED = 6

        attr_accessor :product
        attr_accessor :version
        attr_accessor :dependencies
        attr_accessor :dependencies
        attr_accessor :deployments

        def initialize(product, version, details)
          @product = product
          @version = version
          @blob = details['location']
          @dependencies = details['dependencies']
          @deployments = nil
        end

        def get_state
          state = STATE_REMOTE_ONLY
          bits_filename = URI(@blob).path
          products_dir = Product.version_directory
          product_dir = File.join(products_dir, @product.name)
          version_dir = File.join(product_dir, @version)
          bits_full_local_path = File.join(version_dir, bits_filename)
          bits_full_local_path_dl = "#{bits_full_local_path}.dl"

          if File.exist?(bits_full_local_path_dl)
            state = STATE_DOWNLOADING
          end

          if File.exist?(bits_full_local_path)
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
            end
          end

          state
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
