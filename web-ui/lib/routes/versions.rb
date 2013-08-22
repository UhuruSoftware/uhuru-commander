module Uhuru::BoshCommander
  class Versions < RouteBase

    post '/download' do
      product = Uhuru::BoshCommander::Versioning::Product.get_products[params[:product]]
      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        product.versions[params[:version]].download_from_blobstore
      end

      redirect '/versions'
    end

    post '/download_with_dependencies' do
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      product = Uhuru::BoshCommander::Versioning::Product.get_products[params[:product]]
      version = product.versions[params[:version]]

      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        version.download_from_blobstore


        version.dependencies.each do |current_dependency|

          latest_version = current_dependency['version'].map do |dep_version|
            Uhuru::BoshCommander::Versioning::Product.get_products[current_dependency['dependency']].versions[dep_version]
          end.max

          latest_version.download_from_blobstore
        end

      end

      redirect '/versions'
    end

    get '/download_state' do

      stemcells = nil
      releases = nil
      deployments = nil

      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        stemcells = Uhuru::BoshCommander::Stemcell.new().list_stemcells
        releases = Uhuru::BoshCommander::Release.new().list_releases
        deployments = Deployment.get_director_deployments
      end

      progress = {}

      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        Uhuru::BoshCommander::Versioning::Product.get_products.each do |product_name, product|
          progress[product_name] = {}
          product.versions.each do |version_number, version|
            if version.get_state(stemcells, releases, deployments) == Uhuru::BoshCommander::Versioning::STATE_DOWNLOADING
              progress[product_name][version_number] = version.download_progress
            end
          end
        end
      end

      progress.to_json
    end


    post '/delete_stemcell_from_blobstore' do
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          stemcell = Uhuru::BoshCommander::Stemcell.new
          stemcell.delete(params[:name], params[:version])
        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end
      action_on_done = "Stemcell '#{params[:name]}' - '#{params[:version]}' deleted. Click <a href='/versions'>here</a> to return to library panel."
      redirect Logs.log_url(request_id, action_on_done)
      redirect '/versions'
    end

    post '/delete_software_from_blobstore' do
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release_manifest_path = File.join(Uhuru::BoshCommander::Versioning::Product.version_directory, params[:name], params[:version], 'bits' , 'config', "#{params[:name]}.yml.erb" )
          deployment_erb = File.read(release_manifest_path)
          deployment_rendered = ERB.new(deployment_erb).result()
          deployment_yaml = YAML.load(deployment_rendered)

          if (deployment_yaml["release"])
            release = Uhuru::BoshCommander::Release.new
            release.delete(deployment_yaml["release"]["name"],params[:version])
          else
            deployment_yaml["releases"].each do |spec_release|
              release = Uhuru::BoshCommander::Release.new
              release.delete(spec_release["name"], params[:version])
            end
          end


        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end
      action_on_done = "Release '#{params[:name]}' - '#{params[:version]}' deleted. Click <a href='/versions'>here</a> to return to library panel."
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

      action_on_done = "Release uploaded. Click <a href='/versions'>here</a> to return to library panel."
      redirect Logs.log_url(request_id, action_on_done)
    end

    post '/upload_software' do
      products_dir = Uhuru::BoshCommander::Versioning::Product.version_directory
      product_dir = File.join(products_dir, params[:name])

      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release = Uhuru::BoshCommander::Release.new
          release_files = Dir["#{product_dir}/#{params[:version]}/bits/*release.tgz"]
          release_files.each do |release_file|
            say "Uploading releases #{release_file}"
            release.upload(release_file)
          end

        rescue Exception => e
          $logger.error "#{e.message} - #{e.backtrace}"
        end
      end

      action_on_done = "Release uploaded. Click <a href='/versions'>here</a> to return to library panel."
      redirect Logs.log_url(request_id, action_on_done)
    end



    get '/versions' do
      session[:new_versions] = false
      stemcells = nil
      releases = nil
      deployments = nil
      products = Uhuru::BoshCommander::Versioning::Product.get_products

      Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
        stemcells = Uhuru::BoshCommander::Stemcell.new().list_stemcells
        releases = Uhuru::BoshCommander::Release.new().list_releases
        deployments = Deployment.get_director_deployments
      end

      render_erb do
        template :versions
        layout :layout
        var :products, products
        var :stemcells, stemcells
        var :releases, releases
        var :deployments, deployments
        help 'versions'
      end
    end

  end
end

