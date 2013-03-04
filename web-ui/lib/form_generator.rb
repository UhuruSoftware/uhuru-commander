require 'yaml'
require 'validations'
require 'ipaddr'
require 'netaddr'
require 'fileutils'
require 'securerandom'
require 'pathname'
require 'network_helper'
require 'ucc/deployment'

module Uhuru::BoshCommander
  class FormGenerator
    attr_accessor :deployment

    def self.get_clouds
      clouds = []
      Uhuru::Ucc::Deployment.deployments.each do |cloud_name|
        cloud = {}
        cloud[:name] = cloud_name
        cloud[:status] = get_cloud_status(cloud_name)
        cloud[:services] = ""
        cloud[:frameworks] = ""
        clouds << cloud
      end
      clouds
    end

    def initialize(parameters = {})
      @is_infrastructure = parameters[:is_infrastructure]
      if @is_infrastructure
        director_yml = File.join($config[:bosh][:base_dir], 'jobs','micro_vsphere','director','config','director.yml.erb')
        if File.exists?(File.expand_path('../../config/infrastructure.yml', __FILE__))
          @deployment = File.open(File.expand_path('../../config/infrastructure.yml', __FILE__)) { |file| YAML.load(file)}
        else
          @deployment = File.open(director_yml) { |file| YAML.load(file)}
        end
        @deployment_live = File.open(director_yml) { |file| YAML.load(file)}
      else
        @deployment_name = parameters[:deployment_name]
        @deployment = File.open(File.expand_path("../../cf_deployments/#{@deployment_name}/#{@deployment_name}.yml", __FILE__)) { |file| YAML.load(file)}
        @deployment_obj = Uhuru::Ucc::Deployment.new(@deployment_name)
        begin
          @deployment_live = @deployment_obj.get_manifest
        rescue Exception => ex
          puts ex
        end

      end
      @forms = File.open(File.expand_path("../../config/forms.yml", __FILE__)) { |file| YAML.load(file)}
    end

    def generate_form(form, screen_name, form_data = {} )
      screen = @forms[form].find { |item| item['screen'] == screen_name }

      html_fields = []

      screen['fields'].each do |field|
        html_field = Hash.new

        html_field[:type] = case field['type']
                              when 'separator'
                                'separator'
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
                              when 'array_ip_range'
                                'text'
                              when 'array_ip'
                                'text'
                              when 'array_string'
                                'text'
                            end

        html_field[:id] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:input_name] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:name] = field['label']
        html_field[:description] = field['description']
        local_value = form_data.has_key?(html_field[:id]) ? form_data[html_field[:id].to_sym] : get_local_value(form, screen_name, field)
        live_value = get_live_value(form, screen_name, field)

        if field["type"].start_with?('array_')
          if local_value.kind_of?(Array)
            html_field[:value] = local_value.join(';')
          else
            html_field[:value] = "#{local_value}"
          end
          if live_value.kind_of?(Array)
            html_field[:value_live] = live_value.join(';')
          else
            html_field[:value_live] = "#{live_value}"
          end


        else
          local_value = "#{local_value}"
          html_field[:value] = "#{local_value}"
          live_value = "#{live_value}"
          html_field[:value_live] = "#{live_value}"
        end

        html_field[:error] = [validate_type(local_value, field['type']), validate_value(html_field[:id], form_data)].join("\n").strip

        if (html_field[:type] == 'select')
          html_field[:select_options] = field['items'].split(',')
          html_field[:error] = [validate_type(html_field[:select_options], field['type']), validate_value(html_field[:id], form_data)].join("\n").strip
        else
          html_field[:error] = [validate_type(local_value, field['type']), validate_value(html_field[:id], form_data)].join("\n").strip
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

    def save_local_deployment(page, form_data)
      @forms[page].each{|screen|
        screen["fields"].each{|field|
          if field["yml_key"]
            id = "#{page}:#{screen["screen"]}:#{field['name']}"
            value = form_data[id]
            if field["yml_key"].kind_of?(Array)
              field["yml_key"].each do |key|
                if field['type'] == 'boolean'
                  if value == nil
                    value = false
                  else
                    value = true
                  end
                elsif field['type'].start_with?('array_')
                  value = value.split(';')
                elsif field['type'] == 'numeric'
                  value = value.to_i
                end
                eval('@deployment' + key + ' = value')
              end
            else
              key = field["yml_key"]
              if field['type'] == 'boolean'
                if value == nil
                  value = false
                else
                  value = true
                end
              elsif field['type'].start_with?('array_')
                value = value.split(';')
              elsif field['type'] == 'numeric'
                value = value.to_i
              end
              eval('@deployment' + key + ' = value')
            end
          end
        }
      }

      if page == "cloud"
        @deployment["resource_pools"].each {|pool|
          pool["size"] = @deployment["jobs"].select{|job| job["resource_pool"] == pool["name"]}.size
        }

        set_ips(form_data)
        configure_service_gateways(form_data)

        if !@deployment_live
          @deployment["properties"]["nfs_server"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("debian_nfs_server") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nfs_server"]["network"] = @deployment["networks"][0]["subnets"][0]["range"]
          @deployment["properties"]["syslog_aggregator"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("syslog_aggregator") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nats"]["user"] = SecureRandom.hex
          @deployment["properties"]["nats"]["password"] = SecureRandom.hex
          @deployment["properties"]["nats"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("nats") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["ccdb_ng"]["address"] = @deployment["jobs"].select{|job| job["name"] == "ccdb" }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["ccdb_ng"]["roles"][0]["name"] = SecureRandom.hex
          @deployment["properties"]["ccdb_ng"]["roles"][0]["password"] = SecureRandom.hex
          @deployment["properties"]["uaadb"]["address"] = @deployment["jobs"].select{|job| job["name"] == "uaadb" }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["uaadb"]["roles"][0]["name"] = SecureRandom.hex
          @deployment["properties"]["uaadb"]["roles"][0]["password"] = SecureRandom.hex
          @deployment["properties"]["router"]["status"]["user"] = SecureRandom.hex
          @deployment["properties"]["router"]["status"]["password"] = SecureRandom.hex
        end
      elsif page == "infrastructure"

      end

      if @is_infrastructure
        File.open(File.expand_path("../../config/infrastructure.yml", __FILE__), "w+") {|f| f.write(@deployment.to_yaml)}
      else
        @deployment_obj.save(@deployment)
      end
    end

    def get_errors(form_data, page, screens)
      table_errors = {}

      screens.each do |key, value|
        table_errors[key] = (generate_form(page, value, form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      end

      table_errors
    end


    private

    def validate_type(value, type)
      error = ''
      if value.kind_of?(Array)
        type = type.gsub 'array_' ''
        value.each {|v|
          error = Validations.validate_field(v, type)
          if error != ''
            return error
          end
        }
      else
        error = Validations.validate_field(value, type)
      end
      error
    end

    def validate_value(field_id, form_data)
      error =''

      unless form_data == {}
        value = form_data[field_id]
        if field_id == 'cloud:Networks:static'
          static_ip_needed = @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}

          static = form_data["cloud:Networks:static"].split(';')
          reserved = form_data["cloud:Networks:reserved"].split(';')

          static_ips = 0
          static.each {|st|
            if st.include?('-')
              low = IPAddr.new(st.split('-')[0].strip).to_i
              high = IPAddr.new(st.split('-')[1].strip).to_i
              for j in low..high do
                if ip_in_range?(form_data['cloud:Networks:range'], j)
                  if ip_not_reserved?(reserved, j)
                    static_ips += 1
                  end
                end
              end
            else
              ip = IPAddr.new(st).to_i
              if ip_in_range?(form_data['cloud:Networks:range'], ip)
                if ip_not_reserved?(reserved, ip)
                  static_ips += 1
                end
              end
            end
          }
          if static_ips < static_ip_needed
            error = "Not enough static IPs! provided: #{static_ips} needed: #{static_ip_needed}"
          end
        elsif field_id == 'cloud:Networks:range'
          range = NetAddr::CIDR.create(form_data['cloud:Networks:range'])
          ip_needed = @deployment["jobs"].inject(0){|sum, job| sum += job["instances"].to_i}
          if ip_needed > range.enumerate.size
            error = "Range is too small"
          end
        end
      end

      error
    end

    def get_local_value(form, screen, field)
      if field["yml_key"]
        get_yml_value(@deployment, form, screen, field)
      elsif field["name"] == "dynamic_ip_range"
        helper = NetworkHelper.new(cloud_manifest: @deployment)
        return helper.get_dynamic_ip_range
      elsif field["name"] == "subnet_mask"
        helper = NetworkHelper.new(cloud_manifest: @deployment)
        return helper.get_subnet_mask
      else
        return ""
      end
    end

    def get_live_value(form, screen, field)
      if @deployment_live
        if field["yml_key"]
          get_yml_value(@deployment_live, form, screen, field)
        elsif field["name"] == "dynamic_ip_range"
          helper = NetworkHelper.new(cloud_manifest: @deployment)
          return helper.get_dynamic_ip_range
        elsif field["name"] == "subnet_mask"
          helper = NetworkHelper.new(cloud_manifest: @deployment)
          return helper.get_subnet_mask
        else
          return ""
        end
      else
        return ""
      end
    end

    def get_yml_value(yml, form, screen, field)
      value = ""
      if field["yml_key"].kind_of?(Array)
        value = eval("yml" + field["yml_key"][0])
      else
        value = eval("yml" + field["yml_key"])
      end

      value
    end

    def get_yaml_key(id)
      keys = id.split ":"
      expr = "@forms[\"" + keys[0] + "\"].select{|cl| cl[\"screen\"] == \"" + keys[1] + "\"}.first[\"fields\"].select{|field| field[\"name\"] == \"" + keys[2] + "\"}.first[\"yml_key\"]"
      eval(expr)
    end

    def set_ips(form_data)

      needed_ips = @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}

      ips = []
      NetworkHelper.get_ip_range(@deployment["networks"][0]["subnets"][0]["static"][0].split("-")[0], @deployment["networks"][0]["subnets"][0]["static"][0].split("-")[1], true).first(needed_ips).each do |ip|
        unless ip_taken?(ip)
          ips << ip
        end
      end

      helper = NetworkHelper.new(form_data: form_data)
      @deployment["networks"][0]["subnets"][0]["reserved"] = helper.get_reserved_ip_range
      @deployment["networks"][0]["subnets"][0]["range"] = helper.get_subnet

      @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.each {|job_with_ip|
        if job_with_ip["networks"][0]["static_ips"].nil?
          job_with_ip["networks"][0]["static_ips"] = []
        end
        initial_ips = job_with_ip["networks"][0]["static_ips"].size
        instances = job_with_ip["instances"].to_i
        if instances > initial_ips
          for i in (initial_ips..instances-1) do
            ip = ips.first
            job_with_ip["networks"][0]["static_ips"][i] = ip
            ips.delete_at(ips.index(ip))
          end
        elsif instances < initial_ips
          (initial_ips-1).downto(instances) {|i|
            job_with_ip["networks"][0]["static_ips"].delete_at(i)
          }
        end
      }
    end

    def ip_in_range?(range, ip)
      cidr = NetAddr::CIDR.create(range)
      cidr.contains?(ip)
    end

    def ip_not_reserved?(reserved, ip)
      reserved.each {|res|
        if res.include?('-')
          low = IPAddr.new(res.split('-')[0].strip).to_i
          high = IPAddr.new(res.split('-')[1].strip).to_i
          if (low..high)===ip
            return false
          end
        else
          if IPAddr.new(res).to_i == ip
            return false
          end
        end
      }
      true
    end

    def ip_taken?(ip)
       @deployment["jobs"].map{|job| job["networks"][0]["static_ips"]}.flatten.include?(ip)
    end

    def configure_service_gateways(form_data)
      gateways = []
      gateways << "mysql_gateway" if @deployment["jobs"].select{|job| job["name"] == "mysql_node"}.first["instances"].to_i > 0
      gateways << "mongodb_gateway" if @deployment["jobs"].select{|job| job["name"] == "mongodb_node"}.first["instances"].to_i > 0
      gateways << "redis_gateway" if @deployment["jobs"].select{|job| job["name"] == "redis_node"}.first["instances"].to_i > 0
      gateways << "postgresql_gateway" if @deployment["jobs"].select{|job| job["name"] == "postgresql_node"}.first["instances"].to_i > 0
      gateways << "rabbit_gateway" if @deployment["jobs"].select{|job| job["name"] == "rabbit_node"}.first["instances"].to_i > 0
      gateways << "uhurufs_gateway" if @deployment["jobs"].select{|job| job["name"] == "uhurufs_node"}.first["instances"].to_i > 0
      gateways << "mssql_gateway" if @deployment["jobs"].select{|job| job["name"] == "mssql_node"}.first["instances"].to_i > 0
      @deployment["jobs"].select{|job| job["name"] == "service_gateways"}.first["templates"] = gateways
    end

    def self.get_cloud_status(cloud_name)
      if !File.exist?(File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__))
        return "Not Configured"
      else
        deployment = Uhuru::Ucc::Deployment.new(cloud_name)
        return deployment.get_status["state"]
      end
    end

  end
end

