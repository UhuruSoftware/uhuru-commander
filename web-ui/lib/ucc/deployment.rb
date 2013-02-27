module Uhuru::Ucc

  class Deployment

    attr_reader :deployment_name

    def initialize(deployment_name)
      @deployment_name = deployment_name
      @deployment_dir = "../cf_deployments/#{deployment_name}"
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
      folders = Dir.entries('../cf_deployments').select {|entry| !(entry =='.' || entry == '..') }
      folders
    end

    #start the deployment process
    def deploy()
      info = deployment_info
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

    def update()
      if (!deployment_info)
        rais "Deployment does not exist"
      end


    end

    #the VMs and deployment manifests are deleted.
    def delete()
      info = deployment_info
      if (info["state"] != "Saved")
        tear_down
      end

      #clean the files on disk
      FileUtils.rm_rf "#{@deployment_dir}"
      File.delete("../cf_deployments/local/#{@deployment_name}.yml")
      say "Deployment deleted".green
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
      existing_manifests = Dir['../cf_deployments/cloud-foundry/step_*_*.yml'].map {|entry| File.basename(entry, ".yml") }
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