module Uhuru::BoshCommander
  class  WordpressStatus3_0_0

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

      stats
    end
  end
end