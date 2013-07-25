module Uhuru
  module UCC
    module Publisher
      class Products < ::Escort::ActionCommand::Base

        def products
          client = Uhuru::UCC::Publisher::Client.new()
          rows = []
          products = client.get_products
          products["products"].keys.each do |key|
            rows << [key, products["products"][key]["type"], products["products"][key]["label"], products["products"][key]["description"][0..30].gsub(/\s\w+$/, '...')]
          end
          table = Terminal::Table.new :title => "Products", :headings => ["Name", "Type", "Label", "Description"], :rows => rows
          puts table
        end

        def product
          name = command_options[:name]
          version = command_options[:prod_version]
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
          puts "Name: #{name}"
          puts "Label: #{products["products"][name]["label"]}"
          puts "Description: #{products["products"][name]["description"]}"

          versions = YAML.load client.get(products["products"][name]["blobstore_id"])

          if version == "all"
            all_rows = []
            versions["versions"].keys.each do |version|
              version_rows = []
              versions["versions"][version]["dependencies"].each do |dep|
                version_rows << ["#{dep['dependency']}-#{dep['version']}"]
              end
              all_rows << [version, versions["versions"][version]["type"], versions["versions"][version]["description"], version_rows.join("\n")]

            end
            table = Terminal::Table.new :title => name, :headings => ["Version", "Type", "Description", "Dpendencies"]
            table.rows = all_rows
            puts table
          end

        end

        def add_product
          name = command_options[:name]
          blob_id = command_options[:blob_id]
          client = Uhuru::UCC::Publisher::Client.new()
          content = client.get(BLOBSTORE_ID_PRODUCTS)
          if content
            products = YAML.load content
          else
            products = {}
            products["products"] = {}
          end
          unless products["products"][name].nil?
            unless command_options[:force]
              raise "A product with the same ID already exists"
            else
              blob_id = products["products"][name]["blobstore_id"] || blob_id
            end
          end

          unless client.blob_exists?(blob_id)
            versions = {}
            versions["versions"] = {}
            client.upload(blob_id, YAML::dump(versions))
          end

          products["products"][name] = {}
          products["products"][name]["label"] = command_options[:label]
          products["products"][name]["description"] = command_options[:description]
          products["products"][name]["type"] = command_options[:type]
          products["products"][name]["blobstore_id"] = blob_id
          client.upload(BLOBSTORE_ID_PRODUCTS, YAML::dump(products))
        end

        def delete_product
          name = command_options[:name]
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

          if command_options[:cascade]
            content = client.get(products["products"][name]["blobstore_id"])
            versions = YAML.load content
            versions["versions"].each do |version|
              version.each do |v|
                if (v.kind_of?(Hash) && !v["location"]["object_id"].nil?)
                  client.delete(v["location"]["object_id"])
                end
              end
            end
          end
          client.delete(products["products"][name]["blobstore_id"])
          products["products"].delete(name)
          client.upload(BLOBSTORE_ID_PRODUCTS, YAML::dump(products))
        end
      end
    end
  end
end
