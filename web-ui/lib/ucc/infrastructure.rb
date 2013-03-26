module Uhuru::BoshCommander
  class BoshInfrastructure

    def setup(new_config)
      say('Moving director config')
      @director_config_file =  File.join($config[:bosh][:base_dir], 'jobs','director','config','director.yml.erb')
      @is_update = is_update
      setup_micro(new_config)
      say('Restarting services')
      restart_monit
      if (!@is_update)
        say('Uploading stemcells')
        upload_stemcells
        say('Configuring database')
        configure_database
      end

      say ('Infrastructure configured')
    end

    private

    def setup_micro(new_config)
      FileUtils.cp(new_config, @director_config_file)
      director_yml = load_yaml_file(@director_config_file)
      build_info(director_yml)
      create_users()
      setup_nats()
      setup_postgres()
      setup_health_monitor()
    end

    def is_update
      db = get_database
      first_name = db[:stemcells].select(:name).first()[:name]
      if (first_name.start_with?("empty-"))
        return false
      end
      true
    end


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

    end

    def create_users()
      #we need to created the default admin user
      if (!@is_update)
        User.create("admin", "admin")
        User.create(@director_info[:hm_user], @director_info[:hm_password])
      end
    end

    def setup_nats()
      nats_file =  File.join($config[:bosh][:base_dir], 'jobs','nats','config','nats.yml')
      nats_yml = load_yaml_file(nats_file)
      nats_yml["net"] = @nats_info[:ip]
      nats_yml["port"] = @nats_info[:port]
      nats_yml["authorization"]["user"] = @nats_info[:user]
      nats_yml["authorization"]["password"] = @nats_info[:password]

      File.open(nats_file, 'w') do |file|
        dump_yaml_to_file(nats_yml, file )
      end

    end

    def setup_postgres()
      postgres_file = File.join($config[:bosh][:base_dir],'jobs','postgres', 'bin', 'postgres_ctl')
    end

    def setup_health_monitor()
      hm_file =  File.join($config[:bosh][:base_dir], 'jobs','health_monitor','config','health_monitor.yml')

      hm_yml =  load_yaml_file(hm_file)
      hm_yml["mbus"]["endpoint"] = "nats://#{@nats_info[:ip]}:#{@nats_info[:port]}"
      hm_yml["mbus"]["user"] = @nats_info[:user]
      hm_yml["mbus"]["password"] = @nats_info[:password]
      hm_yml["director"]["endpoint"] = "http://#{@director_info[:hostname]}:#{@director_info[:port]}"
      hm_yml["director"]["user"] = @director_info[:hm_user]
      if (!@is_update)
        hm_yml["director"]["password"] = @director_info[:hm_password]
      end

      File.open(hm_file, 'w') do |file|
        dump_yaml_to_file(hm_yml, file )
      end

    end

    def restart_monit
      monit = Monit.new
      monit.restart_services
    end

    def upload_stemcells
      command_stemcell = Thread.current.current_session['command_stemcell']
      say "Uploading Linux stemcell"
      command_stemcell.upload(get_stemcell_filename($config[:bosh][:stemcells][:linux_stemcell]))
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
      director_yaml = YAML.load_file(@director_config_file)
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
