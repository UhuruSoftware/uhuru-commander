module Uhuru::BoshCommander
  class Versions < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    post '/download' do
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

      redirect '/versions'
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

      # needs to return a json array in order to show the progress span %
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

