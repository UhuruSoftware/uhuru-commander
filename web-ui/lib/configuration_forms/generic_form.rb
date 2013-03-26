module Uhuru::BoshCommander
  class GenericForm
    VALUE_TYPE_SAVED = 'saved'
    VALUE_TYPE_VOLATILE = 'volatile'
    VALUE_TYPE_FORM = 'form'
    VALUE_TYPE_LIVE = 'live'

    attr_accessor :name
    attr_accessor :saved_data
    attr_accessor :form_data
    attr_accessor :live_data
    attr_accessor :screens
    attr_accessor :volatile_data


    def initialize(name, saved_data, form_data, live_data)
      @name = name
      @saved_data = saved_data
      @form_data = form_data
      @live_data = live_data
      @volatile_data = nil

      @screens = []

      get_form_config.each do |screen|
        @screens << Screen.new(screen['screen'], self)
      end
    end

    def validate?(value_type)
      result = true
      @screens.each do |screen|
        screen_ok = screen.validate?(value_type)
        result = result && screen_ok
      end

      result
    end

    def get_data(value_type)
      if value_type == GenericForm::VALUE_TYPE_LIVE
        live_data
      elsif value_type == GenericForm::VALUE_TYPE_SAVED
        saved_data
      elsif value_type == GenericForm::VALUE_TYPE_VOLATILE
        volatile_data
      elsif value_type == GenericForm::VALUE_TYPE_FORM
        form_data
      else
        raise "Unknown value type '#{value_type}'"
      end
    end

    def generate_volatile_data!
      if @form_data == nil || @saved_data == nil
        raise "Both 'form' and 'saved' data have to be present in order to generate volatile data."
      end

      @volatile_data = @saved_data

      @screens.each do |screen|
        screen.generate_volatile_data!
      end


    end

    def get_form_config
      $config[:forms][@name]
    end

    def help(use_visibility_link = true)
      help_items = []
      @screens.each do |screen|
        help_items = help_items + screen.help(use_visibility_link)
      end
      help_items
    end
  end
end