module Uhuru::BoshCommander
  class  AppcloudStatus

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

      unless (state == DeploymentState::ERROR) || (state == DeploymentState::NOT_CONFIGURED)
        stats["resources"] = @deployment.get_resources(current_manifest)

        current_manifest["jobs"].each do |job|
          if job["name"] == "router"
            stats["router_ips"] = []
            static_ips = []
            job["networks"].each do |network|
              network["static_ips"].each do |ip|
                static_ips << ip
              end
            end
            stats["router_ips"] << static_ips
          end
        end
      end

      properties = current_manifest["properties"]
      stats["name"] = @deployment.deployment_name
      stats["state"] = state
      stats["api_url"] = properties["cc"]["srv_api_uri"]
      stats["uaa_url"] = properties["uaa_endpoint"]
      stats["web_ui_url"] = "www.#{properties["domain"]}"
      stats["admin_email"] = properties["cc"]["bootstrap_users"][0]["email"]
      stats["contact_email"] = properties["uhuru"]["simple_webui"]["contact"]["email"]
      stats["support_url"] = properties["support_address"]
      stats["services"] = ["mysql_node", "mssql_node", "uhurufs_node", "rabbit_node", "postgresql_node", "redis_node", "mongodb_node"].map { |node|
        current_manifest["jobs"] != nil && current_manifest["jobs"].select{|job| job["name"] == node}.first["instances"] > 0 ? node : nil }.compact
      stats["stacks"] = ["dea", "win_dea"].map { |stack|
        current_manifest["jobs"] != nil && current_manifest["jobs"].select{|job| job["name"] == stack}.first["instances"] > 0 ? stack : nil }.compact
      stats["version"] = current_manifest["release"]["version"]
      stats
    end
  end
end