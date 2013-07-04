module Uhuru::BoshCommander
  class DeploymentStatus

    attr_reader :deployment

    def initialize(deployment)
      @deployment = deployment
    end

    #retrieves deployment information
    def status
      state = @deployment.get_state
      current_manifest = nil
      if state == DeploymentState::DEPLOYED
        current_manifest = @deployment.get_manifest()
      else
        current_manifest = load_yaml_file(@deployment.deployment_manifest_path)
      end

      stats = {}
      properties = current_manifest["properties"]
      stats["name"] = @deployment.deployment_name
      stats["state"] = state
      stats["version"] = current_manifest["release"]["version"]
      stats
    end
  end
end