module Uhuru::BoshCommander
  class WordpressForm < GenericForm

    attr_accessor :deployment

    def self.product_name
      return "wordpress"
    end

    def product_name
      return "wordpress"
    end

    def generate_volatile_data!
      super

      auto_complete_manifest!
    end

    def auto_complete_manifest!
      volatile_manifest = get_data VALUE_TYPE_VOLATILE

      #**************************************************************
      # Set resource pool sizes based on job instances
      #**************************************************************

      volatile_manifest["resource_pools"].each {|pool|
        pool["size"] = volatile_manifest["jobs"].select{ |job| job["resource_pool"] == pool["name"]}.inject(0){|sum, job| sum += job["instances"].to_i}
      }

      #**************************************************************
      # Assign static IP addresses to jobs
      #**************************************************************

      $logger.debug("Starting to assign Static IPs for deployment #{@deployment.deployment_name}")

      jobs_with_static_ips = volatile_manifest["jobs"].select do |job|
        job["networks"][0].has_key?("static_ips")
      end

      $logger.debug("These are all the jobs with a static IP: #{jobs_with_static_ips.map {|job| job['name'] }.inspect}")

      needed_ips = jobs_with_static_ips.inject(0) do |sum, job|
        sum += job["instances"].to_i
      end

      $logger.debug("There are #{needed_ips} required static IPs")

      static_ips = @screens.find {|screen| screen.name == 'Network' }.fields.find{|field| field.name=='static_ip_range'}.get_value(VALUE_TYPE_VOLATILE)
      static_ips = IPHelper.from_string static_ips

      possible_static_ips = IPHelper.get_ips_from_range(static_ips, needed_ips).select do |ip|
        ip_used = volatile_manifest["jobs"].any? do |job|
          job_static_ips = job["networks"][0]["static_ips"]
          job_static_ips != nil && job_static_ips.include?(ip)
        end

        !ip_used
      end

      $logger.debug("This is the pool of static IPs we can use: #{possible_static_ips}")

      jobs_with_static_ips.each do |job_with_ip|
        job_with_ip["networks"][0]["static_ips"] ||= []

        assigned_ips = job_with_ip["networks"][0]["static_ips"]

        assigned_instances = assigned_ips.size
        needed_instances = job_with_ip["instances"].to_i

        assigned_ips.each_with_index do |static_ip, index|
          if static_ip.to_s.strip == '' || !IPHelper.ip_in_range?(static_ips, static_ip)
            ip = possible_static_ips.shift
            $logger.debug("Replacing static IP #{assigned_ips[index]} with #{ip} for #{job_with_ip['name']}")
            assigned_ips[index] = ip
          end
        end

        if needed_instances > assigned_instances
          (assigned_instances..needed_instances-1).each do |index|
            ip = possible_static_ips.shift
            $logger.debug("Assigning static IP #{ip} to #{job_with_ip['name']}")
            assigned_ips[index] = ip
          end
        elsif needed_instances < assigned_instances
          $logger.debug("Removing #{assigned_instances - needed_instances} static IPs from #{job_with_ip['name']}")
          assigned_ips.slice!(needed_instances, assigned_instances - needed_instances)
        end
      end

      #**************************************************************
      # Set special properties
      #**************************************************************

      wp_ips = []
      volatile_manifest["jobs"].select{|j| j["name"] == "wordpress"}.first["networks"][0]["static_ips"].each do |ip|
        wp_ips << ip
      end
      volatile_manifest["properties"]["wordpress"]["servers"] = wp_ips
      volatile_manifest["properties"]["mysql"]["address"] = volatile_manifest["jobs"].select{|j| j["name"] == "mysql"}.first["networks"][0]["static_ips"][0]

    end

    def self.from_imported_data(cloud_name, imported_data)
      unless (defined? Thread.current.request_id) && (Thread.current.request_id != nil)
        raise "This method has to be called using a 'Commander BOSH Runner'"
      end

      saved_data = imported_data

      WordpressForm.new(saved_data, nil, Deployment.new(cloud_name, product_name))
    end

    def self.from_cloud_name(cloud_name, form_data)
      unless (defined? Thread.current.request_id) && (Thread.current.request_id != nil)
        raise "This method has to be called using a 'Commander BOSH Runner'"
      end

      deployment_yml = File.join($config[:deployments_dir], product_name, cloud_name, "#{cloud_name}.yml")

      saved_data = nil
      if File.exists? deployment_yml
        saved_data = YAML.load_file(deployment_yml)
      end

      WordpressForm.new(saved_data, form_data, Deployment.new(cloud_name, product_name))
    end

    private

    def initialize(saved_data, form_data, deployment)
      @deployment = deployment
      live_data = @deployment.get_manifest
      forms_file = File.join(File.expand_path("../../config/forms.yml", __FILE__))
      @form = File.open(forms_file) { |file| YAML.load(file)}
      super(product_name, saved_data, form_data, live_data)
    end
  end
end
