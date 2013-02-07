require 'yaml'
require 'validations'

module Uhuru::BoshCommander
  class FormGenerator

    def initialize(deployment_file, forms_file, deployment_live)
      @deployment = YAML.load_file(deployment_file)
      @deployment_live = deployment_live
      @forms = YAML.load_file(forms_file)
    end

    def generate_form(form, screen_name, form_data = {} )
      forms = YAML.load_file('../config/forms.yml')
      screen = forms[form].find { |item| item['screen'] == screen_name }

      html_fields = []

      screen['fields'].each do |field|
        html_field = Hash.new

        html_field[:type] = case field['type']
                              when 'numeric'
                                'text'
                              when 'ip'
                                'text'
                              when 'ip_range'
                                'text'
                              when 'string'
                                'text'
                              when 'product_key'
                                'text'
                              when 'text'
                                'textarea'
                              when 'boolean'
                                'checkbox'
                              when 'list'
                                'select'
                            end

        html_field[:id] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:input_name] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:name] = field['label']
        html_field[:description] = field['description']
        #puts form_data[html_field[:id].to_sym]
        local_value = form_data.has_key?(html_field[:id]) ? form_data[html_field[:id].to_sym] : get_local_value(form, screen_name, field['name'])

        html_field[:value] = local_value
        html_field[:value_live] = get_live_value(form, screen_name, field['name'])
        html_field[:error] = [validate_type(local_value, field['type']), validate_value(field['type'], local_value)].join("\n").strip

        changed = html_field[:value] != html_field[:value_live] ? 'changed' : ''
        has_error = html_field[:error].to_s == "true" ? '' : 'error'
        html_field[:class] = ['config_field', field['type'], html_field[:type], form, screen_name, field['name'], changed, has_error].join(' ').strip

        html_fields << html_field
      end
      html_fields
    end


    #we need to make sure the button parameter data is not posted (save button, update button, delete button ... etc ... )
    def validate_form(form_data)
      is_ok = true

        #form_data.each do |name, value|
        #  name.split(",").each do |this_name|
        #    Validations.validate_field(value, this_name)
        #    puts this_name.to_s
        #  end
        #end

      is_ok
    end

    def save_local_deployment(form_data)
      is_ok = true

      is_ok
    end

    private

    def validate_type(value, type)
      if Validations.validate_field(value, type) == true
        is_ok = true
      else
        is_ok = Validations.validate_field(value, type)
      end

      return is_ok
    end

    def validate_value(value, field_id)

    end


    def get_local_value(form, screen, field)
      get_yml_value(@deployment, form, screen, field)
    end

    def get_live_value(form, screen, field)
      get_yml_value(@deployment_live, form, screen, field)
      #"199"
    end

    def get_yml_value(yml, form, screen, field)
      #Random.rand(2).to_i
      "192.168.1.19"
      #"dasdSDAD"
      #"142342"
    end

  end
end


#gen = Uhuru::FormGenerator.new '../config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms.yml', {}
#gen.generate_form('infrastructure', 'Networking')

