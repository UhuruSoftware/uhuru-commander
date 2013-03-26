module Uhuru::BoshCommander
  class InfrastructureForm < GenericForm

    def initialize(saved_data, form_data, live_data)
      super('infrastructure', saved_data, form_data, live_data)
    end

    def self.from_config(form_data)
      infrastructure_yml = $config[:infrastructure_yml]
      director_yml = $config[:director_yml]

      unless File.exists? infrastructure_yml
        infrastructure_yml = director_yml
      end

      saved_data = YAML.load_file(infrastructure_yml)
      live_data = YAML.load_file(director_yml)

      InfrastructureForm.new(saved_data, form_data, live_data)
    end

  end
end