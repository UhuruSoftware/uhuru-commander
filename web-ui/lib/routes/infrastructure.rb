module Uhuru::BoshCommander
  # a class used for the infrastructure page
  class Infrastructure < RouteBase

    # get method for the infrastructure page
    get '/infrastructure' do
      form = InfrastructureForm.from_config(nil)

      render_erb do
        template :infrastructure
        layout :layout
        var :form, form
        var :value_type, GenericForm::VALUE_TYPE_SAVED
        help form.help(false)
      end
    end

    # post method for infrastructure
    post '/infrastructure' do
      params.delete("btn_update")

      values_to_show = GenericForm::VALUE_TYPE_FORM
      properties_yml = $config[:properties_file]
      $config[:bind_address] = params['infrastructure:CPI:net_interface']
      form = InfrastructureForm.from_config(params)
      is_ok = form.validate? GenericForm::VALUE_TYPE_FORM

      if is_ok
        values_to_show = GenericForm::VALUE_TYPE_VOLATILE
        form.generate_volatile_data!
        is_ok = form.validate? GenericForm::VALUE_TYPE_VOLATILE
        if is_ok

          volatile_data = form.get_data(GenericForm::VALUE_TYPE_VOLATILE)

          File.open(properties_yml, "w") do |file|
            file.write(volatile_data.to_yaml)
          end
          request_id = CommanderBoshRunner.execute_background(session) do
            begin
              say ('Setup infrastructure')
              Uhuru::BoshCommander::ConfigUpdater.apply_spec_for_all_jobs
              say ('Restarting services')
              restart_monit

              properties = YAML.load_file($config[:properties_file])
              $config[:versioning][:blobstore_provider] = properties["properties"]["compiled_package_cache"]["provider"]
              $config[:versioning][:blobstore_options] = Config.symbolize_hash properties["properties"]["compiled_package_cache"]["options"]
            rescue Exception => ex
              err ex
            end
          end
          action_on_done = "Infrastructure setup done. Click <a href='/infrastructure'>here</a> to return to infrastructure view."
          redirect Logs.log_url(request_id, action_on_done)
        end
      end

      unless is_ok
        render_erb do
          template :infrastructure
          layout :layout
          var :form, form
          var :value_type, values_to_show
          help form.help(false)
        end
      end
    end

    private

    def restart_monit
      monit = Monit.new
      monit.restart_all_services
    end
  end
end