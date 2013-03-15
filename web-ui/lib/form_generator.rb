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
    attr_accessor :deployment_obj
    attr_accessor :error_screens


    def self.get_clouds
      clouds = []
      Uhuru::Ucc::Deployment.deployments.each do |cloud_name|
        cloud = {}
        cloud[:name] = cloud_name
        cloud[:status] = get_cloud_status(cloud_name)
        cloud[:services] = get_services(cloud_name)
        cloud[:stacks] = get_stacks(cloud_name)
        clouds << cloud
      end
      clouds
    end

    def initialize(parameters = {})
      @error_screens = {}
      @is_infrastructure = parameters[:is_infrastructure]
      if @is_infrastructure
        director_yml = File.join($config[:bosh][:base_dir], 'jobs','director','config','director.yml.erb')
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
          #puts ex
        end

      end
      @forms = File.open(File.expand_path("../../config/forms.yml", __FILE__)) { |file| YAML.load(file)}
    end

    def help()
      help_items = []

      @forms.each do |form_name, form|
        form.each do |screen|
          screen['fields'].each do |field|
            help_items << [field['label'], field['description'], "#{form_name}:#{screen['screen']}:#{field['name']}"]
          end
        end
      end

      help_items
    end

    def generate_form(form, screen_name, form_data = {} )
      screen = @forms[form].find { |item| item['screen'] == screen_name }

      html_fields = []
      if @is_infrastructure && form_data != {}
        require "vsphere_checker"
        infrastructure_errors = VSphereChecker.check(form_data)
      end

      is_error = false
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
                              when 'password'
                                'password'
                            end

        html_field[:id] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:input_name] = "#{form}:#{screen_name}:#{field['name']}"
        html_field[:name] = field['label']
        html_field[:description] = field['description']
        local_value = form_data.has_key?(html_field[:id]) ? form_data[html_field[:id].to_sym] : get_local_value(form, screen_name, field)
        if (!local_value)
          next
        end
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

        if @is_infrastructure && infrastructure_errors != nil
          if html_field[:error] == '' && infrastructure_errors.has_key?(html_field[:id])
            html_field[:error] = infrastructure_errors[html_field[:id]]
          end
        end

        changed = html_field[:value] != html_field[:value_live]
        #if changed
        #  #save_local_deployment(form_data)
        #end
        has_error = html_field[:error] == '' ? '' : 'error'
        if (has_error == 'error' && !is_error)
          is_error = true
        end
        html_field[:class] = ['config_field', field['type'], html_field[:type], form, screen_name, field['name'], changed ? 'changed' : '', has_error].join(' ').strip

        html_fields << html_field
      end
      if (is_error)
        @error_screens[screen_name] = true
      else
        @error_screens[screen_name] = false
      end
      html_fields
    end

    def get_errors(form_data, page, screens)
      table_errors = {}

      screens.each do |key, value|
        table_errors[key] = (generate_form(page, value, form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      end

      table_errors
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
            next unless form_data[id]
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
        configure_service_gateways(form_data)

        @deployment["resource_pools"].each {|pool|
          pool["size"] = @deployment["jobs"].select{|job| job["resource_pool"] == pool["name"]}.inject(0){|sum, job| sum += job["instances"].to_i}
        }

        set_ips(form_data)

        if !@deployment_live
          @deployment["properties"]["nfs_server"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("debian_nfs_server") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nfs_server"]["network"] = @deployment["networks"][0]["subnets"][0]["range"]
          @deployment["properties"]["syslog_aggregator"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("syslog_aggregator") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nats"]["user"] = SecureRandom.hex
          @deployment["properties"]["nats"]["password"] = SecureRandom.hex
          @deployment["properties"]["nats"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("nats") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["ccdb"]["address"] = @deployment["jobs"].select{|job| job["name"] == "ccdb" }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["ccdb"]["password"] = SecureRandom.hex
          @deployment["properties"]["ccdb"]["roles"][0]["password"] = SecureRandom.hex
          @deployment["properties"]["ccdb"]["dbname"] = SecureRandom.hex
          @deployment["properties"]["ccdb"]["databases"][0]["name"] = @deployment["properties"]["ccdb"]["dbname"]
          @deployment["properties"]["ccdb"]["roles"][0]["password"] = @deployment["properties"]["ccdb"]["password"]
          @deployment["properties"]["cc"]["srv_api_uri"] = "api.#{@deployment['properties']['domain']}"
          @deployment["properties"]["cc"]["password"] = SecureRandom.hex
          @deployment["properties"]["cc"]["token"] = SecureRandom.hex
          @deployment["properties"]["cc"]["staging_upload_user"] = SecureRandom.hex
          @deployment["properties"]["cc"]["staging_upload_password"] = SecureRandom.hex
          @deployment["properties"]["vcap_redis"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("vcap_redis") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["vcap_redis"]["password"] = SecureRandom.hex
          @deployment["properties"]["vcap_redis"]["maxmemory"] = @deployment["resource_pools"].select{|pool| pool["name"] == "medium" }.first["cloud_properties"]["ram"]
          @deployment["properties"]["router"]["status"]["user"] = SecureRandom.hex
          @deployment["properties"]["router"]["status"]["password"] = SecureRandom.hex
          @deployment["properties"]["router"]["redirect_parent_domain_to"] = "www.#{@deployment['properties']['domain']}"
          @deployment["properties"]["dea"]["maxmemory"] = @deployment["resource_pools"].select{|pool| pool["name"] == "deas" }.first["cloud_properties"]["ram"]
          #@deployment["properties"]["hbase_master"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("hbase_master") == true }.first["networks"][0]["static_ips"][0]
          #@deployment["properties"]["hbase_slave"]["addresses"][0] = @deployment["jobs"].select{|job| job["template"].include?("hbase_slave") == true }.first["networks"][0]["static_ips"][0]
          #@deployment["properties"]["opentsdb"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("opentsdb") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["uaa"]["cc"]["token_secret"] = SecureRandom.hex
          @deployment["properties"]["uaa"]["cc"]["client_secret"] = SecureRandom.hex
          @deployment["properties"]["uaa"]["admin"]["client_secret"] = SecureRandom.hex
          @deployment["properties"]["uaa"]["login"]["client_secret"] = SecureRandom.hex
          @deployment["properties"]["uaa"]["clients"]["dashboard"]["secret"] = SecureRandom.hex
          @deployment["properties"]["uaa"]["scim"]["users"][0] = "#{form_data['cloud:Properties:dashboard_username']}|#{form_data['cloud:Properties:dashboard_password']}|#{form_data['cloud:Properties:dashboard_email']}|Dash|Board|openid,dashboard.user"

          #@deployment["properties"]["ccdb_ng"]["roles"][0]["name"] = SecureRandom.hex
          #@deployment["properties"]["ccdb_ng"]["roles"][0]["password"] = SecureRandom.hex
          #@deployment["properties"]["ccdb_ng"]["address"] = @deployment["jobs"].select{|job| job["name"] == "ccdb" }.first["networks"][0]["static_ips"][0]
          #@deployment["properties"]["uaadb"]["address"] = @deployment["jobs"].select{|job| job["name"] == "uaadb" }.first["networks"][0]["static_ips"][0]
          #@deployment["properties"]["uaadb"]["roles"][0]["name"] = SecureRandom.hex
          #@deployment["properties"]["uaadb"]["roles"][0]["password"] = SecureRandom.hex
          #@deployment["properties"]["router"]["status"]["user"] = SecureRandom.hex
          #@deployment["properties"]["router"]["status"]["password"] = SecureRandom.hex
        end
      elsif page == "infrastructure"

      end

      if @is_infrastructure
        File.open(File.expand_path("../../config/infrastructure.yml", __FILE__), "w+") {|f| f.write(@deployment.to_yaml)}
      else
        @deployment_obj.save(@deployment)
      end
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
        if field_id == 'cloud:Network:static_ip_range'
          static_ip_needed = @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}
          static = form_data["cloud:Network:static_ip_range"].split('-')
          static_ips_provided = NetworkHelper.get_ip_range(static[0], static[1], true).count
          if static_ips_provided < static_ip_needed
            error = "Not enough static IPs! provided: #{static_ips_provided} needed: #{static_ip_needed}"
          end
        elsif field_id == 'cloud:Network:dynamic_ip_range'
          dynamic_ip_needed = @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips") == false}.inject(0){|sum, job| sum += job["instances"].to_i}
          dynamic = form_data["cloud:Network:dynamic_ip_range"].split('-')
          dynamic_ips_provided = NetworkHelper.get_ip_range(dynamic[0], dynamic[1], true).count
          if dynamic_ips_provided < dynamic_ip_needed
            error = "Not enough dynamic IPs! provided: #{dynamic_ips_provided} needed: #{dynamic_ip_needed}"
          end
        end
      end
      puts error if error != ""
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
      elsif field["name"] == "dashboard_email"
        return @deployment["properties"]["uaa"]["scim"]["users"][0].split('|')[2]
      elsif field["name"] == "dashboard_username"
        return @deployment["properties"]["uaa"]["scim"]["users"][0].split('|')[0]
      elsif field["name"] == "dashboard_password"
        return @deployment["properties"]["uaa"]["scim"]["users"][0].split('|')[1]
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
      begin
        if field["yml_key"].kind_of?(Array)
          value = eval("yml" + field["yml_key"][0])
        else
          value = eval("yml" + field["yml_key"])
        end

        if value.nil?
          return ""
        else
          return value
        end

      rescue Exception => ex
        #puts "field: #{field}: #{ex} -> #{ex.backtrace}"
        #needed if some resource pools/jobs are missing
        return nil
      end
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
        job_with_ip["networks"][0]["static_ips"] = [] if job_with_ip["networks"][0]["static_ips"].nil?
        initial_ips = job_with_ip["networks"][0]["static_ips"].size
        instances = job_with_ip["instances"].to_i

        job_with_ip["networks"][0]["static_ips"].each_with_index {|static_ip, index|
          unless NetworkHelper.ip_in_range?(form_data["cloud:Network:static_ip_range"].split('-')[0].strip, form_data["cloud:Network:static_ip_range"].split('-')[1].strip, static_ip)
            ip = ips.first
            job_with_ip["networks"][0]["static_ips"][index] = ip
            ips.delete_at(ips.index(ip))
          end
        }

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

      #one job per gateway
      gateways = {
          "mysql_gateway" => "mysql_node",
          "mongodb_gateway" => "mongodb_node",
          "redis_gateway" => "redis_node",
          "postgresql_gateway" => "postgresql_node",
          "rabbit_gateway" => "rabbit_node",
          "uhurufs_gateway" => "uhurufs_node",
          "mssql_gateway" => "mssql_node"
      }
      gateways.each{|key, value|
        if @deployment["jobs"].select{|job| job["name"] == value}.first["instances"].to_i > 0
          @deployment["jobs"].select{|job| job["name"] == key}.first["instances"] = 1
        else
          @deployment["jobs"].select{|job| job["name"] == key}.first["instances"] = 0
        end
      }

      #job collocation

      #gateways = []
      #gateways.each{|key, value|
      #  gateways << key if @deployment["jobs"].select{|job| job["name"] == value}.first["instances"].to_i > 0
      #  }
      #@deployment["jobs"].select{|job| job["name"] == "service_gateways"}.first["templates"] = gateways
    end

    def self.get_cloud_status(cloud_name)
      if !File.exist?(File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__))
        return "Not Configured"
      else
        deployment = Uhuru::Ucc::Deployment.new(cloud_name)
        return deployment.get_status["state"]
      end
    end

    def self.get_services(cloud_name)
      deployment = Uhuru::Ucc::Deployment.new(cloud_name)
      begin
        manifest = deployment.get_manifest
      rescue
      end

      #manifest = File.open(File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__)) { |file| YAML.load(file)}

      services = []
      if manifest
        ["mysql_node", "mssql_node", "uhurufs_node", "rabbit_node", "postgresql_node", "redis_node", "mongodb_node"].each do |node|
          if manifest["jobs"].select{|job| job["name"] == node}.first["instances"] > 0
            services << node
          end
        end
      end
      services
    end

    def self.get_stacks(cloud_name)
      deployment = Uhuru::Ucc::Deployment.new(cloud_name)
      begin
        manifest = deployment.get_manifest
      rescue
      end

      #manifest = File.open(File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__)) { |file| YAML.load(file)}

      stacks = []
      if manifest
        ["dea", "win_dea"].each do |stack|
          if manifest["jobs"].select{|job| job["name"] == stack}.first["instances"] > 0
            stacks << stack
          end
        end
      end
      stacks
    end

  end
end

