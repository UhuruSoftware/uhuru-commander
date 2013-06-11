module Uhuru
  module UCC
    module Publisher
      class Client
        def initialize
          if $config
            options = YAML.load_file $config
          else
            options= YAML.load_file File.expand_path('../../config/publisher.config', __FILE__)
          end
          @bsc_provider= options["blobstore_provider"]
          @bsc_options= options["blobstore_options"]
        end

        def upload(id, content)
          blobstore_client = Bosh::Blobstore::Client.create(@bsc_provider, @bsc_options)
          blobstore_client.create(content, id)
        end

        def get(id)
          blobstore_client = Bosh::Blobstore::Client.create(@bsc_provider, @bsc_options)
          if blobstore_client.exists?(id)
            return blobstore_client.get(id)
          else
            return nil
          end
        end

        def get_products
          YAML.load(get(BLOBSTORE_ID_PRODUCTS))
        end

        def product_exists?(product_id)
          get_products["products"].has_key?(product_id)
        end
      end
    end
  end
end
