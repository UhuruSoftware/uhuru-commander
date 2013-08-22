module  Uhuru
  module UCC
    module Publisher
      class WebModal

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
              dependencies = []

              versions["versions"][version]["dependencies"].each do |dep|
                dependencies << { :product_name => dep['dependency'], :versions => dep['version'] }
              end

              rows << {
                  :version => version,
                  :type => versions["versions"][version]["type"],
                  :description => versions["versions"][version]["description"],
                  :dependencies => dependencies
              }
            end
          end

          return rows
        end

        def self.delete_products(product_name)
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

        def self.add_dependency(product_name, version, dependency_name, dependency_version)
          unless product_name == dependency_name && version == dependency_version

            client = Uhuru::UCC::Publisher::Client.new()

            unless client.product_exists?(product_name)
              raise "Product does not exist: #{product_name}"
            end
            unless client.product_exists?(dependency_name)
              raise "Product does not exist: #{dependency_name}"
            end

            products = client.get_products

            content = client.get(products["products"][product_name]["blobstore_id"])
            unless content
              raise "Product #{product_name} has no release uploaded"
            end

            product_versions = YAML.load content
            content = client.get(products["products"][dependency_name]["blobstore_id"])

            unless content
              raise "Product #{dependency_name} has no release uploaded"
            end

            dependency_versions = YAML.load content

            unless product_versions["versions"].has_key?(version)
              raise "Version #{version} for product #{product_name} does not exist"
            end

            dependency = product_versions["versions"][version]["dependencies"].find {|d| d["dependency"] == dependency_name}
            if dependency.nil?
              dependency = {}
              dependency["dependency"] = dependency_name
              dependency["version"] = []
              product_versions["versions"][version]["dependencies"] << dependency
            end

            if dependency["version"].include?(dependency_version)
              raise "Product dependency already exists"
            end

            dependency["version"] << dependency_version
            client.upload(products["products"][product_name]["blobstore_id"], YAML::dump(product_versions))
          else
            raise "Can't add a dependency to itself"
          end
        end

        def self.remove_dependency(product_name, version, dependency_name, dependency_version)

          client = Uhuru::UCC::Publisher::Client.new()
          products = client.get_products
          content = client.get(products["products"][product_name]["blobstore_id"])
          product_versions = YAML.load content


          dependency = product_versions["versions"][version]["dependencies"].find {|d| d["dependency"] == dependency_name}
          unless dependency.nil?
            dependency['version'].each do |version|
              if version == dependency_version
                position = dependency['version'].index(version)
                product_versions["versions"][version]["dependencies"] << dependency['version'].delete_at(position)
              end
            end
          end

          client.upload(products["products"][product_name]["blobstore_id"], YAML::dump(product_versions))
        end
      end
    end
  end
end

#def self.delete_dependencies(version)
#  version[1]['dependencies'].each do |dependency|
#    product = dependency['dependency']
#    dependency['version'].each do |version|
#      delete_versions(product, version)
#    end
#  end
#end