require 'yaml'
require 'validations'
require 'ipaddr'
require 'netaddr'
require 'fileutils'
require 'securerandom'

module Uhuru::BoshCommander
  class FormGenerator
    attr_accessor :deployment

    def self.get_clouds
      clouds = []
      dir = File.expand_path('../../config/clouds/', __FILE__)
      Dir.foreach(dir) do |file|
        next if file == '.' or file == '..'
        obj = File.join(dir, file)
        unless Dir.exist?(obj)
          if File.exist?(obj)
            cloud = {}
            cloud[:name] = file
            cloud[:status] = ""
            if FileUtils.compare_file("../config/clouds/#{file}", "../config/blank.yml")
              cloud[:status] = "Not configured"
            elsif !File.exist?("../config/clouds/live/#{file}")
              cloud[:status] = "Not deployed"
            elsif FileUtils.compare_file("../config/clouds/#{file}", "../config/clouds/live/#{file}")
              cloud[:status] = "Not deployed"
            end
            cloud[:services] = ""
            cloud[:frameworks] = ""
            clouds << cloud
          end
        end
      end

      clouds
    end

    def initialize(deployment_file, forms_file, deployment_live = nil)
      @deployment_manifest = deployment_file
      @deployment = File.open(deployment_file) { |file| YAML.load(file)}
      if deployment_live
        if File.exist?(deployment_live)
          @deployment_live = File.open(deployment_live)  { |file| YAML.load(file)}
        end
      end
      @forms = File.open(forms_file) { |file| YAML.load(file)}
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
      is_ok = true

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

        if get_cloud_status == "Not configured"
          @deployment["properties"]["nfs_server"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("debian_nfs_server") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nfs_server"]["network"] = @deployment["networks"][0]["subnets"][0]["range"]
          @deployment["properties"]["syslog_aggregator"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("syslog_aggregator") == true }.first["networks"][0]["static_ips"][0]
          @deployment["properties"]["nats"]["user"] = SecureRandom.hex
          @deployment["properties"]["nats"]["password"] = SecureRandom.hex
          @deployment["properties"]["nats"]["address"] = @deployment["jobs"].select{|job| job["template"].include?("nats") == true }.first["networks"][0]["static_ips"][0]

        end

      end

      File.open(@deployment_manifest, "w+") {|f| f.write(@deployment.to_yaml)}
      is_ok
    end

    def get_table_errors(form_data)
      table_errors = {}

      table_errors[:networks] = (generate_form("cloud", "Network", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      #table_errors[:compilation] = (generate_form("cloud", "Compilation", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:resource_pools] = (generate_form("cloud", "Resource Pools", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      #table_errors[:update] = (generate_form("cloud", "Update", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:components] = (generate_form("cloud", "Components", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:properties] = (generate_form("cloud", "Properties", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:product_keys] = (generate_form("cloud", "Product Keys", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      table_errors[:user_limits] = (generate_form("cloud", "User Limits", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      #table_errors[:service_plans] = (generate_form("cloud", "Service Plans", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0
      #table_errors[:advanced] = (generate_form("cloud", "Advanced", form_data).select{|networks_field| networks_field[:error] != ''}).size > 0

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
      else
        ""
      end
    end

    def get_live_value(form, screen, field)
      if @deployment_live
        if field["yml_key"]
          get_yml_value(@deployment_live, form, screen, field)
        else
          ""
        end
      else
        ""
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
      ip_pool = form_data["cloud:Network:ip_pool"]
      subnet_mask = form_data["cloud:Network:subnet_mask"]

      needed_ips = @deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}
      ips = []

      ip_range = NetAddr::CIDR.create("#{ip_pool} #{subnet_mask}")

      ips = ip_range.range(0, needed_ips)

      range = "#{ip_range.network}#{ip_range.netmask}"

      puts ips.inspect
      puts range

      @deployment["networks"][0]["subnets"][0]["static"] = ips
      @deployment["networks"][0]["subnets"][0]["range"] = ip_range.to_s

      #static.each {|st|
      #  if st.include?('-')
      #    low = IPAddr.new(st.split('-')[0].strip).to_i
      #    high = IPAddr.new(st.split('-')[1].strip).to_i
      #    for j in low..high do
      #      if ip_in_range?(range, j)
      #        if ip_not_reserved?(reserved, j)
      #          ip = IPAddr.new(j, Socket::AF_INET).to_s
      #          unless ip_taken?(ip)
      #            ips << ip
      #          end
      #        end
      #        if ips.size == needed_ips
      #          break
      #        end
      #      end
      #    end
      #  else
      #    ip = IPAddr.new(st).to_i
      #    if ip_in_range?(range, ip)
      #      if ip_not_reserved?(reserved, ip)
      #        ip = IPAddr.new(j, Socket::AF_INET).to_s
      #        unless ip_taken?(ip)
      #          ips << ip
      #        end
      #      end
      #      if ips.size == needed_ips
      #        break
      #      end
      #    end
      #  end
      #  if ips.size == needed_ips
      #    break
      #  end
      #}
      #
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

    def get_cloud_status
      "Not configured"
    end

  end
end

