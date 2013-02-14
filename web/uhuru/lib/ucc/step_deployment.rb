module Uhuru::Ucc

  class StepDeploymentGenerator

    def self.generate_step_deployment(cf_deployment_file, out_dir)
      unless cf_deployment_file && File.exist?(cf_deployment_file)
        raise "Cannot find Cloud Foundry deployment YML '#{cf_deployment_file}'."
      end

      unless out_dir && Dir.exist?(out_dir)
        raise "Cannot find output directory '#{out_dir}'."
      end

      cf_deployment = YAML::load(File.open(cf_deployment_file ))

      resource_pools = %w(windows sqlserver tiny small medium large deas)

      yml_resource_pools = cf_deployment['resource_pools'].map do |resource_pool|
        resource_pool['name']
      end


      delta = (resource_pools - yml_resource_pools) + (yml_resource_pools - resource_pools)

      unless delta.size == 0
        raise <<ERROR
The Cloud Foundry YML file contains a different resource pool list than expected.
Delta(+/-): #{delta.join('|')}
Expected:   #{resource_pools.join(',')}
Found:      #{yml_resource_pools.join(',')}
ERROR
      end

      jobs = {
          'windows' => %w(win_dea uhuru_tunnel uhurufs_node),
          'sqlserver' => %w(mssql_node),
          'tiny' => %w(simple_webui mysql_gateway mongodb_gateway redis_gateway rabbit_gateway postgresql_gateway mssql_gateway uhurufs_gateway),
          'small' => %w(debian_nfs_server nats uaadb uaa health_manager),
          'medium' => %w(syslog_aggregator ccdb_postgres vcap_redis cloud_controller stager router mysql_node mongodb_node rabbit_node postgresql_node hbase_master hbase_slave opentsdb collector dashboard),
          'large' => %w(redis_node),
          'deas' => %w(dea),
      }

      yml_jobs = Hash.new

      resource_pools.each do |resource_pool|
        yml_jobs[resource_pool] = []
      end

      cf_deployment['jobs'].each do |job|

        unless yml_jobs[job['resource_pool']]
          raise "Job '#{job['name']}' references invalid resource pool '#{job['resource_pool']}'"
        end

        yml_jobs[job['resource_pool']] << job['name']
      end

      delta = []

      resource_pools.each do |resource_pool|
        delta += (jobs[resource_pool] - yml_jobs[resource_pool]) + (yml_jobs[resource_pool] - jobs[resource_pool])
      end

      unless delta.size == 0
        raise <<ERROR
The Cloud Foundry YML file contains a different job to resource pool assignment list than expected.
Delta(+/-): #{delta.join('|')}
Expected:   #{jobs.inspect}
Found:      #{yml_jobs.inspect}
ERROR
      end


      core_jobs = %w(debian_nfs_server syslog_aggregator nats ccdb_postgres uaadb vcap_redis uaa cloud_controller stager
router health_manager simple_webui mysql_gateway mongodb_gateway redis_gateway rabbit_gateway postgresql_gateway
mssql_gateway uhurufs_gateway hbase_master hbase_slave opentsdb collector dashboard uhuru_tunnel)

      dea_jobs = %w(dea win_dea)

      service_jobs = %w(mysql_node mongodb_node redis_node rabbit_node postgresql_node uhurufs_node mssql_node)


      all_jobs = core_jobs + dea_jobs + service_jobs

      #we must do a deep copy
      cf_deployment_original = deep_copy(cf_deployment)

      # set everything to 0
      cf_deployment['resource_pools'].each do |resource_pool|
        resource_pool['size'] = 0
      end

      cf_deployment['jobs'].each do |job|
        job['instances'] = 0
        job['networks'].each do |net|
          if (net['static_ips'])
            net['static_ips'].clear
          end
        end
      end

      step = 0
      filename = File.basename(cf_deployment_file)

      # add one box at a time

      all_jobs.each do |job|
        resource_pool = jobs.find { |_, list| list.include? job }.first

        yml_pool = cf_deployment['resource_pools'].find { |item| item['name'] == resource_pool }

        yml_job = cf_deployment['jobs'].find { |item| item['name'] == job }
        yml_job_original = cf_deployment_original['jobs'].find { |item| item['name'] == job }

        yml_job['networks'] = yml_job_original['networks']

        for i in 1 .. yml_job_original['instances']
          yml_pool['size'] += 1
          yml_job['instances'] += 1

          file = File.join(out_dir, "step_#{step}_#{filename}")
          File.open(file, "w") {|f| f.write(YAML.dump(cf_deployment))}

          step += 1
        end

      end
    end

    def self.deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end
  end
end



#
#cf_file = ARGV[0]
#out_dir = ARGV[1]
#
#puts "CF file is '#{cf_file}'"
#puts "Output dir is '#{out_dir}'"
#
#Uhuru::StepDeploymentGenerator.generate_step_deployment(cf_file, out_dir)

