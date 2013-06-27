module Uhuru::BoshCommander
  class Infrastructure < RouteBase
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

          redirect '/'
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
  end
end