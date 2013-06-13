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


#@t << {:path => '/clouds', :href => '/clouds', :name => p[1].label}
#
#product[1].versions.each do |current_ver|
#  current_ver[1].version
#end


