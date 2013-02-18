require 'yaml'
require 'validations'

module Uhuru::BoshCommander
  class FormGenerator

    def initialize(deployment_file, forms_file, deployment_live)
      @deployment_manifest = deployment_file
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
        local_value = form_data.has_key?(html_field[:id]) ? form_data[html_field[:id].to_sym] : get_local_value(form, screen_name, field)

        local_value = "#{local_value}"

        html_field[:value] = "#{local_value}"
        html_field[:value_live] = get_live_value(form, screen_name, field['name'])
        html_field[:error] = [validate_type(local_value, field['type']), validate_value(field['type'], local_value)].join("\n").strip

        if (html_field[:type] == 'select')
          html_field[:select_options] = field['items'].split(',')
        end

        changed = html_field[:value] != html_field[:value_live]
        if changed
          #save_local_deployment(form_data)
        end
        has_error = html_field[:error] == '' ? '' : 'error'
        html_field[:class] = ['config_field', field['type'], html_field[:type], form, screen_name, field['name'], changed ? 'changed' : '', has_error].join(' ').strip

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

      form_data.each {|key, value|
        yml_key = get_yaml_key(key)
        unless yml_key.nil?
          eval("@deployment" + yml_key + "=" + value)
        end
      }

      File.open(@deployment_manifest, "w+") {|f| f.write(@deployment.to_yaml)}
      is_ok
    end

    def get_table_errors(form_data)
      table_errors = {}

      table_errors[:networks] = (generate_form("cloud", "Networks", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:compilation] = (generate_form("cloud", "Compilation", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:resource_pools] = (generate_form("cloud", "Resource Pools", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:update] = (generate_form("cloud", "Update", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:deas] = (generate_form("cloud", "DEAs", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:services] = (generate_form("cloud", "Services", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:properties] = (generate_form("cloud", "Properties", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:service_plans] = (generate_form("cloud", "Service Plans", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:advanced] = (generate_form("cloud", "Advanced", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0

      table_errors
    end


    private

    def validate_type(value, type)
      Validations.validate_field(value, type)
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

      value = ""
      if field["yml_key"]

        value = eval("yml" + field["yml_key"])

      else
        value = "192.168.1.19"
      end
      value
      #"dasdSDAD"
      #"142342"
    end

    def get_yaml_key(id)
      keys = id.split ":"
      expr = "@forms[\"" + keys[0] + "\"].select{|cl| cl[\"screen\"] == \"" + keys[1] + "\"}.first[\"fields\"].select{|field| field[\"name\"] == \"" + keys[2] + "\"}.first[\"yml_key\"]"
      eval(expr)
    end

  end
end


#gen = Uhuru::FormGenerator.new '../config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms.yml', {}
#gen.generate_form('infrastructure', 'Networking')

