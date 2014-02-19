# Copyright (c) 2009-2012 VMware, Inc.


module Uhuru::BoshCommander
  # monitoring class
  class Monit

    BOSH_APP = BOSH_APP_USER = BOSH_APP_GROUP = "vcap"
    BOSH_APP_GROUP_BASE = "vcap_base"

    def initialize
      @tries = 3
    end

    # define de base directory
    def base_dir
      '/etc'
    end

    def monit_dir
      File.join(base_dir, 'monit')
    end

    def monit_user_file
      File.join(monit_dir, 'monit.user')
    end

    def monit_alerts_file
      File.join(monit_dir, 'alerts.monitrc')
    end

    # credentials for monitoring
    def monit_credentials
      entry = File.read(monit_user_file).lines.find { |line| line.match(/\A#{BOSH_APP_GROUP}/) }
      user, cred = entry.split(/:/)
      [user, cred.strip]
    end

    # defines de logger
    def logger
      $config[:logger]
    end

    def monit_api_client
      user, cred = monit_credentials
      MonitClient.new("https://#{user}:#{cred}@127.0.0.1:2822", :logger => logger)
    end

    def monit_bin
      File.join(base_dir, 'bosh', 'bin', 'monit')
    end

    def monitrc
      File.join(base_dir, 'bosh', 'etc', 'monitrc')
    end

    def retry_monit_request(attempts=10)
      # HACK: Monit becomes unresponsive after reload
      begin
        yield monit_api_client if block_given?
      rescue Errno::ECONNREFUSED, TimeoutError
        sleep 1
        logger.info("Monit Service Connection Refused: retrying")
        retry if (attempts -= 1) > 0
      rescue => ex
        messages = [
            "Connection reset by peer",
            "Service Unavailable"
        ]
        if messages.include?(ex.message)
          logger.info("Monit Service Unavailable (#{ex.message}): retrying")
          sleep 1
          retry if (attempts -= 1) > 0
        end
        err ex
        raise ex
      end
    end

    # starts the services
    def start_services(attempts=20)
      retry_monit_request(attempts) do |client|
        client.start(:group => BOSH_APP_GROUP)
      end
    end

    # stops the services
    def stop_services(attempts=20)
      retry_monit_request(attempts) do |client|
        client.stop(:group => BOSH_APP_GROUP)
      end
    end

    # restart all services
    def restart_all_services
      restart_services(20, BOSH_APP_GROUP_BASE)
      restart_services(20, BOSH_APP_GROUP)
    end

    def restart_services(attempts=20, group= BOSH_APP_GROUP)
      retry_monit_request(attempts) do |client|
        client.restart(:group => group)
      end
      say "Waiting for services to be online"
      restart_done = false

      #waiting for the services to be online
      service_state = ""
      count = 0
      for count in 0..10
        sleep 30
        if (service_group_state == "running")
          say "Services Online"
          restart_done = true
          break
        end
      end

      if (count == 10)
        @tries -= 1
      end

      if @tries <= 0
        error_msg = "Infrastructure services did not start properly."
        raise error_msg
      else
        if (!restart_done)
          restart_services
        end
      end
    end

    def service_group_state(num_retries=10, group = BOSH_APP_GROUP)
      # FIXME: state should be unknown if monit is disabled
      # However right now that would break director interaction
      # (at least in integration spec)
      status = get_status(num_retries, group)

      not_running = status.reject do |name, data|
        # break early if any service is initializing
        return "starting" if data[:monitor] == :init
        # at least with monit_api a stopped services is still running
        (data[:monitor] == :yes && data[:status][:message] == "running")
      end

      not_running.empty? ? "running" : "failing"
    rescue => ex
      logger.info("Unable to determine job state: #{ex}")
      "unknown"
    end

    def get_status(num_retries=10, group = BOSH_APP_GROUP)
      retry_monit_request(num_retries) do |client|
        client.status(:group => group)
      end
    end
  end
end