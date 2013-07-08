require 'fileutils'
require 'yaml'

module Uhuru
  module BoshCommander
    module Versioning
      class Product
        BLOBSTORE_ID_PRODUCTS = "products.yml"

        TYPE_STEMCELL = 'stemcell'
        TYPE_SOFTWARE = 'software'
        TYPE_UCC = 'ucc'

        attr_accessor :name
        attr_accessor :label
        attr_accessor :description
        attr_accessor :versions
        attr_accessor :type

        def self.version_directory
          dir = $config[:versioning][:dir]
          FileUtils.mkdir_p(dir)
          dir
        end

        def self.get_products
          dir = Product.version_directory
          products_yaml_file = File.join(dir, 'products.yml')

          if File.exist? products_yaml_file
            products_yaml = YAML.load_file(products_yaml_file)
            products = {}
            products_yaml['products'].each do |product, details|
              products[product] = Product.new(product, details['label'], details['type'], details['description'])
            end
            products
          else
            {}
          end
        end

        def self.get_blobstore_client
          bsc_provider= $config[:versioning][:blobstore_provider]
          bsc_options= $config[:versioning][:blobstore_options]

          Bosh::Blobstore::Client.create(bsc_provider, bsc_options)
        end

        def self.download_manifests
          dir = Product.version_directory

          temp_dir = Dir.mktmpdir
          products_yaml_file = File.join(temp_dir, 'products.yml')

          if get_blobstore_client.exists?(BLOBSTORE_ID_PRODUCTS)
            File.open(products_yaml_file, "w") do |file|
              get_blobstore_client.get(BLOBSTORE_ID_PRODUCTS, file)
            end
          end

          products_yaml = YAML.load_file(products_yaml_file)

          products_yaml['products'].each do |product_name, product_details|
            product_dir = File.join(temp_dir, product_name)
            Dir.mkdir product_dir
            versions_manifest_id = product_details['blobstore_id']
            versions_manifest_yaml_file = File.join(product_dir, 'manifest.yml')

            if (versions_manifest_id != nil) && (get_blobstore_client.exists?(versions_manifest_id))
              File.open(versions_manifest_yaml_file, "w") do |file|
                get_blobstore_client.get(versions_manifest_id, file)
              end
            end
          end

          FileUtils.cp_r Dir.glob("#{temp_dir}/*"), dir
        end

        def initialize(name, label, type, description)
          @name = name
          @label = label
          @description = description
          @type = type

          dir = Product.version_directory
          versions_manifest_file = File.join(dir, @name, 'manifest.yml')

          @versions = {}

          if File.exist?(versions_manifest_file)
            versions_manifest = YAML.load_file(versions_manifest_file)

            versions_manifest['versions'].each do |version, details|
              @versions[version] = Version.new(self, version, details)
            end
          end
        end
      end
    end
  end
end