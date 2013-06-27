module Uhuru::BoshCommander
  class InfrastructureForm < GenericForm

    def initialize(saved_data, form_data, live_data)
      forms_file = File.join(File.expand_path("../../../config/infrastructure_form.yml", __FILE__))
      @form = File.open(forms_file) { |file| YAML.load(file)}
      super('infrastructure', saved_data, form_data, live_data)
    end

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