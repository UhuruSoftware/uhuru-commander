module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end


    post '/versions/read_states' do
      r = Random.new
      current_state = nil

      Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              #puts "parameters: " + params[:product] + params[:version]
              #puts "real_values :" + product[1].name + version[1].version

              current_state = r.rand(0...1000)
              puts current_state
              return current_state.to_i.to_s
            else
              return "loading..."
            end
          end
        else
          return
        end
      end
      return "loading..."
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

