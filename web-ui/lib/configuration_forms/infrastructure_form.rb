module Uhuru::BoshCommander
  # Form for configuring the UCC infrastructure
  class InfrastructureForm < GenericForm

    # Initializes form
    # saved_data = existing data on the server
    # form_data = data displayed on the form
    # live_data = existing data from deployment manifest
    #
    def initialize(saved_data, form_data, live_data)
      forms_file = File.join(File.expand_path("../../../config/infrastructure_form.yml", __FILE__))
      @form = File.open(forms_file) { |file| YAML.load(file)}
      super('infrastructure', saved_data, form_data, live_data)
    end

    # Loads infrastructure configurations from config file, if there are no saved data will load data from a dummy
    # config file
    # form_data = data displayed on the form
    #
    def self.from_config(form_data)
      properties_yml = $config[:properties_file]

      if File.exists? properties_yml
        saved_data = YAML.load_file(properties_yml)
      else
        blank_infrastructure_template = ERB.new(File.read($config[:blank_properties_file]))
        saved_data = YAML.load(blank_infrastructure_template.result(binding))
      end

      live_data = YAML.load_file(properties_yml)

      InfrastructureForm.new(saved_data, form_data, live_data)
    end

  end
end