module Uhuru::BoshCommander
  class MonitoringForm < GenericForm

    def initialize(saved_data, form_data, live_data)
      forms_file = File.join(File.expand_path("../../../config/ucc_forms.yml", __FILE__))
      @form = File.open(forms_file) { |file| YAML.load(file)}
      super('monitoring', saved_data, form_data, live_data)
    end

    def self.from_config(form_data)
      properties_yml = $config[:properties_file]
      live_data = YAML.load_file(properties_yml)
      saved_data = live_data = YAML.load_file(monitoring_yml)

      MonitoringForm.new(saved_data, form_data, live_data)
    end
  end
end