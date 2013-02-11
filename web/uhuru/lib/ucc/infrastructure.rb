module Uhuru
  module Ucc
    class Infrastructure

      def setup(new_config)
        say('Moving director config')
        move_director_config(new_config)
        say('Restarting services')
        restart_monit
        say('Uploading stemcells')
        upload_stemcells
        say "Deployment finished"
      end

      private

      def move_director_config(new_config)
        director_config_path = File.join($config[:bosh][:base_dir], 'jobs','micro_vsphere','director','config','director.yml.erb')
        FileUtils.cp(new_config, director_config_path)
      end

      def restart_monit
        monit = Monit.new
        monit.restart_services
      end

      def upload_stemcells
        command_stemcell = Thread.current.current_session['command_stemcell']
        say "Uploading Linux stemcell"
        command_stemcell.upload("../resources/#{$config[:bosh][:stemcells][:linux_stemcell]}")
        say "Uploading Linux PHP stemcell"
        command_stemcell.upload("../resources/#{$config[:bosh][:stemcells][:linux_php_stemcell]}")
        say "Uploading Windows stemcell"
        #command_stemcell.upload("../resources/#{$config[:bosh][:stemcells][:windows_stemcell]}")
        say "Uploading Windows SQL Server stemcell"
        #command_stemcell.upload("../resources/#{$config[:bosh][:stemcells][:mssql_stemcell]}")
      end
    end
  end
end