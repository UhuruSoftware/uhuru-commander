module Uhuru
  module UCC
    module Publisher
      class Versions < ::Escort::ActionCommand::Base
        def upload_version
          product_name = command_options[:name]
          version = command_options[:prod_version]
          type = command_options[:type]
          description = command_options[:description]
          file_path = command_options[:file]

          client = Uhuru::UCC::Publisher::Client.new()
          unless client.product_exists?(product_name)
            raise "Product does not exist: #{product_name}"
          end

          content = client.get("#{product_name}.yml")

          if content
            versions = YAML.load content
          else
            versions = {}
            versions["versions"] = {}
          end
          if versions["versions"].has_key?(version)
            raise "Version already exists"
          end

          file= File.new(file_path, "r")
          blob_id = "#{product_name}-#{version}-#{type}"
          client.upload(blob_id, file)

          location = {}
          location["object_id"] = blob_id
          location["size"] = File.size(file_path)
          location["sha"] = Digest::SHA1.file(file_path).hexdigest

          versions["versions"][version] = {}
          versions["versions"][version]["type"] = type
          versions["versions"][version]["description"] = description
          versions["versions"][version]["location"] = location
          versions["versions"][version]["dependencies"] = []

          client.upload("#{product_name}.yml", YAML::dump(versions))
        end

        def add_dependency
          product_name = command_options[:name]
          version = command_options[:prod_version]
          dependency_name = command_options[:dep_name]
          dependency_version = command_options[:dep_version]

          client = Uhuru::UCC::Publisher::Client.new()
          unless client.product_exists?(product_name)
            raise "Product does not exist: #{product_name}"
          end
          unless client.product_exists?(dependency_name)
            raise "Product does not exist: #{dependency_name}"
          end

          content = client.get("#{product_name}.yml")
          unless content
            raise "Product #{product_name} has no release uploaded"
          end
          product_versions = YAML.load content
          content = client.get("#{dependency_name}.yml")
          unless content
            raise "Product #{dependency_name} has no release uploaded"
          end
          dependency_versions = YAML.load content

          unless product_versions["versions"].has_key?(version)
            raise "Version #{version} for product #{product_name} does not exist"
          end


          dependency = {}
          dependency["dependency"] = dependency_name
          dependency["version"] = dependency_version
          product_versions["versions"][version]["dependencies"] << dependency
          client.upload("#{product_name}.yml", YAML::dump(product_versions))
        end
      end
    end
  end
end

