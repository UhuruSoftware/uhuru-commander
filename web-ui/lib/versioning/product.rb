require 'fileutils'
require 'yaml'

module Uhuru
  module BoshCommander
    module Versioning
      class Product

        attr_accessor :name
        attr_accessor :label
        attr_accessor :description
        attr_accessor :versions
        attr_accessor :type

        def self.version_directory
          dir = $config['versioning_dir']
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
