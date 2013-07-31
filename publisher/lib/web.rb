require 'rubygems'
require 'sinatra'

require 'versions'
require 'client'
require 'escort'
require 'blobstore_client'

module Uhuru
  module UCC
    module Publisher
      BLOBSTORE_ID_PRODUCTS = "products.yml"
      class WebInterface < Sinatra::Base
        set :root, File.expand_path("../..", __FILE__)
        set :views, File.expand_path("../../web_interface/views", __FILE__)
        set :public_folder, File.expand_path("../../web_interface/public", __FILE__)

        set :bind => '192.168.1.125'
        set :port => '9000'



        get '/' do
          redirect '/publisher'
        end

        get '/publisher' do
          products = get_all_products
          erb :publisher, :locals => { :products => products }, :layout => :layout
        end





        def get_all_products
          client = Uhuru::UCC::Publisher::Client.new()
          rows = []
          products = client.get_products

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

          return rows
        end

        def get_all_versions(products = nil, client =nil, product_name = nil)
          client = client
          rows = []
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
                          }
            end

          return rows
        end

      end
    end
  end
end