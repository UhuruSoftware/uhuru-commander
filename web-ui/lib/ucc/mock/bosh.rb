module Uhuru::BoshCommander
  # a class used for mocking the bosh backend
  # all the methods of this class are used if the cloud commander is not connected to bosh
  # the methods return custom hardcoded data
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
      return name, value
    end

    def set_target(target)
      return target
    end

    def login(user, password)
      return user, password
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
      return deployment_name, job_name, index, job, filter
    end

    def get_deployment(deployment_name)
      result = {}
      result['manifest'] = ""
      return deployment_name
    end

    def list_deployments
      [
          {
              "stemcells" =>
                  [
                      {
                          "name" => "bosh-stemcell-php",
                          "version" => "0.9.12.a.a"
                      },
                      {
                          "name" => "uhuru-windows-stemcell",
                          "version" => "1.1.2.a.a"
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
              "name" => "bosh-stemcell-php",
              "version" => "0.9.12.a.a"
          },
          {
              "name" => "uhuru-windows-stemcell",
              "version" => "1.1.2.a.a"
          },
          {
              "name" => "uhuru-windows-2008R2",
              "version" => "0.9.9"
          }
      ]
    end

    def list_recent_tasks(count, verbose)
      [count, verbose]
    end

    def list_releases
      []
    end

    def fetch_vm_state(deployment)
      [deployment]
    end
  end
end