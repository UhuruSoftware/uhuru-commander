module Uhuru
  module Ucc
    class Director

      DIRECTOR_HTTP_ERROR_CODES = [400, 403, 404, 500]

      API_TIMEOUT = 86400 * 3
      CONNECT_TIMEOUT = 30

      attr_reader :director_uri

      # @return [String]
      attr_accessor :user

      # @return [String]
      attr_accessor :password

      def initialize(director_uri, user = nil, password = nil)
        if director_uri.nil? || director_uri =~ /^\s*$/
          raise DirectorMissing, "no director URI given"
        end

        @director_uri = director_uri
        @user = user
        @password = password
      end

      def create_user(username, password)

      end

      def upload_stemcell(filename, options = {})

      end

      def list_stemcells

      end

      def list_releases

      end

      def list_deployments

      end

      def list_vms(name)

      end

      def upload_release(filename, options = {})

      end

      def delete_stemcell(name, version, options = {})

      end

      def delete_deployment(name, options = {})

      end

      def deploy(manifest_yaml, options = {})

      end

      def setup_ssh(deployment_name, job, index, user,
          public_key, password, options = {})

      end

      def cleanup_ssh(deployment_name, job, user_regex, indexes, options = {})

      end

      def fetch_logs(deployment_name, job_name, index, log_type,
          filters = nil, options = {})
      end

      def fetch_vm_state(deployment_name, options = {})

      end

      def perform_cloud_scan(deployment_name, options = {})

      end

      def list_problems(deployment_name)

      end

      def apply_resolutions(deployment_name, resolutions, options = {})

      end

      def get_task(task_id)

      end

      def get_task_state(task_id)

      end

      def get_task_result(task_id)

      end

      def get_task_result_log(task_id)

      end

      def get_task_output(task_id, offset, log_type = nil)

      end

      def cancel_task(task_id)

      end


    end
  end
end
