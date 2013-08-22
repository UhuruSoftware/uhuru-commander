module Uhuru
  module UCC
    module Publisher
      class WebInterface < Sinatra::Base
        config = YAML.load_file File.expand_path('../../config/publisher.config', __FILE__)

        set :root, File.expand_path("../..", __FILE__)
        set :views, File.expand_path("../../web_interface/views", __FILE__)
        set :public_folder, File.expand_path("../../web_interface/public", __FILE__)

        set :bind => config['web_interface']['domain']    || 'localhost'
        set :port => config['web_interface']['port']      || '9000'

        set :dump_errors => true
        set :raise_errors => false
        set :show_exceptions => false

        error do
          erb :error, :layout => :layout
        end

        get '/' do
          redirect '/products'
        end

        get '/products' do
          products = Uhuru::UCC::Publisher::WebModal.get_all_products
          erb :products, :locals => { :products => products }, :layout => :layout
        end

        get '/products/:product/' do
          redirect "/products/#{params[:product]}/#{'first'}"
        end
        get '/products/:product' do
          redirect "/products/#{params[:product]}/#{'first'}"
        end

        get '/products/:product/:version' do
          current_version = nil
          default_version = nil

          Uhuru::UCC::Publisher::WebModal.get_all_products.each do |product|
            if product[:name] == params[:product]
              product[:versions].each do |version|
                default_version = version
                if version[:version] == params[:version]
                  current_version = version
                end
              end
            end
          end

          if params[:version] == 'first'
            current_version = default_version
          end

          erb :versions, :locals => { :product => params[:product], :version => current_version }, :layout => :layout
        end

        post '/delete_products' do
          Uhuru::UCC::Publisher::WebModal.delete_products(params[:product])
          redirect '/products'
        end

        post '/delete_versions' do
          Uhuru::UCC::Publisher::WebModal.delete_versions(params[:product], params[:version])
          redirect '/products'
        end

        post '/add_dependency' do
          Uhuru::UCC::Publisher::WebModal.add_dependency(params[:dependent_product_name], params[:dependent_version], params[:dependency_product_name], params[:dependency_version])
          redirect '/products'
        end

        post '/remove_dependency' do
          Uhuru::UCC::Publisher::WebModal.remove_dependency(params[:dependent_product_name], params[:dependent_version], params[:dependency_product_name], params[:dependency_version])

          if params[:product_name] == nil
            redirect "/products"
          elsif params[:version] == nil
            redirect "/products/#{params[:product_name]}"
          else
            redirect "/products/#{params[:product_name]}/#{params[:version]}"
          end
        end
      end
    end
  end
end