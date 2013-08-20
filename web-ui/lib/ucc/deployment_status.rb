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
      if (current_manifest["release"])
        stats["version"] = current_manifest["release"]["version"]
      else
        stats["version"] = current_manifest["releases"][0]["version"]
      end
      stats["resources"] = @deployment.get_resources current_manifest
      stats["track_url"] = @deployment.get_track_url
      stats
    end
  end
end