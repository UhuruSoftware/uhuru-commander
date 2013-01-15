module Uhuru
  module Ucc
    class Director

      def initialize(director_uri, user = nil, password = nil)

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
