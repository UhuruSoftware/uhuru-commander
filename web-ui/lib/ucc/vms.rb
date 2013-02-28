module Uhuru::Ucc
  class Vms

    def list(deployment_name)
      director =  Thread.current.current_session[:command].instance_variable_get("@director")

      vms = director.fetch_vm_state(deployment_name)
      sorted = vms.sort do |a, b|
        s = a["job_name"].to_s <=> b["job_name"].to_s
        s = a["index"].to_i <=> b["index"].to_i if s == 0
        s = a["resource_pool"].to_s <=> b["resource_pool"].to_s if s == 0
        s
      end

      sorted
    end
  end
end