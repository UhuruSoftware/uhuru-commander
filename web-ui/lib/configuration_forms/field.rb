require 'net/smtp'
require 'openssl'

module Uhuru::BoshCommander
  class Field

    TYPE_IP = 'ip'
    TYPE_STRING = 'string'
    TYPE_TEXT = 'text'
    TYPE_PASSWORD = 'password'
    TYPE_IP_RANGE = 'ip_range'
    TYPE_NUMERIC = 'numeric'
    TYPE_SEPARATOR = 'separator'
    TYPE_BOOLEAN = 'boolean'
    TYPE_PRODUCT_KEY = 'product_key'
    TYPE_LIST = 'list'
    TYPE_CSV = 'csv'
    TYPE_IP_LIST = 'ip_list'

    TYPE_TO_HTML_TYPE_MAP = {
        'separator' => 'separator',
        'numeric' => 'text',
        'ip' => 'text',
        'ip_range' => 'text',
        'string' => 'text',
        'csv' => 'text',
        'ip_list' => 'text',
        'product_key' => 'text',
        'text' => 'textarea',
        'boolean' => 'checkbox',
        'list' => 'select',
        'password' => 'password'
    }

    attr_accessor :name
    attr_accessor :error

    def initialize(name, screen, form)
      @screen = screen
      @form = form
      @name = name
      @error = ''

      if get_data_type != TYPE_SEPARATOR && get_field_config["yml_key"] == nil
        raise "yml_key not found for field #{html_form_id}"
      end
    end

    def get_field_config
      fields = @screen.get_screen_config['fields'].select do |field|
        field['name'] == @name
      end

      unless fields.size == 1
        raise "Invalid results when looking for field '#{@name}'"
      end

      fields[0]
    end

    def get_label
      get_field_config['label']
    end

    def get_description
      get_field_config['description']
    end

    def get_data_type
      get_field_config['type']
    end

    def get_html_type
      TYPE_TO_HTML_TYPE_MAP[get_data_type]
    end

    def get_css_class
      live_value = get_value GenericForm::VALUE_TYPE_LIVE

      if @form.get_data(GenericForm::VALUE_TYPE_VOLATILE) == nil
        value = get_value GenericForm::VALUE_TYPE_SAVED
      else
        value = get_value GenericForm::VALUE_TYPE_VOLATILE
      end

      changed = live_value != value

      ['config_field', get_data_type, get_html_type, @form.name, @screen.name, @name, changed ? 'changed' : '', @error == '' ? '' : 'error'].join(' ').strip
    end

    def get_list_items
      unless get_data_type == TYPE_LIST
        raise "List items not available for type '#{get_data_type}"
      end
      get_field_config['items']
    end

    def generate_volatile_data!
      value = get_value GenericForm::VALUE_TYPE_FORM

      if get_data_type == TYPE_SEPARATOR
        return
      end

      exotic_value = generate_exotic_value(value)
      if exotic_value != nil
        value = exotic_value
      end

      yml_keys = get_field_config["yml_key"]

      unless yml_keys.is_a? Array
        yml_keys = [yml_keys]
      end

      yml_keys.each do |key|
        eval('@form.volatile_data' + key + ' = value')
      end
    end

    def get_value(value_type)
      data = @form.get_data(value_type)
      if data == nil
        return nil
      end

      if get_data_type == TYPE_SEPARATOR
        return nil
      end

      result = nil

      if value_type == GenericForm::VALUE_TYPE_LIVE || value_type == GenericForm::VALUE_TYPE_SAVED || value_type == GenericForm::VALUE_TYPE_VOLATILE
        begin
          if get_field_config["yml_key"].kind_of?(Array)
            value = eval("data" + get_field_config["yml_key"][0])
          else
            value = eval("data" + get_field_config["yml_key"])
          end
        rescue => e
          $logger.error("Error evaluating field '#{html_form_id}' - #{e.message}: #{e.backtrace}")
          raise "Error evaluating field '#{html_form_id}'"
        end
        exotic_value = get_exotic_value(value, value_type)
        result = exotic_value != nil ? exotic_value : value
      elsif value_type == GenericForm::VALUE_TYPE_FORM
        value = data[html_form_id]
        if get_data_type == TYPE_BOOLEAN
          value = value == nil ? false : true
        elsif get_data_type == TYPE_NUMERIC
          value = value.to_i
        end
        result = value
      else
        raise "Unknown value type '#{value_type}'"
      end

      result = '' if result == nil
      result
    end

    def validate?(value_type)
      @error = ''
      @error = validate_data_type(value_type)

      if @error == ''
        @error = validate_value(value_type)
      end

      (@error == '')
    end

    def html_form_id
      "#{@form.name}:#{@screen.name}:#{@name}"
    end

    def help(use_visibility_link)
      help_item = [get_field_config['label'], get_field_config['description']]
      if use_visibility_link
        visibility_link = html_form_id
        help_item << visibility_link
      end
      help_item
    end

    private

    def validate_data_type(value_type)
      type = get_data_type
      value = get_value(value_type)

      begin
        error = ''
        case type
          when "ip"
            unless value =~ IPHelper::IP_REGEX
              error = "Invalid IP address"
            end
          when "ip_range"
            unless IPHelper.is_valid_string?(value)
              error = "Invalid IP address range"
            end
          when "numeric"
            unless /^\d*\.{0,1}\d*$/.match(value.to_s)
              error = "Invalid number"
            end
          when "netmask"
            unless IPAddress.valid_ipv4_netmask?(value)
              error = "Invalid netmask"
            end
          when "string"
            unless value.size < 256
              error = "The length of this field exceeds 255 characters"
            end
          when "text"
            error = ''
          when "product_key"
            unless /^([a-zA-Z0-9]{5})-([a-zA-Z0-9]{5})-([a-zA-Z0-9]{5})-([a-zA-Z0-9]{5})-([a-zA-Z0-9]{5})$/.match(value)
              error = "Invalid product key"
            end
          when "boolean"
            unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
              error = "Invalid boolean value"
            end
          when "list"
            if value == nil || value == ""
              error = "Empty box!"
            end
          when "csv"
            error = ''
          when "ip_list"
            ips = value.gsub(/,/, ';').split(';').map(&:strip).reject(&:empty?)
            invalid_ips = ips.any? do |ip|
              !(ip =~ IPHelper::IP_REGEX)
            end

            if ips.size == 0 || invalid_ips
              error = "Invalid IP list"
            end
        end
        error
      rescue Exception => e
        $logger.error "Error validating field #{html_form_id} - #{e.to_s}: #{e.backtrace}"
        return "Server error - invalid field"
      end
    end

    def validate_value(value_type)
      if value_type == GenericForm::VALUE_TYPE_FORM
        return ''
      end

      error = ''
      value = get_value value_type
      deployment = @form.get_data value_type

      if @form.name == 'cloud'
        if @screen.name == 'Network'
          if @name == 'static_ip_range'
            static_ip_needed = deployment["jobs"].select{|job| job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}
            static_ips_provided = IPHelper.ip_count_in_range(value)
            if static_ips_provided < static_ip_needed
              error = "Not enough static IPs! provided: #{static_ips_provided} needed: #{static_ip_needed}"
            end
          elsif @name == 'dynamic_ip_range'
            dynamic_ip_needed = deployment["jobs"].select{|job| !job["networks"][0].has_key?("static_ips")}.inject(0){|sum, job| sum += job["instances"].to_i}
            dynamic_ips_provided = IPHelper.ip_count_in_range(value)
            if dynamic_ips_provided < dynamic_ip_needed
              error = "Not enough dynamic IPs! provided: #{dynamic_ips_provided} needed: #{dynamic_ip_needed}"
            end
          end
        elsif @screen.name == 'Properties'
          if @name == 'email_server'
            email_server =  @screen.fields.find {|field| field.name == 'email_server' }.get_value(value_type)
            email_port = @screen.fields.find {|field| field.name == 'email_server_port' }.get_value(value_type)
            email_server_enable_tls = @screen.fields.find {|field| field.name == 'email_server_enable_tls' }.get_value(value_type)
            email_server_user = @screen.fields.find {|field| field.name == 'email_server_user' }.get_value(value_type)
            email_server_secret = @screen.fields.find {|field| field.name == 'email_server_secret' }.get_value(value_type)
            email_server_auth_method = @screen.fields.find {|field| field.name == 'email_server_auth_method' }.get_value(value_type)
            domain = @screen.fields.find {|field| field.name == 'domain' }.get_value(value_type)
            admin_email = @screen.fields.find {|field| field.name == 'admin_email' }.get_value(value_type)

            client = Net::SMTP.new( email_server,email_port)

            if (email_server_enable_tls)
              context =   Net::SMTP.default_ssl_context
              context.verify_mode = OpenSSL::SSL::VERIFY_NONE
              client.enable_starttls(context)
            end
            begin
              msg = "Test email for #{domain} deployment"
              client.open_timeout = 10
                client.start(
                  "localhost",
                  email_server_user,
                  email_server_secret,
                  eval(email_server_auth_method)) do
                client.send_message msg, admin_email, admin_email

                end
            rescue Exception => e
              error = "Cannot connect to email server, please verify settings"
            end

          end
        end
      elsif @form.name == 'infrastructure'
        if @screen.name == 'CPI'
          if @name == 'vcenter_template_folder'
            vcenter = @screen.fields.find {|field| field.name == 'vcenter' }
            vcenter_user = @screen.fields.find {|field| field.name == 'vcenter_user' }
            vcenter_password = @screen.fields.find {|field| field.name == 'vcenter_password' }
            vcenter_datacenter = @screen.fields.find {|field| field.name == 'vcenter_datacenter' }
            vcenter_clusters = @screen.fields.find {|field| field.name == 'vcenter_clusters' }
            vcenter_datastore = @screen.fields.find {|field| field.name == 'vcenter_datastore' }
            vcenter_vm_folder = @screen.fields.find {|field| field.name == 'vcenter_vm_folder' }

            address = vcenter.get_value(value_type)
            user = vcenter_user.get_value(value_type)
            password = vcenter_password.get_value(value_type)
            datacenter = vcenter_datacenter.get_value(value_type)
            cluster = vcenter_clusters.get_value(value_type)
            datastore = vcenter_datastore.get_value(value_type)
            vm_folder = vcenter_vm_folder.get_value(value_type)
            template_folder = value

            vim = nil
            thr = Thread.new do
              begin
                vim = RbVmomi::VIM.connect host: address, user: user, password: password, insecure: true
              rescue Exception => e
                if e.message.include? 'incorrect user name or password'
                  vcenter_user.error = "User may be incorrect"
                  vcenter_password.error = "Password may be incorrect"
                  error = 'Please rectify incorrect settings'
                else
                  vcenter.error = "Could not connect to '#{address}'"
                  error = 'Please rectify incorrect settings'
                end
              end
            end

            $config[:bosh_commander][:check_infrastructure_timeout].times do
              break if vim
              sleep 1
            end

            unless thr.status == false
              Thread.kill(thr)
              vcenter.error = "Timed out while connecting to '#{address}'"
              error = 'Please rectify incorrect settings'
            end

            if vim
              root_folder = vim.serviceInstance.content.rootFolder
              dc = root_folder.childEntity.grep(RbVmomi::VIM::Datacenter).find { |x| x.name == datacenter }
              if dc == nil
                vcenter_datacenter.error = "Datacenter '#{datacenter}' not found."
                error = 'Please rectify incorrect settings'
              else
                cl = dc.hostFolder.children.find { |clus| clus.name == cluster }
                if cl == nil
                  vcenter_clusters.error = "Cluster '#{cluster}' not found."
                  error = 'Please rectify incorrect settings'
                else
                  datastores = cl.datastore.find_all { |ds| !!(ds.name =~ Regexp.new(datastore)) }

                  if datastores == nil || datastores.size == 0
                    vcenter_datastore.error = "Could not find any datastores matching '#{ datastore }'."
                    error = 'Please rectify incorrect settings'
                  end
                end

                dc_vmf = dc.vmFolder.children.find{ |x| x.name ==  vm_folder}

                if dc_vmf == nil
                  vcenter_vm_folder.error = "Could not find a folder for VMs named '#{ vm_folder }' in datacenter '#{ datacenter }'."
                  error = 'Please rectify incorrect settings'
                end

                dc_tf = dc.vmFolder.children.find{ |x| x.name ==  template_folder}

                if dc_tf == nil
                  error = "Could not find a folder for templates named '#{ template_folder }' in datacenter '#{ datacenter }'."
                end
              end
            end
          end
        end
      end

      error
    end

    def get_exotic_value(value, value_type)
      def handle_exotic_type(value)
        data_type = get_data_type
        result = nil

        if data_type == TYPE_CSV || data_type == TYPE_IP_LIST
          result = value.join(';')
        elsif data_type == TYPE_IP_RANGE
          ip_ranges = value.map do |range|
            range.split('-').map(&:strip).reject(&:empty?)
          end
          result = IPHelper.to_string ip_ranges
        end

        result
      end

      result = nil
      begin
        if @form.name == 'cloud'
          if @screen.name == 'Network'
            if @name == 'dynamic_ip_range'
              deployment = @form.get_data value_type

              range = deployment["networks"][0]["subnets"][0]["range"]
              gateway = deployment["networks"][0]["subnets"][0]["gateway"]
              static_ips = deployment["networks"][0]["subnets"][0]["static"]

              if gateway == nil || gateway.strip == ''
                gateway = '0.0.0.0'
              end

              gateway.strip!
              range = [IPHelper.get_subnet_limits(range)]
              range = IPHelper.subtract_range(range, [gateway, gateway])

              static_ips.each do |static_range|
                range = IPHelper.subtract_range(range, static_range.split('-').map(&:strip).reject(&:empty?))
              end

              value.each do |reserved_range|
                range = IPHelper.subtract_range(range, reserved_range.split('-').map(&:strip).reject(&:empty?))
              end

              result = IPHelper.to_string range
            elsif @name == 'subnet_mask'
              result = IPHelper.get_subnet_netmask(value)
            end
          end
        end

        if result == nil
          result = handle_exotic_type(value)
        end
      rescue => e
        $logger.warn "Could not generate exotic value for '#{html_form_id}' - #{e.message} : #{e.backtrace}"
        result = ''
      end

      result
    end

    def generate_exotic_value(value)
      def handle_exotic_type(value)
        data_type = get_data_type
        result = nil

        if data_type == TYPE_CSV || data_type == TYPE_IP_LIST
          result = value.gsub(/,/, ';').split(';').map(&:strip).reject(&:empty?)
        elsif data_type == TYPE_IP_RANGE
          result = IPHelper.from_string(value).map do |range|
            "#{range[0]}-#{range[1]}"
          end
        end

        result
      end

      result = nil
      if @form.name == 'cloud'
        if @screen.name == 'Network'
          if @name == 'dynamic_ip_range'
            form_data = @form.get_data GenericForm::VALUE_TYPE_FORM
            gateway = form_data['cloud:Network:gateway']
            subnet_short = IPHelper.get_subnet_short(form_data['cloud:Network:subnet_mask'])
            static_ips = IPHelper.from_string(form_data['cloud:Network:static_ip_range'])
            dynamic_ips = IPHelper.from_string(form_data['cloud:Network:dynamic_ip_range'])
            result_range = [IPHelper.get_subnet_limits("#{gateway}/#{subnet_short}")]
            result_range = IPHelper.subtract_range(result_range, [gateway, gateway])
            static_ips.each do |static_range|
              result_range = IPHelper.subtract_range(result_range, static_range)
            end
            dynamic_ips.each do |dynamic_range|
              result_range = IPHelper.subtract_range(result_range, dynamic_range)
            end
            result = result_range.map do |range|
              "#{range[0]}-#{range[1]}"
            end
          elsif @name == 'subnet_mask'
            form_data = @form.get_data GenericForm::VALUE_TYPE_FORM
            subnet_short = IPHelper.get_subnet_short(value)
            range = IPHelper.get_subnet_limits("#{form_data['cloud:Network:gateway']}/#{subnet_short}")
            range = IPHelper.ip_to_string(IPHelper.ip_to_int(range[0]) - 1)
            result = "#{range}/#{subnet_short}"
          end
        elsif @screen.name == 'Properties'
          if @name == 'domain'
            result = value.to_s.downcase
          end
        end
      end

      if result == nil
        result = handle_exotic_type(value)
      end

      result
    end

  end
end
