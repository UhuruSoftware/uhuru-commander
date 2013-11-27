module Uhuru::BoshCommander
  # Class that manages a screen on configuration form in webui, and their correspondence in config files
  class Screen
    attr_accessor :name
    attr_accessor :fields

    # Initializes screen
    # name = screen name
    # form = the form screen belongs to
    #
    def initialize(name, form)
      @name = name
      @form = form
      @fields = []

      fields = get_screen_config['fields']
      if ["infrastructure", "monitoring"].include?(@form.name)
        fields.each do |field|
          @fields << Field.new(field['name'], self, @form)
        end
      else
        field_class_name = "#{form.product_name.capitalize}Field"
        fields.each do |screen_field|
          @fields << Uhuru::BoshCommander.const_get(field_class_name).new(screen_field['name'], self, @form)
        end
      end

    end

    # Validates data by it's type
    # value_type = data type (form, volatile, saved, live)
    #
    def validate?(value_type)
      result = true
      @fields.each do |field|
        field_ok = field.validate?(value_type)
        result = result && field_ok
      end

      result
    end

    # Checks the fields on the screen for errors
    #
    def has_errors?
      @fields.any? do |field|
        field.error != ''
      end
    end

    # Gets a hash with the screen configurations from config file by screen's name
    #
    def get_screen_config
      screens = @form.get_form_config.select do |screen|
        screen['screen'] == @name
      end

      unless screens.size == 1
        raise "Invalid results when looking for screen '#{ @name }'"
      end

      screens[0]
    end

    # Gets the id of the screen
    #
    def id
      get_screen_config['id']
    end

    # Generates volatile data for all fields on a screen
    #
    def generate_volatile_data!
      @fields.each do |field|
        field.generate_volatile_data!
      end
    end

    # Loads help div for a form, concatenating help for each filed
    # use_visibility_link = help status, if it's visible or not on the form
    #
    def help(use_visibility_link)
      @fields.map do |field|
        field.help use_visibility_link
      end
    end
  end
end