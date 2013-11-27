module Uhuru::BoshCommander
  # Form for configuring Nagios monitoring
  class MonitoringForm < GenericForm

    # Initializes form
    # saved_data = existing data on the server
    # form_data = data displayed on the form
    # live_data = existing data from deployment manifest
    #
    def initialize(saved_data, form_data, live_data)
      forms_file = File.join(File.expand_path("../../../config/ucc_forms.yml", __FILE__))
      @form = File.open(forms_file) { |file| YAML.load(file)}
      super('monitoring', saved_data, form_data, live_data)
    end

    # Loads monitoring configurations from config file
    # form_data = data displayed on the form
    #
    def self.from_config(form_data)
      properties_yml = $config[:properties_file]
      live_data = YAML.load_file(properties_yml)
      saved_data = live_data = YAML.load_file(monitoring_yml)

      MonitoringForm.new(saved_data, form_data, live_data)
    end
  end
end