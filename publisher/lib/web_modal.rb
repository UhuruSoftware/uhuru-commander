require 'client'
require 'escort'
require 'blobstore_client'

module  Uhuru
  module UCC
    module Publisher
      class WebModal

        #####################################   READ PRODUCTS   ############################################

        def self.get_all_products
          client = Uhuru::UCC::Publisher::Client.new()
          rows = []
          products = client.get_products

          if products != nil
            products["products"].keys.each do |key|
              rows << {
                  :name => key,
                  :type => products["products"][key]["type"],
                  :label => products["products"][key]["label"],
                  :description => products["products"][key]["description"],
                  :blobstore_id => products["products"][key]["blobstore_id"],
                  :versions => get_all_versions(products, client, key)
              }
            end
          end

          return rows
        end

        def self.get_all_versions(products, client, product_name)
          client = client
          rows = []

          if products["products"][product_name]["blobstore_id"] != nil
            versions = YAML.load client.get(products["products"][product_name]["blobstore_id"])

            versions["versions"].keys.each do |version|
              version_rows = []

              versions["versions"][version]["dependencies"].each do |dep|
                version_rows << ["#{dep['dependency']}-#{dep['version']}"]
              end

              rows << {
                  :version => version,
                  :type => versions["versions"][version]["type"],
                  :description => versions["versions"][version]["description"],
                  :dependencies => version_rows
              }
            end
          end

          return rows
        end

        #########################   PRODUCTS and VERSIONS FUNCTIONS  #######################################


        def self.delete_products(product_name, with_dependencies = nil)
          name = product_name
          client = Uhuru::UCC::Publisher::Client.new()
          content = client.get(BLOBSTORE_ID_PRODUCTS)
          if content
            products = YAML.load content
          else
            raise "No products"
          end
          if (products["products"][name].nil?)
            raise "Product does not exist"
          end

          content = client.get(products["products"][name]["blobstore_id"])
          versions = YAML.load content
          versions["versions"].each do |version|
            version.each do |v|
              if (v.kind_of?(Hash) && !v["location"]["object_id"].nil?)

                if to_boolean(with_dependencies)
                  delete_dependencies(version)
                end
                client.delete(v["location"]["object_id"])

              end
            end
          end

          client.delete(products["products"][name]["blobstore_id"])
          products["products"].delete(name)
          client.upload(BLOBSTORE_ID_PRODUCTS, YAML::dump(products))

        end

        def self.delete_versions(product_name, version)

          client = Uhuru::UCC::Publisher::Client.new()

          unless client.product_exists?(product_name)
            raise "Product does not exist: #{product_name}"
          end

          product_blob_id = client.get_products["products"][product_name]["blobstore_id"]
          content = client.get(product_blob_id)

          if content
            versions = YAML.load content
          else
            versions = {}
            versions["versions"] = {}
          end
          unless versions["versions"].has_key?(version)
            raise "Version does not exist"
          end
          client.delete(versions["versions"][version]["location"]["object_id"])
          versions["versions"].delete(version)

          client.upload(product_blob_id, YAML::dump(versions))

        end




        def self.delete_dependencies(version)
          version[1]['dependencies'].each do |dependency|
            product = dependency['dependency']
            dependency['version'].each do |version|
              delete_versions(product, version)
            end
          end
        end

        def self.add_dependency(version_name = nil)

        end



        def self.to_boolean(string)
          return true   if string == true   || string =~ (/(true|t|yes|y|1)$/i)
          return false  if string == false || string.blank? || string =~ (/(false|f|no|n|0)$/i)
          raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
        end
      end


    end
  end
end