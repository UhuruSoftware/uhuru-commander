module Uhuru::BoshCommander
  class Clouds < RouteBase

    def initialize(app)
      super

      @cloud_menu = {
          :tab_manage =>  'Manage',
          :tab_virtual_machines => 'Virtual Machines',
          :tab_summary => 'Summary'
      }

      @default_cloud_menu = :tab_manage
      @default_cloud_sub_menu = :networks
    end


    get '/products/:product_name' do
      product_name = params[:product_name]

      clouds = []
      CommanderBoshRunner.execute(session) do
        Deployment.deployments_obj(product_name).each do |deployment|
          clouds << DeploymentStatus.new(deployment).status
        end
      end

      render_erb do
        template :clouds
        layout :layout
        var :product_name, product_name
        var :clouds, clouds
        var :error_message, ""
        help 'clouds'
      end

    end

    post '/products/:product_name' do
      product_name = params[:product_name]

      product = Uhuru::BoshCommander::Versioning::Product.get_products[product_name]
      local_versions = product.local_versions
      version = local_versions[local_versions.keys.last]

      clouds = []
      message = ""
      cloud_name = params["create_cloud_name"]

      if !!cloud_name.match(/^[[:alnum:]]+$/)
        CommanderBoshRunner.execute(session) do
          Deployment.deployments_obj(product_name).each do |deployment|
            clouds << DeploymentStatus.new(deployment).status
          end
          if clouds.select{ |cloud| cloud['name'] == cloud_name }.size == 0
            deployment = Deployment.new(cloud_name, product_name)

            blank_manifest_path = File.join($config[:versioning][:dir], product_name, version.version.to_s, "bits", "config", "#{product_name}.yml.erb")
            blank_manifest_template = ERB.new(File.read(blank_manifest_path))

            new_manifest = YAML.load(blank_manifest_template.result(binding))
            new_manifest["release"]["version"] = version.version
            deployment.save(new_manifest)
            clouds << DeploymentStatus.new(deployment).status
          else
            message = "A cloud with the same name already exists"
          end
        end
      else
        message = "Cloud name must contain only alphanumeric characters"
        CommanderBoshRunner.execute(session) do
          Deployment.deployments_obj(product_name).each do |deployment|
            clouds << DeploymentStatus.new(deployment).status
          end
        end
      end

      render_erb do
        template :clouds
        layout :layout
        var :product_name, product_name
        var :clouds, clouds
        var :error_message, message
        help 'clouds'
      end

    end

    get '/products/:product_name/:cloud_name' do
      product_name = params[:product_name]
      cloud_name = params[:cloud_name]

      product = Uhuru::BoshCommander::Versioning::Product.get_products[product_name]
      current_version = File.open(Deployment.new(cloud_name, product_name).deployment_manifest_path) { |file| YAML.load(file)}["release"]["version"].to_s
      version = product.local_versions[current_version]

      manager = PluginManager.new
      manager.add_plugin_version_source(version.version_dir)
      manager.load

      deployment_status = {}
      form = nil

      class_name = "#{product_name.capitalize}Form"
      status_class_name = "#{product_name.capitalize}Status"

      CommanderBoshRunner.execute(session) do
        form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name ,cloud_name, nil)
        deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
        form.validate? GenericForm::VALUE_TYPE_SAVED
      end

      help = Uhuru::BoshCommander::Runner.load_help_file("#{$config[:versioning][:dir]}/#{product_name}/#{version.version}/bits/config/help.yml")
      cloud_summary_help = help['cloud_summary'].map do |help_item|
        help_item << 'cloud_tab_summary_div'
      end

      cloud_vms_help = help['cloud_vms'].map do |help_item|
        help_item << 'cloud_tab_virtual_machines_div'
      end

      erb = File.join(version.version_dir, "bits", "views", "cloud.erb")

      render_erb do
        template File.read(erb)
        layout :layout

        var :form, form
        var :summary, deployment_status
        var :product_name, product_name
        var :cloud_name, cloud_name
        var :value_type, GenericForm::VALUE_TYPE_SAVED
        var :versions, product.local_versions.keys
        var :current_version, current_version

        help form.help
        help cloud_summary_help
        help cloud_vms_help
      end
    end

    post '/products/:product_name/:cloud_name' do
      product_name = params[:product_name]
      cloud_name = params[:cloud_name]

      product = Uhuru::BoshCommander::Versioning::Product.get_products[product_name]
      current_version = File.open(Deployment.new(cloud_name, product_name).deployment_manifest_path) { |file| YAML.load(file)}["release"]["version"].to_s
      version = product.local_versions[current_version]

      is_ok = true
      form = nil
      values_to_show = GenericForm::VALUE_TYPE_FORM
      deployment_status = {}

      help = Uhuru::BoshCommander::Runner.load_help_file("#{$config[:versioning][:dir]}/#{product_name}/#{version.version.to_s}/bits/config/help.yml")
      cloud_summary_help = help['cloud_summary'].map do |help_item|
        help_item << 'cloud_tab_summary_div'
      end

      class_name = "#{product_name.capitalize}Form"
      status_class_name = "#{product_name.capitalize}Status"

      if params.has_key?("btn_save") || params.has_key?("btn_save_and_deploy")

        if params["select_version"].to_s != current_version

          current_version = params["select_version"].to_s
          version = product.local_versions[current_version]

          blank_manifest_path = File.join(version.version_dir, "bits", "config", "#{product_name}.yml.erb")
          blank_manifest_template = ERB.new(File.read(blank_manifest_path))

          new_manifest = YAML.load(blank_manifest_template.result(binding))

          manager = PluginManager.new
          manager.add_plugin_version_source(version.version_dir)
          manager.load

          CommanderBoshRunner.execute(session) do

            form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name, cloud_name, params)
            is_ok = form.upgrade
            if is_ok
              values_to_show = GenericForm::VALUE_TYPE_VOLATILE
            end
            deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
          end

        else

          manager = PluginManager.new
          manager.add_plugin_version_source(version.version_dir)
          manager.load

          CommanderBoshRunner.execute(session) do
            form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name, cloud_name, params)
            is_ok = form.validate?(GenericForm::VALUE_TYPE_FORM)

            if is_ok
              form.generate_volatile_data!
              values_to_show = GenericForm::VALUE_TYPE_VOLATILE
              form.deployment.save(form.get_data(GenericForm::VALUE_TYPE_VOLATILE))

              is_ok = form.validate?(GenericForm::VALUE_TYPE_VOLATILE)
            end
            deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
          end
        end

        if params.has_key?("btn_save") || !is_ok
          erb = File.join(version.version_dir, "bits", "views", "cloud.erb")

          render_erb do
            template File.read(erb)
            layout :layout

            var :form, form
            var :product_name, product_name
            var :cloud_name, cloud_name
            var :summary, deployment_status
            var :value_type, values_to_show
            var :versions, product.local_versions.keys
            var :current_version, current_version

            help form.help
            help cloud_summary_help
          end
        elsif params.has_key?("btn_save_and_deploy")
          request_id = CommanderBoshRunner.execute_background(session) do
            begin
              form.deployment.deploy
            rescue Exception => e
              err e.message.to_s
            end
          end

          action_on_done = "Deployment of cloud '#{cloud_name}' finished. Click <a href='/products/#{product_name}/#{cloud_name}?menu=tab_summary'>here</a> to view cloud summary."
          redirect Logs.log_url request_id, action_on_done
        end

      elsif params.has_key?("version")
        current_version = params["version"].to_s
        version = product.local_versions[current_version]

        manager = PluginManager.new
        manager.add_plugin_version_source(version.version_dir)
        manager.load

        CommanderBoshRunner.execute(session) do
          form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name, cloud_name, params)
          is_ok = form.validate?(GenericForm::VALUE_TYPE_FORM)

          if is_ok
            form.generate_volatile_data!
            values_to_show = GenericForm::VALUE_TYPE_VOLATILE
          end
          deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
        end
        erb = File.join(version.version_dir, "bits", "views", "cloud.erb")

        render_erb do
          template File.read(erb)
          layout :layout

          var :form, form
          var :product_name, product_name
          var :cloud_name, cloud_name
          var :summary, deployment_status
          var :value_type, values_to_show
          var :versions, product.local_versions.keys
          var :current_version, current_version

          help form.help
          help cloud_summary_help
        end
      elsif params.has_key?("btn_tear_down")
        request_id = CommanderBoshRunner.execute_background(session) do
          begin
            deployment = Deployment.new(cloud_name, product_name)
            deployment.tear_down
          rescue Exception => e
            err e.message.to_s
          end
        end

        action_on_done = "Tear-down of cloud '#{cloud_name}' finished. Click <a href='/products/#{product_name}/#{cloud_name}'>here</a> to view cloud configuration."
        redirect Logs.log_url request_id, action_on_done
      elsif params.has_key?("btn_delete")
        request_id = CommanderBoshRunner.execute_background(session) do
          begin
            deployment = Deployment.new(cloud_name, product_name)
            deployment.delete
          rescue Exception => e
            err e.message.to_s
          end
        end

        action_on_done = "Delete of cloud '#{cloud_name}' finished. Click <a href='/products/#{product_name}'>here</a> for cloud management."
        redirect Logs.log_url request_id, action_on_done
      elsif params.has_key?("btn_export")
        params.delete("btn_export")
        send_file Deployment.get_deployment_yml_path(cloud_name, product_name), :filename => "#{cloud_name}.yml", :type => 'Application/octet-stream'
      elsif params.has_key?("file_input")
        tempfile = params['file_input'][:tempfile]
        manifest = YAML.load_file(tempfile)
        params.delete("file_input")

        blank_manifest_path = File.join($config[:versioning][:dir], product_name, version.version.to_s, "bits", "config", "#{product_name}.yml.erb")
        blank_manifest_template = ERB.new(File.read(blank_manifest_path))
        new_manifest = YAML.load(blank_manifest_template.result(binding))

        forms_yml = YAML.load_file("#{$config[:versioning][:dir]}/#{product_name}/#{version.version.to_s}/bits/config/forms.yml")

        forms_yml[product_name].each do |screen|
          screen['fields'].each do |field|
            unless field['type'] == 'separator'

              yml_keys = field['yml_key']

              unless yml_keys.is_a? Array
                yml_keys = [yml_keys]
              end

              yml_keys.each do |key|
                begin
                  new_value = nil
                  eval("new_value=manifest#{key}")
                  if new_value
                    eval("new_manifest#{key} = manifest#{key}")
                  end
                rescue => e
                  $logger.warn "Could not import value #{field['label']} for cloud #{cloud_name}"
                end
              end
            end
          end
        end

        form_params = {}

        manager = PluginManager.new
        manager.add_plugin_version_source(version.version_dir)
        manager.load

        CommanderBoshRunner.execute(session) do
          form = Uhuru::BoshCommander.const_get(class_name).send(:from_imported_data, cloud_name, new_manifest)

          form.screens.each do |screen|
            screen.fields.each do |field|
              form_params[field.html_form_id] = field.get_value(GenericForm::VALUE_TYPE_SAVED)
            end
          end

          values_to_show = GenericForm::VALUE_TYPE_FORM
          form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name, cloud_name, form_params)
          form.validate? GenericForm::VALUE_TYPE_FORM
          deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
        end

        erb = File.join(version.version_dir, "bits", "views", "cloud.erb")

        render_erb do
          template File.read(erb)
          layout :layout

          var :form, form
          var :product_name, product_name
          var :cloud_name, cloud_name
          var :summary, deployment_status
          var :value_type, values_to_show

          help form.help
          help cloud_summary_help
        end

      else
        manager = PluginManager.new
        manager.add_plugin_version_source(version.version_dir)
        manager.load

        CommanderBoshRunner.execute(session) do
          form = Uhuru::BoshCommander.const_get(class_name).send(:from_cloud_name ,cloud_name, nil)
          deployment_status = Uhuru::BoshCommander.const_get(status_class_name).new(form.deployment).status
          form.validate? GenericForm::VALUE_TYPE_SAVED
        end

        cloud_vms_help = help['cloud_vms'].map do |help_item|
          help_item << 'cloud_tab_virtual_machines_div'
        end

        erb = File.join(version.version_dir, "bits", "views", "cloud.erb")

        render_erb do
          template File.read(erb)
          layout :layout

          var :form, form
          var :summary, deployment_status
          var :product_name, product_name
          var :cloud_name, cloud_name
          var :value_type, GenericForm::VALUE_TYPE_SAVED
          var :versions, product.local_versions.keys
          var :current_version, current_version

          help form.help
          help cloud_summary_help
          help cloud_vms_help
        end
      end
    end

    get '/products/:product_name/:cloud_name/vms' do
      vms_list = {}

      product_name = params[:product_name]
      cloud_name = params[:cloud_name]

      CommanderBoshRunner.execute(session) do
        if Deployment.new(cloud_name, product_name).get_state() == DeploymentState::DEPLOYED
          vms = Vms.new()
          vms_list = vms.list(cloud_name)
        end
      end

      vms_list.to_json
    end
  end
end