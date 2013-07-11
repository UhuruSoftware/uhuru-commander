module Uhuru::BoshCommander
  class Versions < RouteBase

    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    post '/download' do

      products = Uhuru::BoshCommander::Versioning::Product.get_products
      products.each do |product|
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

      redirect '/versions'
    end

    post '/download_with_dependencies' do
      redirect '/versions'
    end

    get '/download_state' do
      progress = ''

      Uhuru::BoshCommander::Versioning::Product.get_products.each do |product|
        if product[1].name == params[:product]
          product[1].versions.each do |version|
            if version[1].version == params[:version]
              Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
                progress = version[1].download_progress
                puts progress
              end
            end
          end
        end
      end

      return "{ \"progressbar\" : \"#{progress[0].to_s}\", \"progressmessage\" : \"#{progress[1].to_s}\" }"
    end


    post '/delete_stemcell_from_bosh' do
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          stemcell = Uhuru::BoshCommander::Stemcell.new
          stemcell.delete(params[:name], params[:version])
        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end
      action_on_done = "Stemcell '#{params[:name]}' - '#{params[:version]}' deleted. Click <a href='/versions'>here</a> to return to versions panel."
      redirect Logs.log_url(request_id, action_on_done)
      redirect '/versions'
    end

    post '/delete_software_from_bosh' do
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release = Uhuru::BoshCommander::Release.new
          release.delete(params[:name], params[:version])
        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end
      action_on_done = "Release '#{params[:name]}' - '#{params[:version]}' deleted. Click <a href='/versions'>here</a> to return to versions panel."
      redirect Logs.log_url(request_id, action_on_done)
      redirect '/versions'
    end


    post '/delete_stemcell_local' do
      products_dir = Uhuru::BoshCommander::Versioning::Product.version_directory
      product_dir = File.join(products_dir, params[:name])
      FileUtils.rm_rf("#{product_dir}/#{params[:version]}")
      redirect '/versions'
    end

    post '/delete_software_local' do
      products_dir = Uhuru::BoshCommander::Versioning::Product.version_directory
      product_dir = File.join(products_dir, params[:name])
      FileUtils.rm_rf("#{product_dir}/#{params[:version]}")
      redirect '/versions'
    end


    post '/upload_stemcell' do
      products_dir = Uhuru::BoshCommander::Versioning::Product.version_directory
      product_dir = File.join(products_dir, params[:name])

      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          stemcell = Uhuru::BoshCommander::Stemcell.new
          stemcell.upload("#{product_dir}/#{params[:version]}/bits")
        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end

      action_on_done = "Release uploaded. Click <a href='/versions'>here</a> to return to versions panel."
      redirect Logs.log_url(request_id, action_on_done)
    end

    post '/upload_software' do
      products_dir = Uhuru::BoshCommander::Versioning::Product.version_directory
      product_dir = File.join(products_dir, params[:name])

      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release = Uhuru::BoshCommander::Release.new
          release.upload("#{product_dir}/#{params[:version]}/bits/release.tgz")

        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end

      action_on_done = "Release uploaded. Click <a href='/versions'>here</a> to return to versions panel."
      redirect Logs.log_url(request_id, action_on_done)
    end



    get '/versions' do
      stemcells = nil
      releases = nil
      products = Uhuru::BoshCommander::Versioning::Product.get_products

      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        stemcells = Uhuru::BoshCommander::Stemcell.new().list_stemcells
        releases = Uhuru::BoshCommander::Release.new().list_releases
      end

      render_erb do
        template :versions
        layout :layout
        var :products, products
        var :stemcells, stemcells
        var :releases, releases
        help 'versions'
      end
    end

  end
end

