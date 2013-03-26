module Uhuru::BoshCommander
  class Screen
    attr_accessor :name
    attr_accessor :fields

    def initialize(name, form)
      @name = name
      @form = form
      @fields = []

      get_screen_config['fields'].each do |field|
        @fields << Field.new(field['name'], self, @form)
      end
    end

    def validate?(value_type)
      result = true
      @fields.each do |field|
        field_ok = field.validate?(value_type)
        result = result && field_ok
      end

      result
    end

    def has_errors?
      @fields.any? do |field|
        field.error != ''
      end
    end

    def get_screen_config
      screens = @form.get_form_config.select do |screen|
        screen['screen'] == @name
      end

      unless screens.size == 1
        raise "Invalid results when looking for screen '#{ @name }'"
      end

      screens[0]
    end

    def id
      get_screen_config['id']
    end

    def generate_volatile_data!
      @fields.each do |field|
        field.generate_volatile_data!
      end
    end

    def help(use_visibility_link)
      @fields.map do |field|
        field.help use_visibility_link
      end
    end
  end
end