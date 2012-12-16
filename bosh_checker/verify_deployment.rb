require 'rbvmomi'
require 'colorize'
require 'trollop'

opts = Trollop::options do
  banner "You have to provide all options described below"
  opt :address, "IP/hostname of your vSphere server", :type => :string, :short => 'h', :required => true
  opt :user, "The username used to login to vSphere", :type => :string, :short => 'u', :required => true
  opt :password, "The password used to login to vSphere", :type => :string, :short => 'p', :required => true
  opt :datacenter, "The name of the datacenter", :type => :string, :short => 'd', :required => true
  opt :cluster, "The name of the cluster", :type => :string, :short => 'c', :required => true
  opt :datastore, "A pattern for the datastores", :type => :string, :short => 's', :required => true
  opt :template_folder, "The template folder", :type => :string, :short => 't', :required => true
  opt :vm_folder, "The VM folder", :type => :string, :short => 'v', :required => true
end

address = opts[:address]
user = opts[:user]
password = opts[:password]
datacenter = opts[:datacenter]
cluster = opts[:cluster]
datastore = opts[:datastore]
template_folder = opts[:template_folder]
vm_folder = opts[:vm_folder]


exit_code = nil

begin
  vim = RbVmomi::VIM.connect host: address, user: user, password: password, insecure: true
  $stdout.puts "Login successful to '#{address}'".green
rescue Exception => e
  $stderr.puts "Could not login to '#{address}' using the provided credentials".red
  exit_code ||= 1
end

rootFolder = vim.serviceInstance.content.rootFolder
dc = rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).find { |x| x.name == datacenter }

if dc == nil
  $stderr.puts "Datacenter '#{datacenter}' not found.".red
  exit_code ||= 2
else
  $stdout.puts "Datacenter '#{datacenter}' found.".green

  cl = dc.hostFolder.children.find { |clus| clus.name == cluster }

  if cl == nil
    $stderr.puts "Cluster '#{cluster}' not found.".red
    exit_code ||= 3
  else
    $stdout.puts "Cluster '#{cluster}' found.".green

    datastores = cl.datastore.find_all { |ds| !!(ds.name =~ Regexp.new(datastore)) }

    if datastores == nil || datastores.size == 0
      $stderr.puts "Could not find any datastores matching '#{ datastore }'.".red
      exit_code ||= 4
    else
      $stdout.puts "Found the following datastores: #{ datastores.map {|ds| "'#{ds.name}'"}.join(", ") }.".green
    end
  end

  dc_tf = dc.vmFolder.children.find{ |x| x.name ==  template_folder}

  if dc_tf == nil
    $stderr.puts "Could not find a folder for templates named '#{ template_folder }' in datacenter '#{ datacenter }'.".red
    exit_code ||= 5
  else
    $stdout.puts "Template folder '#{ template_folder }' found.".green
  end

  dc_vmf = dc.vmFolder.children.find{ |x| x.name ==  vm_folder}

  if dc_vmf == nil
    $stderr.puts "Could not find a folder for VMs named '#{ vm_folder }' in datacenter '#{ datacenter }'.".red
    exit_code ||= 6
  else
    $stdout.puts "VM folder '#{ vm_folder }' found.".green
  end
end



exit! exit_code == nil ? 0 : exit_code