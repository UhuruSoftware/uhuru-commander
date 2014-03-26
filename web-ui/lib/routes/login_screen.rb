module Uhuru::BoshCommander
  # a classed used for the login screen page methods
  class LoginScreen < RouteBase

    # the login method for a user
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

      set_last_log

      #we do not care about local user
      tmpdir = Dir.mktmpdir

      config = File.join(tmpdir, "bosh_config")
      cache = File.join(tmpdir, "bosh_cache")

      command.add_option(:config, config)
      command.add_option(:cache_dir, cache)
      command.add_option(:non_interactive, true)

      CommanderBoshRunner.execute(session) do
        command.set_target($config[:bosh][:target])
        command.login(params[:username], params[:password])
      end

      return command, config, cache
    end

    # the get method for the login page
    get '/login' do
      path = params['path']

      render_erb do
        template :login
        var :error_message, ""
        var :path, path
      end
    end

    # the post method for the login page (performs the login action)
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
            latest_deployed_version = product.versions.values.find_all {|version| version.get_state == Uhuru::BoshCommander::Versioning::STATE_DEPLOYED }.min
            if (latest_deployed_version != nil) && (latest_deployed_version < product.latest_version)
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
        # clear sessions if the login fails
        session['user_name'] = nil
        session[:new_versions] = nil

        render_erb do
          template :login
          var :error_message, message
        end
      end
    end

    # get method for the logout page (also performs the logout)
    get '/logout' do
      CommanderBoshRunner.execute(session) do
        session['user_name'] = nil
        session['command'].logout
      end
      redirect '/'
    end

    # get method for the monit status
    get '/monit_status' do
      state = nil
      CommanderBoshRunner.execute(session) do
        monit = Monit.new
        state = monit.service_group_state

      end
      state
    end

    private

    # a method used for setting the last log
    def set_last_log
      log_file = $config[:logging][:file]
      json = File.read log_file
      logs = []
      Yajl::Parser.parse(json) { |obj|
        logs << obj
      }

      session['last_log'] = logs.length - 1
    end
  end
end
