module Uhuru::BoshCommander
  class MockBoshCommand

    def logged_in?
      true
    end

    def logout
    end

    def initialize
      @options = {}
      @director = MockBoshDirector.new
    end

    def target
      "127.0.0.1"
    end

    def deployment
      "local"
    end

    def username
      "admin"
    end

    def password
      "admin"
    end

    def add_option(name, value)

    end

    def set_target(target)

    end

    def login(user, password)

    end
  end

  class MockBoshDirector

    def initialize
      @uuid = UUIDTools::UUID.random_create
    end

    def uuid
      @uuid
    end

    def fetch_logs(deployment_name, job_name, index, job, filter)

    end

    def get_deployment(deployment_name)
      result = {}
      result['manifest'] = ""
    end

    def list_deployments
      [
          {
              "stemcells" =>
                  [
                      {
                          "name" => "bosh-stemcell-php-vsphere",
                          "version" => "1.5.0.pre.3"
                      },
                      {
                          "name" => "uhuru-windows-2008R2",
                          "version" => "0.9.9"
                      }
                  ]
          }
      ]
    end

    def list_stemcells
      [
          {
              "name" => "bosh-stemcell-php-vsphere",
              "version" => "1.5.0.pre.3"
          },
          {
              "name" => "uhuru-windows-2008R2",
              "version" => "0.9.9"
          }
      ]
    end

    def list_recent_tasks(count, verbose)
      []
    end

    def list_releases
      []
    end

    def fetch_vm_state(deployment)
      []
    end
  end
end