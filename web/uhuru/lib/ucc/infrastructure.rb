module Uhuru
  module Ucc
    class Infrastructure

      def setup(new_config)
        say('Moving director config')
        @director_config_file = move_director_config(new_config)
        say('Restarting services')
        restart_monit
        say('Uploading stemcells')
        upload_stemcells
        say('Configuring database')
        configure_database
        say ('Deployment finished')
      end

      private

      def move_director_config(new_config)
        director_config_path = File.join($config[:bosh][:base_dir], 'jobs','micro_vsphere','director','config','director.yml.erb')
        FileUtils.cp(new_config, director_config_path)
        director_config_path
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
        director_yaml = YAML.load_file(@director_config_file)
        db_config = director_yaml["db"]
        connection_options = {
            :max_connections => db_config["max_connections"],
            :pool_timeout => db_config["pool_timeout"]
        }
        db = Sequel.connect(db_config["database"], connection_options)

        $config[:bosh][:stemcells].each do |stemcell_type, config_stemcell|
          current_cid = db[:stemcells].select(:cid).first(:name=>config_stemcell[:name])[:cid]
          db[:stemcells].filter(:name=>config_stemcell[:name]).delete
          db[:stemcells].filter(:name=>"empty-#{config_stemcell[:name]}").update(:cid=> current_cid,                                                                  :name=> config_stemcell[:name])
        end
      end

    end
  end
end