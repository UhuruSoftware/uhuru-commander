module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    get '/refresh_state' do
      state = nil

      begin
        Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
          if product[1].name == params[:product]
            product[1].versions.each do |version|
              if version[1].version == params[:version]
                Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                  state = version[1].get_state.to_s
                end
              end
            end
          end
        end
      rescue Exception => e
        $logger.warn "Could not read state after downloading - #{e.message} : #{e.backtrace}"
        return  nil
      end

      return state.to_s
    end


    get '/download' do
      product = params[:product]
      version = params[:version]
      # TODO: products array can pe passed at post
      #products = params[:products_list]

      products = Uhuru::BoshCommander::Versioning::Product.get_products
      products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                version[1].download_from_blobstore
                puts 'started'
              end
            end
          end
        end
      end
    end

    get '/download_state' do
      progress = ''
      # TODO: products array can pe passed at post
      #products = params[:products_list]

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

