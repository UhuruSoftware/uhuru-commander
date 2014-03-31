require 'net/smtp'
require 'openssl'

module Uhuru::BoshCommander
  # Class that manages a set of fields in webui forms, and their correspondence in config files
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
    TYPE_STEMCELL_LINUX = 'stemcell_linux'
    TYPE_STEMCELL_WINDOWS = 'stemcell_windows'

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
        'password' => 'password',
        'stemcell_linux' => 'select',
        'stemcell_windows' => 'select'
    }

    attr_accessor :name
    attr_accessor :error

    # Initialization
    # name = field name
    # screen = screen name that the field belongs to
    # form = form name that the field belongs to
    #
    def initialize(name, screen, form)
      @screen = screen
      @form = form
      @name = name
      @error = ''

      if get_data_type != TYPE_SEPARATOR && get_field_config["yml_key"] == nil
        raise "yml_key not found for field #{html_form_id}"
      end
    end

    # Gets the configuration of the field according to name
    #
    def get_field_config
      fields = @screen.get_screen_config['fields'].select do |field|
        field['name'] == @name
      end

      unless fields.size == 1
        raise "Invalid results when looking for field '#{@name}'"
      end

      fields[0]
    end

    # Gets the label of the field
    #
    def get_label
      get_field_config['label']
    end

    # Gets the description of the field
    #
    def get_description
      get_field_config['description']
    end

    # Gets field data type
    #
    def get_data_type
      get_field_config['type']
    end

    # Gets the mapped html type corresponding to forms.yml file type
    #
    def get_html_type
      TYPE_TO_HTML_TYPE_MAP[get_data_type]
    end

    # Gets the css class for the html element corresponding to field
    #
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

    # Gets a list of items (list of fields, list of stemcell) for specific data type
    #
    def get_items
      if get_data_type == TYPE_LIST
        return get_list_items
      elsif get_data_type == TYPE_STEMCELL_LINUX
        return get_linux_stemcells
      elsif get_data_type == TYPE_STEMCELL_WINDOWS
        return get_windows_stemcells
      else
        raise "Items not available for type '#{get_data_type}"
      end
    end

    # Gets the list of deployed linux stemcell with version
    #
    def get_linux_stemcells
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      current_product = products[@form.product_name]
      stemcells = {}
      current_product.versions[@form.product_version.to_s].dependencies.each do |dependency|
        products_dependency = products[dependency["dependency"]]
        products_dependency_name = products_dependency.name
        products_dependency.local_versions.each do |version|
          first_version = version[0]
          if products_dependency.type == Uhuru::BoshCommander::Versioning::Product::TYPE_STEMCELL
            unless products_dependency_name.downcase.include? "windows"
              if dependency["version"].include? first_version
                stemcells["#{products_dependency.label} v. #{first_version}"] = "name:#{products_dependency_name},version:#{first_version}"
              end
            end
          end
        end
      end
      stemcells
    end

    # Gets the list of deployed windows stemcell with version
    #
    def get_windows_stemcells
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      current_product = products[@form.product_name]
      stemcells = {}
      current_product.versions[@form.product_version.to_s].dependencies.each do |dependency|
        products_dependency = products[dependency["dependency"]]
        products_dependency_name = products_dependency.name
        products_dependency.local_versions.each do |version|
          first_version = version[0]
          if products_dependency.type == Uhuru::BoshCommander::Versioning::Product::TYPE_STEMCELL
            if products_dependency_name.downcase.include? "windows"
              if dependency["version"].include? first_version
                stemcells["#{products_dependency.label} v. #{first_version}"] = "name:#{products_dependency_name},version:#{first_version}"
              end
            end
          end
        end
      end
      stemcells
    end

    # Gets the configuration of 'items' field
    #
    def get_list_items
      get_field_config['items']
    end

    # Generates volatile data for field and verify structure to be conform with config file
    #
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
        begin
          eval('@form.volatile_data' + key + ' = value')
        rescue => ex
          $logger.error("Failed to evaluate key '#{key}' for generating volatile data: #{ex.inspect}")
          raise ex
        end
      end
    end

    # Gets filed value from html form
    # value_type = type of the value field
    #
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
          field_config = get_field_config["yml_key"]
          if field_config.kind_of?(Array)
            value = eval("data" + field_config[0])
          else
            value = eval("data" + field_config)
          end
        rescue => ex
          $logger.error("Error evaluating field '#{html_form_id}' - #{ex.message}: #{ex.backtrace}")
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

      if result.is_a? String
        result.strip!
      end

      result
    end

    # Validate field value and displays error message if any
    # value_type = type of the field value
    #
    def validate?(value_type)
      @error = ''
      @error = validate_data_type(value_type)

      if @error == ''
        @error = validate_value(value_type)
      end
      (@error == '')
    end

    # Gets the html form id of the field
    #
    def html_form_id
      "#{@form.name}:#{@screen.name}:#{@name}"
    end

    # Loads help info for the field from config file
    # use_visibility_link = help status if it's visible or not on the form
    #
    def help(use_visibility_link)
      help_item = [get_field_config['label'], get_field_config['description']]
      if use_visibility_link
        visibility_link = html_form_id
        help_item << visibility_link
      end
      help_item
    end

    private

    # Validates data value with REGEX conform with their type
    # value_type = type of the value to be validated
    #
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
          when "password"
            error = value.include?('|') ? "Passwords cannot contain the pipe '|' character." : ''
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
      rescue Exception => ex
        $logger.error "Error validating field #{html_form_id} - #{ex.to_s}: #{ex.backtrace}"
        return "Server error - invalid field"
      end
    end

    # Validate field value in real time for infrastructure form and returns an error message
    # For other forms where no validation is required just returns the value
    # value_type = type of the field value
    #
    def validate_value(value_type)
      if value_type == GenericForm::VALUE_TYPE_FORM
        return ''
      end

      error = ''
      value = get_value value_type

      if @form.name == 'infrastructure'
        if @screen.name == 'CPI'
          if @name == 'vcenter_template_folder'
            # validate existence
            vcenter = find_screen_field('vcenter')
            vcenter_user = find_screen_field('vcenter_user')
            vcenter_password = find_screen_field('vcenter_password')
            vcenter_datacenter = find_screen_field('vcenter_datacenter')
            vcenter_clusters = find_screen_field('vcenter_clusters')
            vcenter_datastore = find_screen_field('vcenter_datastore')
            vcenter_vm_folder = find_screen_field('vcenter_vm_folder')

            address = vcenter.get_value(value_type)
            user = vcenter_user.get_value(value_type)
            password = vcenter_password.get_value(value_type)
            datacenter = vcenter_datacenter.get_value(value_type)
            cluster = vcenter_clusters.get_value(value_type)
            datastore = vcenter_datastore.get_value(value_type)
            vm_folder = vcenter_vm_folder.get_value(value_type)
            template_folder = value

            # validate vcenter credentials
            vim = nil
            thr = Thread.new do
              begin
                vim = RbVmomi::VIM.connect host: address, user: user, password: password, insecure: true
              rescue Exception => ex
                if ex.message.include? 'incorrect user name or password'
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

            # validate datacenter settings
            if vim
              root_folder = vim.serviceInstance.content.rootFolder
              dc = root_folder.childEntity.grep(RbVmomi::VIM::Datacenter).find { |folder| folder.name == datacenter }
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

                root_vm_folder = dc.vmFolder
                dc_vmf = root_vm_folder.children.find{ |folder| folder.name ==  vm_folder}

                if dc_vmf == nil
                  vcenter_vm_folder.error = "Could not find a folder for VMs named '#{ vm_folder }' in datacenter '#{ datacenter }'."
                  error = 'Please rectify incorrect settings'
                end

                dc_tf = root_vm_folder.children.find{ |folder| folder.name ==  template_folder}

                if dc_tf == nil
                  error = "Could not find a folder for templates named '#{ template_folder }' in datacenter '#{ datacenter }'."
                end
              end
            end
          elsif @name == 'nagios_email_server'
            # validate nagios settings
            email_server = find_screen_field('nagios_email_server').get_value(value_type)
            email_from =  find_screen_field('nagios_email_from').get_value(value_type)
            email_port = find_screen_field('nagios_email_server_port').get_value(value_type)
            email_server_enable_tls = find_screen_field('nagios_email_server_enable_tls').get_value(value_type)
            email_server_user = find_screen_field('nagios_email_server_user').get_value(value_type)
            email_server_secret = find_screen_field('nagios_email_server_secret').get_value(value_type)
            email_server_auth_method = find_screen_field('nagios_email_server_auth_method').get_value(value_type)

            #validate email settings
            client = Net::SMTP.new( email_server,email_port)

            if email_server_enable_tls
              context =   Net::SMTP.default_ssl_context
              client.enable_starttls(context)
            end
            begin
              msg = <<END_OF_MESSAGE
 Subject: Test send email for Nagios
 MIME-Version: 1.0
 Content-type: text/html


 Test email for Uhuru Commander Nagios Monitoring

END_OF_MESSAGE
              client.open_timeout = 10
              client.start(
                  "localhost",
                  email_server_user,
                  email_server_secret,
                  email_server_auth_method) do
                client.send_message msg, email_from, $config[:test_email]

              end
            rescue Exception => ex
              error = "Cannot connect to email server, please verify settings - #{ex.message}"
            end

          end
        end
      end

      error
    end

    # This method is called when we want to show values on the form
    #
    def get_exotic_value(value, value_type)
      result = nil
      begin
        if @form.name == 'infrastructure'
           if @screen.name == 'CPI'
             if @name == 'net_interface'

               #we get only ipv4 addresses
               Socket.ip_address_list.delete_if { |intfr| !intfr.ipv4? }.map {|intfr| intfr.ip_address}.each do |ipaddr|
               get_list_items[ipaddr.to_s] = ipaddr
               end
             elsif @name == 'nagios_email_server_auth_method'
               result = value.to_s
             end
           end
        end

        if result == nil
          result = handle_to_get_exotic_type(value)
        end
      rescue => ex
        $logger.warn "Could not generate exotic value for '#{html_form_id}' - #{ex.message} : #{ex.backtrace}"
        result = ''
      end

      result
    end

    # Transforms a exotic value for displaying it on the form
    # value = value to be transformed
    #
    def handle_to_get_exotic_type(value)
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

    # This method is called when we want to save data. This is where we have to manipulate values before we save them.
    # value = field value from web interface
    #
    def generate_exotic_value(value)
      result = nil
      if @form.name == 'infrastructure'
        if @screen.name == 'CPI'
          if @name == 'net_interface'
            #replace ip address in configuration file
            config_file = $config[:configuration_file]
            configuration = YAML.load_file(config_file)
            configuration["bind_address"] = value
            File.open(config_file, "w") {|file| file.write(configuration.to_yaml)}
          elsif @name == 'nagios_email_server_auth_method'
            result = value.to_sym
          end
        end
      end

      if result == nil
        result = handle_to_generate_exotic_type(value)
      end

      result
    end

    # Transforms a exotic value for saving it in config file
    # value = value to be transformed
    #
    def handle_to_generate_exotic_type(value)
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

    # Find a field in the screen by name
    # field_name = name of the field
    #
    def find_screen_field(field_name)
      @screen.fields.find {|field| field.name == field_name }
    end

  end
end
