module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    get '/versions' do

      products = Uhuru::BoshCommander::Versioning::Product.get_products

      render_erb do
        template :versions
        layout :layout
        var :products, products
        help 'versions'
      end
    end
  end
end

