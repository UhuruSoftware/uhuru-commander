module Uhuru::Ucc

  class Deployment

    attr_reader :deployment_name
    attr_reader :deployment_dir
    attr_reader :deployment_manifest_path


    def initialize(deployment_name)
      @deployment_name = deployment_name

      @deployment_dir = File.expand_path("../../../cf_deployments/#{deployment_name}", __FILE__)

      @deployment_manifest_path = File.join("#{@deployment_dir}","#{deployment_name}.yml")

      #create deployment folder
      if (Dir["#{@deployment_dir}"].empty?)
        Dir.mkdir @deployment_dir
      end

    end

    #saves the deployment manifest
    def save(deployment_manifest)
      @manifest = deployment_manifest
      @manifest["name"] = @deployment_name

      #set director UUID
      director = Thread.current.current_session[:command].instance_variable_get("@director")
      @manifest["director_uuid"] =  director.uuid

      #write the file
      File.open(@deployment_manifest_path, 'w') do |out|
        YAML.dump(@manifest, out)
      end
    end

    #Returns an array of all the deployments
    def self.deployments
      folders = Dir.entries('../cf_deployments').select {|entry|
        !(entry =='.' || entry == '..' || File.file?(File.join("../cf_deployments/",entry)))
      }
      folders
    end

    #start the deployment process
    def deploy()
      info = deployment_info
      if info["state"] == "Deployed"
        update
        say "Deployment #{@deployment_name} updated".green
        return
      end
      if info["state"] != "Saved"
        raise "Cannot deploy, current state is #{info["state"]}"
      end

      split_manifest

      info = deployment_info
      total_steps = info["total_steps"]

      #deploy
      command = deployment_command
      for i in 0 .. total_steps.to_i
        current_file = File.join(@deployment_dir, "step_#{i}_#{@deployment_name}.yml")
        command.set_current(current_file)
        command.perform
        File.delete(current_file)
      end
      say "Deployment finished".green

    end

    #retrieves deployment information
    def status
      state = get_state
      current_manifest = nil
      if (state == "Deployed")
        current_manifest = get_manifest()
        if current_manifest == nil
          return {}
        end
      else
        if (state == "Saved")
          current_manifest = load_yaml_file(@deployment_manifest_path)
        else
          raise "Cannot get status, current state is #{state}"
        end

      end
      stats = {}
      stats["resources"] = get_resources(current_manifest)

      #get router ips
      #i = 1
      current_manifest["jobs"].each do |job|
        if (job["name"] == "router")
          stats["router_ips"] = []
          static_ips = []
          job["networks"].each do |network|
            network["static_ips"].each do |ip|
              static_ips << ip
            end
          end
          stats["router_ips"] << static_ips
          #i = i + 1
        end
      end

      properties = current_manifest["properties"]
      stats["api_url"] = properties["cc"]["srv_api_uri"]
      stats["uaa_url"] = properties["uaa_endpoint"]
      stats["web_ui_url"] = "www.#{properties["domain"]}"
      stats["admin_email"] = properties["uhuru"]["simple_webui"]["admin_email"]
      stats["contact_email"] = properties["uhuru"]["simple_webui"]["contact"]["email"]
      stats["support_url"] = properties["support_address"]

      stats

    end


    def update()
      command = deployment_command
      current_file = File.join(@deployment_dir, "#{@deployment_name}.yml")
      command.set_current(current_file)
      command.perform

    end

    #the VMs and deployment manifests are deleted.
    def delete()
      info = deployment_info
      if (info["state"] != "Saved")
        tear_down
      end

      #clean the files on disk
      FileUtils.rm_rf "#{@deployment_dir}"
      say "Deployment deleted".green
    end

    #returns the deployment manifest. If save_as is provided, also saves the deployment manifest to a flie
    def get_manifest(save_as = nil)
      info = deployment_info
      if (info["state"] != "Deployed")
        raise "Cannot get deployment manifest, current deployment state is #{info["state"]}"
      end

      director = Thread.current.current_session[:command].instance_variable_get("@director")
      deployment = director.get_deployment(@deployment_name)

      if save_as
        File.open(save_as, "w") do |f|
          f.write(deployment["manifest"])
        end
      end

      if deployment["manifest"] == nil
        return nil
      end

      YAML.load(deployment["manifest"])
    end

    #delete VMs corresponding to this deployment
    def tear_down()

      #delete deployment
      command = deployment_command
      command.delete(@deployment_name)

    end

    # returns the status of the current deployment
    def get_status()
      deployment_info
    end

    private

    def get_resources(deployment_manifest)
      result = {}
      total_cpu = 0
      total_RAM = 0
      total_disk = 0
      deployment_manifest["resource_pools"].each do |resource_pool|
        total_cpu +=  resource_pool["cloud_properties"]["cpu"].to_i * resource_pool["size"].to_i
        total_RAM += resource_pool["cloud_properties"]["ram"].to_i * resource_pool["size"].to_i
        total_disk += (get_stemcell_disk(resource_pool["stemcell"]) + resource_pool["cloud_properties"]["disk"].to_i) * resource_pool["size"].to_i
      end
      deployment_manifest["jobs"].each do |job|
        total_disk += job["persistent_disk"].to_i * job["instances"].to_i
      end
      result["total_cpu"] = total_cpu
      result["total_RAM"] = total_RAM
      result["total_disk"] = total_disk
      result
    end

    def get_stemcell_disk(stemcell)
      $config[:bosh][:stemcells].each do |stemcell_type, config_stemcell|
        if (config_stemcell[:name] == stemcell["name"] && config_stemcell[:version] == stemcell["version"])
          return config_stemcell[:system_disk].to_i
        end
      end
      0
    end

    def deployment_command
      command = Thread.current.current_session[:command]
      deployment_cmd = Bosh::Cli::Command::Deployment.new
      deployment_cmd.instance_variable_set("@options", command.instance_variable_get("@options"))
      deployment_cmd
    end

    def split_manifest
      StepDeploymentGenerator.generate_step_deployment(@deployment_manifest_path, @deployment_dir)
    end

    def get_info_steps
      existing_manifests = Dir["#{@deployment_dir}/step_*_*.yml"].map {|entry| File.basename(entry, ".yml") }
      steps = existing_manifests.map {|entry| entry.match(/(?!step_)(0|[1-9][0-9]*)(?=_)/)[0].to_i}
      return steps.min, steps.max
    end


    def deployment_info
      state = get_state
      current_step = 0
      total_steps = 0

      if (state == "Deployed" || state == "Saved")
        current_step, total_steps = get_info_steps
      end

      info = { "current_step" => current_step,
               "total_steps" => total_steps,
               "state" => state }

      info
    end

    def get_state
      state = "Not Saved"
      deployments = Thread.current.current_session[:command].instance_variable_get("@director").list_deployments
      existing_manifests = Dir['../cf_deployments/cloud-foundry/step_*_*.yml']

      split_files = false
      split_files = true if (existing_manifests.length > 0)

      local_manifest = false
      local_manifest = true if (File.exist? @deployment_manifest_path)

      #determine if director contains the deployment
      director_deployment = false
      if (!deployments.empty?)
        deployments.each do |d|
          if (d["name"] == @deployment_name)
            director_deployment = true
            break
          end
        end
      end

      if (split_files)
        if (director_deployment)
          if (local_manifest)
            "Deploying"
          else
            "Error"
          end
        else
          "Error"
        end
      end
      if (director_deployment)
        if (local_manifest)
          "Deployed"
        else
          "Error"
        end
      else
        if (local_manifest)
          "Saved"
        else
          "Not Saved"
        end
      end
    end
  end
end
