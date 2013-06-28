module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    post '/versions/read_states' do
      state = nil

      begin
        Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
          if product[1].name == params[:product]
            product[1].versions.each do |version|
              if version[1].version == params[:version]
                Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do

                  #state = r.rand(1...7)    #version[1].get_state
                  state = version[1].get_state.to_s

                  if state == '1'
                    state = '1'
                  elsif state == '2'
                    state = '2'
                  elsif state == '3'
                    state = '3'
                  elsif state == '4'
                    state = '4'
                  elsif state == '5'
                    state = '5'
                  elsif state == '6'
                    state = '6'
                  else
                    state = '7'
                  end

                end
              end
            end
          end
        end
      rescue Exception => e
        $logger.warn "Could not read states - #{e.message} : #{e.backtrace}"
        return '7'
      end

      return state.to_s
    end


    post '/download' do
      product = params[:product]
      version = params[:version]

      Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                version[1].download_from_blobstore
              end
            end
          end
        end
      end

      render_erb do
        template :downloads
        layout :layout
        var :progress, 0
        var :product, product
        var :version, version
        help 'versions'
      end
    end

    post '/download_state' do
      progress = nil

      Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                progress = version[1].download_progress
              end
            end
          end
        end
      end

      return progress[0].to_s
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

