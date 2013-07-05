module Uhuru::BoshCommander
  class Monitoring < RouteBase
    get '/monitoring' do

      render_erb do
        template :monitoring
        layout :layout
      end
    end

    post '/monitoring' do
      params.delete("btn_update")

      values_to_show = GenericForm::VALUE_TYPE_FORM
      monitoring_yml = $config[:nagios][:config_path]

      form = MonitoringForm.from_config(params)
      is_ok = form.validate? GenericForm::VALUE_TYPE_FORM

      if is_ok
        values_to_show = GenericForm::VALUE_TYPE_VOLATILE
        form.generate_volatile_data!
        is_ok = form.validate? GenericForm::VALUE_TYPE_VOLATILE
        if is_ok

          volatile_data = form.get_data(GenericForm::VALUE_TYPE_VOLATILE)

          File.open(monitoring_yml, "w") do |file|
            file.write(volatile_data.to_yaml)
          end

          redirect '/monitoring'
        end
      end

      unless is_ok
        render_erb do
          template :monitoring
          layout :layout
          var :form, form
          var :value_type, values_to_show
          help form.help(false)
        end
      end
    end
  end
end