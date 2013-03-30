module Uhuru::BoshCommander
  class MonitoringForm < GenericForm

    def initialize(saved_data, form_data, live_data)
      super('monitoring', saved_data, form_data, live_data)
    end

    def self.from_config(form_data)
      monitoring_yml = $config[:nagios][:config_path]

      saved_data = live_data = YAML.load_file(monitoring_yml)

      MonitoringForm.new(saved_data, form_data, live_data)
    end
  end
end