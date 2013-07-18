module Uhuru::BoshCommander
  class LoginScreen < RouteBase

    def login
      if session['streamer'] == nil
        session['command_uuid'] = UUIDTools::UUID.random_create
      end

      command = nil
      if $config[:mock_backend]
        command = Uhuru::BoshCommander::MockBoshCommand.new
      else
        command = Bosh::Cli::Command::Misc.new
      end

      session['command'] = command

      #we do not care about local user
      tmpdir = Dir.mktmpdir

      config = File.join(tmpdir, "bosh_config")
      cache = File.join(tmpdir, "bosh_cache")

      command.add_option(:config, config)
      command.add_option(:cache_dir, cache)
      command.add_option(:non_interactive, true)

      CommanderBoshRunner.execute(session) do
        Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(cache)
        command.set_target($config[:bosh][:target])
        command.login(params[:username], params[:password])
      end

      return command, config, cache
    end

    get '/login' do
      path = params['path']

      render_erb do
        template :login
        var :error_message, ""
        var :path, path
      end
    end

    post '/login' do
      session['user_name'] = params[:username]
      session[:new_versions] = false
      command, _, _ = login

      if command.logged_in?
        stemcell_cmd = Bosh::Cli::Command::Stemcell.new
        stemcell_cmd.instance_variable_set("@config", command.instance_variable_get("@config"))
        session['command_stemcell'] = stemcell_cmd

        redirect_path = params['path']

        # check if newer versions of current deployments are available  ## this should be in each login session  #
        products = Uhuru::BoshCommander::Versioning::Product.get_products

        products.each do |_ , product|
          Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
            latest_deployed_version = product.versions.values.find_all {|version| version.get_state == Uhuru::BoshCommander::Versioning::STATE_DEPLOYED }.max
            if latest_deployed_version != nil && latest_deployed_version < product.latest_version
              session[:new_versions] = true
            end
          end
        end

        if redirect_path == nil
          redirect '/'
        else
          redirect redirect_path
        end
      else
        message = "Cannot log in as '#{params[:username]}'"

        render_erb do
          template :login
          var :error_message, message
        end
      end
    end

    get '/logout' do
      CommanderBoshRunner.execute(session) do
        session['user_name'] = nil
        session['command'].logout
      end
      redirect '/'
    end

    get '/monit_status' do
      state = nil
      CommanderBoshRunner.execute(session) do
        monit = Monit.new
        state = monit.service_group_state

      end
      state
    end
  end
end
