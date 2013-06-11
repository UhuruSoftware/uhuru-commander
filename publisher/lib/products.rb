module Uhuru
  module UCC
    module Publisher
      class Products < ::Escort::ActionCommand::Base

        def products
          client = Uhuru::UCC::Publisher::Client.new()
          rows = []
          products = client.get_products
          products["products"].keys.each do |key|
            rows << [key, products["products"][key]["type"], products["products"][key]["label"], products["products"][key]["description"]]
          end
          table = Terminal::Table.new :title => "Products", :headings => ["Name", "Type", "Label", "Description"], :rows => rows
          puts table
        end

        def product
          name = command_options[:name]
          version = command_options[:prod_version]
          client = Uhuru::UCC::Publisher::Client.new()
          content = client.get(BLOBSTORE_ID_PRODUCTS)
        end

        def add_product
          name = command_options[:name]
          client = Uhuru::UCC::Publisher::Client.new()
          content = client.get(BLOBSTORE_ID_PRODUCTS)
          if content
            products = YAML.load content
          else
            products = {}
            products["products"] = {}
          end
          unless (products["products"][name].nil? || command_options[:force])
            raise "A product with the same ID already exists"
          end
          products["products"][name] = {}
          products["products"][name]["label"] = command_options[:label]
          products["products"][name]["description"] = command_options[:description]
          products["products"][name]["type"] = command_options[:type]
          client.upload(BLOBSTORE_ID_PRODUCTS, YAML::dump(products))
        end
      end
    end
  end
end
