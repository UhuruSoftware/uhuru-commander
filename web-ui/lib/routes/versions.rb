module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    post '/versions/read_states' do
      r = Random.new
      state = 'error'
      Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                state = r.rand(0...1000) #version[1].get_state
                puts state
              end
            end
          end
        end
      end

      #if state == 1
      #  state = "Remote Only"
      #elsif state == 2
      #  state = "Downloading"
      #elsif state == 3
      #  state = "Local"
      #elsif state == 4
      #  state = "Local Preparing"
      #elsif state == 5
      #  state = "Available"
      #elsif state == 6
      #  state = "Deployed"
      #else state == "error"
      #  state = "Loading ..."
      #end

      return state.to_s
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

