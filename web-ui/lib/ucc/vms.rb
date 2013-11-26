module Uhuru::BoshCommander
  # vms class
  class Vms

    # list all vms
    def list(deployment_name)
      director =  Thread.current.current_session[:command].instance_variable_get("@director")

      vms = director.fetch_vm_state(deployment_name)
      sorted = vms.sort do |vm1, vm2|
        sort = vm1["job_name"].to_s <=> vm2["job_name"].to_s
        sort = vm1["index"].to_i <=> vm2["index"].to_i if sort == 0
        sort = vm1["resource_pool"].to_s <=> vm2["resource_pool"].to_s if sort == 0
        sort
      end

      sorted
    end
  end
end