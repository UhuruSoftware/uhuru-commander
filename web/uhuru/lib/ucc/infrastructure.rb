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
        command_stemcell.upload('../resources/bosh-stemcell-vsphere-0.6.4.tgz')
        say "Uploading Linux PHP stemcell"
        command_stemcell.upload('../resources/bosh-stemcell-php-vsphere-0.6.4.3.tgz')
        say "Uploading Windows stemcell"
        #command_stemcell.upload('../resources/uhuru-windows-2008R2-0.9.3.tgz')
        say "Uploading Windows SQL Server stemcell"
        #command_stemcell.upload('../resources/uhuru-windows-2008R2-sqlserver-0.9.4.tgz')
      end
    end
  end
end