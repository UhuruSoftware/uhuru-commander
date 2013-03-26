module Uhuru::BoshCommander
  class Infrastructure < RouteBase
    get '/infrastructure' do

      form = InfrastructureForm.from_config(nil)
      form.validate? GenericForm::VALUE_TYPE_SAVED

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
      infrastructure_yml = $config[:infrastructure_yml]
      form = InfrastructureForm.from_config(params)
      is_ok = form.validate? GenericForm::VALUE_TYPE_FORM

      if is_ok
        values_to_show = GenericForm::VALUE_TYPE_VOLATILE
        form.generate_volatile_data!
        is_ok = form.validate? GenericForm::VALUE_TYPE_VOLATILE
        if is_ok

          volatile_data = form.get_data(GenericForm::VALUE_TYPE_VOLATILE)

          File.open(infrastructure_yml, "w") do |file|
            file.write(volatile_data.to_yaml)
          end

          $infrastructure_update_request = CommanderBoshRunner.execute_background(session) do
            begin
              infrastructure = BoshInfrastructure.new
              infrastructure.setup(infrastructure_yml)
            rescue Exception => e
              err e.message.to_s
            end
            $infrastructure_update_request = nil
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