require 'rbvmomi'

class VSphereChecker


  def self.check(form_data)
    vim = nil
    if ($config)
      timeout = $config[:bosh_commander][:check_infrastructure_timeout]
    else
      timeout = 20
    end

    errors = {
        "infrastructure:CPI:vcenter" => "",
        "infrastructure:CPI:vcenter_user" => "",
        "infrastructure:CPI:vcenter_password" => "",
        "infrastructure:CPI:vcenter_datacenter" => "",
        "infrastructure:CPI:vcenter_clusters" => "",
        "infrastructure:CPI:vcenter_datastore" => "",
        "infrastructure:CPI:vcenter_vm_folder" => "",
        "infrastructure:CPI:vcenter_template_folder" => ""
    }

    address = form_data["infrastructure:CPI:vcenter"]
    user = form_data["infrastructure:CPI:vcenter_user"]
    password = form_data["infrastructure:CPI:vcenter_password"]
    datacenter = form_data["infrastructure:CPI:vcenter_datacenter"]
    cluster = form_data["infrastructure:CPI:vcenter_clusters"]
    datastore = form_data["infrastructure:CPI:vcenter_datastore"]
    vm_folder = form_data["infrastructure:CPI:vcenter_vm_folder"]
    template_folder = form_data["infrastructure:CPI:vcenter_template_folder"]

    thr = Thread.new {
      begin
        vim = RbVmomi::VIM.connect host: address, user: user, password: password, insecure: true
      rescue Exception => e
        errors["infrastructure:CPI:vcenter"] = "Could not login to '#{address}' using the provided credentials"
      end
    }

    for i in 1 .. timeout
      if vim
         break
      end
      sleep 1
    end

    if (thr.status != false)
      Thread.kill(thr)
      errors["infrastructure:CPI:vcenter"] = "Could not login to '#{address}' using the provided credentials"
    end


    if vim
      rootFolder = vim.serviceInstance.content.rootFolder
      dc = rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).find { |x| x.name == datacenter }

      if dc == nil
        errors["infrastructure:CPI:vcenter_datacenter"] = "Datacenter '#{datacenter}' not found."
      else
        cl = dc.hostFolder.children.find { |clus| clus.name == cluster }

        if cl == nil
          errors["infrastructure:CPI:vcenter_clusters"] = "Cluster '#{cluster}' not found."
        else
          datastores = cl.datastore.find_all { |ds| !!(ds.name =~ Regexp.new(datastore)) }

          if datastores == nil || datastores.size == 0
            errors["infrastructure:CPI:vcenter_datastore"] = "Could not find any datastores matching '#{ datastore }'."
          end
        end

        dc_tf = dc.vmFolder.children.find{ |x| x.name ==  template_folder}

        if dc_tf == nil
          errors["infrastructure:CPI:vcenter_vm_folder"] = "Could not find a folder for templates named '#{ template_folder }' in datacenter '#{ datacenter }'."
        end

        dc_vmf = dc.vmFolder.children.find{ |x| x.name ==  vm_folder}

        if dc_vmf == nil
          errors["infrastructure:CPI:vcenter_template_folder"] = "Could not find a folder for VMs named '#{ vm_folder }' in datacenter '#{ datacenter }'."
        end
      end
    end
    errors
  end
end
