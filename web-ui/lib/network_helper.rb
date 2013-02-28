require 'ip_admin'

class NetworkHelper
  def initialize(parameters = {})
    @manifest = parameters[:cloud_manifest]
    @data = parameters[:form_data]
  end

  def get_reserved_ip_range
    static_ip_start = @data["cloud:Network:static_ip_range"].split('-')[0].strip
    static_ip_end = @data["cloud:Network:static_ip_range"].split('-')[1].strip

    dynamic_ip_start = @data["cloud:Network:dynamic_ip_range"].split('-')[0].strip
    dynamic_ip_end = @data["cloud:Network:dynamic_ip_range"].split('-')[1].strip

    subnet_mask = @data["cloud:Network:subnet_mask"]

    gateway = @data["cloud:Network:gateway"]

    sorted_ip_boundaries = IPAdmin.sort [static_ip_start, static_ip_end, dynamic_ip_start, dynamic_ip_end]

    if ((sorted_ip_boundaries[0] == static_ip_start) && (sorted_ip_boundaries[1] != static_ip_end)) ||
        ((sorted_ip_boundaries[2] == static_ip_start) && (sorted_ip_boundaries[3] != static_ip_end)) ||
        ((sorted_ip_boundaries[0] == dynamic_ip_start) && (sorted_ip_boundaries[1] != dynamic_ip_end)) ||
        ((sorted_ip_boundaries[2] == dynamic_ip_start) && (sorted_ip_boundaries[3] != dynamic_ip_end))
      raise "Invalid IP range"
    end

    subnet_mask_bits = get_subnet_bits(subnet_mask)
    ips_in_subnet = get_ips_in_subnet("#{dynamic_ip_start}/#{subnet_mask_bits}")
    ips_in_static = self.class.get_ip_range(static_ip_start, static_ip_end)
    ips_in_dynamic = self.class.get_ip_range(dynamic_ip_start, dynamic_ip_end)

    used_ips_boundaries = [ips_in_subnet.first, ips_in_subnet.last]

    if (ips_in_static.include? gateway) || (ips_in_dynamic.include? gateway)
      used_ips_boundaries += [static_ip_start, static_ip_end]
      used_ips_boundaries += [dynamic_ip_start, dynamic_ip_end]
      reserved_ips = [[0, 1], [2, 3], [4, 5]]
    elsif
    used_ips_boundaries += [static_ip_start, static_ip_end]
      used_ips_boundaries += [dynamic_ip_start, dynamic_ip_end]
      used_ips_boundaries += [gateway, gateway]
      reserved_ips = [[0, 1], [2, 3], [4, 5], [6, 7]]
    end

    used_ips_boundaries = IPAdmin.sort used_ips_boundaries

    reserved_ips = reserved_ips.map do |ip_range|
      reserved_range = self.class.get_ip_range used_ips_boundaries[ip_range[0]], used_ips_boundaries[ip_range[1]]
      [reserved_range.first, reserved_range.last]
    end

    reserved_ips.delete [nil, nil]

    result = []
    reserved_ips.each do |pair|
      result << "#{pair[0]}-#{pair[1]}"
    end

    result
  end

  def get_subnet
    dynamic_ip_start = @data["cloud:Network:dynamic_ip_range"].split('-')[0].strip
    subnet_mask = @data["cloud:Network:subnet_mask"].strip
    subnet_mask_bits = get_subnet_bits(subnet_mask)
    ips_in_subnet = get_ips_in_subnet("#{dynamic_ip_start}/#{subnet_mask_bits}")
    subnet = "#{ips_in_subnet.first}/#{subnet_mask_bits}"
    subnet
  end

  def get_dynamic_ip_range
    if @manifest["networks"][0]["subnets"][0]["static"] == []
      return ""
    end

    static_ip_start = @manifest["networks"][0]["subnets"][0]["static"][0].split("-")[0].strip
    static_ip_end = @manifest["networks"][0]["subnets"][0]["static"][0].split("-")[1].strip
    subnet = @manifest["networks"][0]["subnets"][0]["range"]
    gateway = @manifest["networks"][0]["subnets"][0]["gateway"]

    reserved_ips = []
    if @manifest["networks"][0]["subnets"][0]["reserved"].kind_of?(Array)
      @manifest["networks"][0]["subnets"][0]["reserved"].each do |range|
        reserved_ips << [range.split('-')[0], range.split('-')[1]]
      end
    end
    reserved_ips << [static_ip_start, static_ip_end]

    all_ips = []

    reserved_ips.each do |ips|
      range = self.class.get_ip_range(ips[0], ips[1], true)
      all_ips += range
    end

    all_ips << gateway

    ips_in_subnet = get_ips_in_subnet(subnet)

    dynamic_ip_list = ips_in_subnet - all_ips
    dynamic_ip_list.delete(ips_in_subnet.first)
    dynamic_ip_list.delete(ips_in_subnet.last)
    dynamic_ip_list = IPAdmin.sort dynamic_ip_list

    "#{dynamic_ip_list.first}-#{dynamic_ip_list.last}"
  end

  def get_subnet_mask
    if @manifest["networks"][0]["subnets"][0]["range"]
      return get_subnet_netmask(@manifest["networks"][0]["subnets"][0]["range"])
    end
    ""
  end

  def self.get_ip_range(ip_start, ip_end, inclusive = false)
    IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => ip_start), IPAdmin::CIDR.new(:CIDR => ip_end)], :Inclusive => inclusive
  end

  private

  def get_ips_in_subnet(ip_with_subnet)
    IPAdmin::CIDR.new(ip_with_subnet).enumerate
  end

  def get_subnet_bits(subnet)
    IPAdmin.unpack_ip_netmask(IPAdmin.pack_ip_netmask(subnet))
  end

  def get_subnet_netmask(ip_with_subnet)
    IPAdmin::CIDR.new(ip_with_subnet).netmask_ext
  end
end