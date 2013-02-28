require 'ip_admin'

ere
user_ip_range_start = "10.0.1.100"
user_ip_range_end = "10.0.2.190"
user_ip_subnet_mask = "255.255.0.0"
user_ip_gateway = "10.0.3.162"

reserved_ip = ""
range = ""


user_ip_subnet_mask_bits = IPAdmin.unpack_ip_netmask(IPAdmin.pack_ip_netmask(user_ip_subnet_mask))

list = IPAdmin.range :Boundaries => [
    IPAdmin::CIDR.new(:CIDR => user_ip_range_start),
    IPAdmin::CIDR.new(:CIDR => user_ip_range_end),
    ]


withnetmask = IPAdmin::CIDR.new("#{user_ip_range_start}/#{user_ip_subnet_mask_bits}")

subnet_list = withnetmask.enumerate



start_range = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => subnet_list.first), IPAdmin::CIDR.new(:CIDR => user_ip_range_start)]
end_range = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => user_ip_range_end), IPAdmin::CIDR.new(:CIDR => subnet_list.last)]

reserved_ips = []

if start_range.include? user_ip_gateway
  gw_range_start = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => start_range.first), IPAdmin::CIDR.new(:CIDR => user_ip_gateway)], :Inclusive => true
  gw_range_end = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => user_ip_gateway), IPAdmin::CIDR.new(:CIDR => start_range.last)], :Inclusive => true

  gw_range_start.delete(user_ip_gateway)
  gw_range_end.delete(user_ip_gateway)

  reserved_ips << [gw_range_start.first, gw_range_start.last]
  reserved_ips << [gw_range_end.first, gw_range_end.last]
else
  reserved_ips << [start_range.first, start_range.last]
end

if end_range.include? user_ip_gateway
  gw_range_start = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => end_range.first), IPAdmin::CIDR.new(:CIDR => user_ip_gateway)], :Inclusive => true
  gw_range_end = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => user_ip_gateway), IPAdmin::CIDR.new(:CIDR => end_range.last)], :Inclusive => true

  gw_range_start.delete(user_ip_gateway)
  gw_range_end.delete(user_ip_gateway)


  reserved_ips << [gw_range_start.first, gw_range_start.last]
  reserved_ips << [gw_range_end.first, gw_range_end.last]
else
  reserved_ips << [end_range.first, end_range.last]
end


puts "Pelerinul shi-a facut magia."

p "#{subnet_list.first}/#{user_ip_subnet_mask_bits}"

reserved_ips.each do |ips|
  p ips
end


##############################################################################################


all_ips = []

reserved_ips.each do |ips|
  range = IPAdmin.range :Boundaries => [IPAdmin::CIDR.new(:CIDR => ips[0]), IPAdmin::CIDR.new(:CIDR => ips[1])], :Inclusive => true

  all_ips += range
end

all_ips << user_ip_gateway

withnetmask = IPAdmin::CIDR.new("10.0.0.0/16")

users_list = withnetmask.enumerate - all_ips
users_list.delete(withnetmask.first)
users_list.delete(withnetmask.last)


puts "Pelerinul reloaded"

users_list = IPAdmin.sort users_list

p "#{withnetmask.netmask_ext()}"
p "#{users_list.first}-#{users_list.last}"


