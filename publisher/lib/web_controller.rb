require 'rubygems'
require 'sinatra'
require 'web_modal'

module Uhuru
  module UCC
    module Publisher
      BLOBSTORE_ID_PRODUCTS = "products.yml"
      class WebInterface < Sinatra::Base
        config = YAML.load_file File.expand_path('../../config/publisher.config', __FILE__)

        set :root, File.expand_path("../..", __FILE__)
        set :views, File.expand_path("../../web_interface/views", __FILE__)
        set :public_folder, File.expand_path("../../web_interface/public", __FILE__)

        set :bind => config['web_interface']['domain']    || 'localhost'
        set :port => config['web_interface']['port']      || '9000'


        get '/' do
          redirect '/publisher'
        end

        get '/publisher' do
          products = Uhuru::UCC::Publisher::WebModal.get_all_products
          erb :publisher, :locals => { :products => products }, :layout => :layout
        end

        post '/delete_products' do
          Uhuru::UCC::Publisher::WebModal.delete_products(params[:product], params[:with_dependencies])
          redirect '/publisher'
        end

        post '/delete_versions' do
          Uhuru::UCC::Publisher::WebModal.delete_versions(params[:product], params[:version])
          redirect '/publisher'
        end


      end
    end
  end
end