module Uhuru::BoshCommander
  class BoshInfrastructure

    def setup(new_config)
      say('Moving director config')
      #@director_config_file = $config[:director_yml]
      @is_update = is_update
      setup_micro(new_config)
      say('Restarting services')
      restart_monit
      say('Creating system users')
      create_users()
      say('Reconnecting to services')
      refresh_login()
      unless @is_update
        say('Uploading stemcells')
        upload_stemcells
        say('Configuring database')
        configure_database
      end

      say('Configuring Nagios')
      setup_nagios

      say ('Infrastructure configured')
    end

    def refresh_login
      sleep 50
      command = Bosh::Cli::Command::Misc.new

      Thread.current.current_session['command'] = command

      #we do not care about local user
      tmpdir = Dir.mktmpdir

      config = File.join(tmpdir, "bosh_config")
      cache = File.join(tmpdir, "bosh_cache")

      command.add_option(:config, config)
      command.add_option(:cache_dir, cache)
      command.add_option(:non_interactive, true)

      CommanderBoshRunner.execute(Thread.current.current_session) do
        Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(cache)
        command.set_target($config[:bosh][:target])
        command.login('admin', 'admin')
      end

      stemcell_cmd = Bosh::Cli::Command::Stemcell.new
      stemcell_cmd.instance_variable_set("@config", command.instance_variable_get("@config"))
      Thread.current.current_session['command_stemcell'] = stemcell_cmd
    end

    def is_update
      db = get_database
      first_name = db[:stemcells].select(:name).first()[:name]
      if first_name.start_with?("empty-")
        return false
      end
      true
    end

    def setup_micro(new_config)
      director_yml = load_yaml_file(new_config)

      build_info(director_yml)
      setup_properties()
    end

    private

    def build_info(director_yml)
      nats_hash = director_yml["mbus"].scan(/(nats):\/\/(\S+):(\S+)@(\S+):(\S+)?/).first
      @nats_info = {}
      @nats_info[:user] = nats_hash[1]
      @nats_info[:password] = nats_hash[2]
      @nats_info[:ip] = nats_hash[3]
      @nats_info[:port] = nats_hash[4].to_i

      #we assume that redis is going to be on the same box as the director

      @director_info = {}
      @director_info[:hostname] = $config[:bosh][:target].match(/[0-9]+(?:\.[0-9]+){3}/).to_s
      @director_info[:port] = director_yml["port"].to_i
      @director_info[:hm_user] = "hm_user"
      @director_info[:hm_password] = (0...8).map{ ('a'..'z').to_a[rand(26)] }.join.to_s

      pg_uri = URI(director_yml['db']['database'])
      @postgres_info = {}
      @postgres_info[:host] = pg_uri.host
      @postgres_info[:user] = pg_uri.user
      @postgres_info[:password] = pg_uri.password
      @postgres_info[:port] = pg_uri.port
      @postgres_info[:db] = pg_uri.path
      @postgres_info[:db][0] = ''
    end

    def create_users()
      #we need to created the default admin user
      unless @is_update
        User.create("admin", "admin")
        User.create(@director_info[:hm_user], @director_info[:hm_password])
      end
    end

    def setup_nagios()
      monitoring_file = $config[:nagios][:config_path]
      monitoring_yml = YAML.load_file(monitoring_file)

      monitoring_yml['nats'] = "nats://#{@nats_info[:ip]}:#{@nats_info[:port]}"

      monitoring_yml['bosh_db']['user'] = @postgres_info[:user]
      monitoring_yml['bosh_db']['password'] = @postgres_info[:password]
      monitoring_yml['bosh_db']['address'] = @postgres_info[:host]
      monitoring_yml['bosh_db']['port'] = @postgres_info[:port]
      monitoring_yml['bosh_db']['database'] = @postgres_info[:db]

      monitoring_yml['director']['address'] = @director_info[:hostname]
      monitoring_yml['director']['port'] = @director_info[:port]
      monitoring_yml['director']['user'] = @director_info[:hm_user]
      monitoring_yml['director']['password'] = @director_info[:hm_password]

      File.open(monitoring_file, 'w') do |file|
        dump_yaml_to_file(monitoring_yml, file )
      end
    end

    def setup_properties()
      properties_file = $config[:properties_file]
      prop = load_yaml_file(properties_file)

      #nats settings
      prop["properties"]["nats"]["listen_address"] = @nats_info[:ip]
      prop["properties"]["nats"]["port"] = @nats_info[:port]
      prop["properties"]["nats"]["user"] = @nats_info[:user]
      prop["properties"]["nats"]["password"] = @nats_info[:password]

      #database settings
      prop["properties"]["postgres"]["host"] = @postgres_info[:host]
      prop["properties"]["postgres"]["password"] =  @postgres_info[:password]

      #health manager settings
      prop["properties"]["hm"]["director_account"]["user"] = @director_info[:hm_user]
      prop["properties"]["hm"]["director_account"]["password"] = @director_info[:hm_password]

      File.open(properties_file, 'w') do |file|
        dump_yaml_to_file(prop, file )
      end
    end

    def restart_monit
      monit = Monit.new
      monit.restart_services
    end

    def upload_stemcells
      command_stemcell = Thread.current.current_session['command_stemcell']
      say "Uploading Linux PHP stemcell"
      command_stemcell.upload(get_stemcell_filename($config[:bosh][:stemcells][:linux_php_stemcell]))
      say "Uploading Windows stemcell"
      command_stemcell.upload(get_stemcell_filename($config[:bosh][:stemcells][:windows_stemcell]))
      say "Uploading Windows SQL Server stemcell"
      command_stemcell.upload(get_stemcell_filename($config[:bosh][:stemcells][:mssql_stemcell]))
    end

    def get_stemcell_filename(stemcell)
      "../resources/#{stemcell[:name]}-#{$config[:bosh][:infrastructure]}-#{stemcell[:version]}.tgz"
    end

    def configure_database
      db = get_database
      $config[:bosh][:stemcells].each do |stemcell_type, config_stemcell|
        current_cid = db[:stemcells].select(:cid).first(:name=>config_stemcell[:name])[:cid]
        db[:stemcells].filter(:name => config_stemcell[:name]).delete
        db[:stemcells].filter(:name => "empty-#{config_stemcell[:name]}").update(:cid => current_cid, :name => config_stemcell[:name])
      end
    end

    def get_database
      director_yaml = YAML.load_file($config[:director_yml])
      db_config = director_yaml["db"]
      connection_options = {
          :max_connections => db_config["max_connections"],
          :pool_timeout => db_config["pool_timeout"]
      }
      db = Sequel.connect(db_config["database"], connection_options)
      db
    end

  end
end
