module Uhuru::BoshCommander
  class Update < RouteBase

    #gets an array of all existing releases
    get '/releases' do
      releases = nil
      CommanderBoshRunner.execute(session) do
        begin
          release = Release.new
          releases = release.list_releases
        rescue Exception => e
          err e
        end
      end
      #TODO add table
      releases.to_s
    end

    #deletes the specified release
    get '/release/delete/:name/:version' do
      releases = nil
      name = params[:name]
      version = params[:version]
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release = Release.new
          release.delete(name, version)

        rescue Exception => e
         err e
         end
      end

      action_on_done = "Release '#{name}' - '#{version}' deleted. Click <a href='/products/:product_name'>here</a> to return to cloud view."
      redirect Logs.log_url(request_id, action_on_done)

    end

    get '/release/upload' do
      release_path = '/home/mitza/code/private-cf-release/dev_releases/app-cloud-122.3-dev.yml'
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          release = Release.new
          release.upload(release_path)

        rescue Exception => e
          err e
        end
      end

      action_on_done = "Release uploaded. Click <a href='/products/:product_name'>here</a> to return to cloud view."
      redirect Logs.log_url(request_id, action_on_done)
    end

    get '/stemcells/test' do
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      state = nil
      director_deplyoemts = nil
      CommanderBoshRunner.execute(session) do
        begin
          #director_deplyoemts = Deployment.get_director_deployments
          #director_deplyoemts
          #state = products['uhuru-windows-2008R2'].versions['0.9.10'].get_state
          #state = products['boshrelease'].versions[122.1].get_state
          state = products['app-cloud'].versions['122.3-dev'].get_state

        end
      end
      #director_deplyoemts
      state
    end


    get '/stemcells' do
      stemcells = nil
      CommanderBoshRunner.execute(session) do
        begin
          stemcell = Stemcell.new
          stemcells = stemcell.list_stemcells
        rescue Exception => e
          err e
        end
      end
      #TODO add table
      stemcells.to_s
    end

    #deletes the specified release
    get '/stemcell/delete/:name/:version' do
      name = params[:name]
      version = params[:version]
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          stemcell = Stemcell.new
          stemcell.delete(name, version)

        rescue Exception => e
          err e
        end
      end

      action_on_done = "Stemcell '#{name}' - '#{version}' deleted. Click <a href='/products/:product_name'>here</a> to return to cloud view."
      redirect Logs.log_url(request_id, action_on_done)

    end

    get '/stemcell/upload' do
      stemcell_path = '/home/mitza/bosh/stemcells/micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz'
      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          stemcell = Stemcell.new
          stemcell.upload(stemcell_path)

        rescue Exception => e
          err e
        end
      end

      action_on_done = "Stemcell uploaded. Click <a href='/products/:product_name'>here</a> to return to cloud view."
      redirect Logs.log_url(request_id, action_on_done)
    end

  end
end