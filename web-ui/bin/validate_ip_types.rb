require 'ip_admin'
require "ipaddress"

#
#HERE WOULD BE REQUIRED THE SPECIFIC VALIDATION CLASS WITCH WILL INCLUDE IP CHECKING AND SO ON
#

    #@valid = IPAddress.valid? ip
    #if @valid != false
    #puts ip
    #list = IPAdmin.range :Boundaries => [
    #    IPAdmin::CIDR.new(:CIDR => "192.167.2.1"),
    #    IPAdmin::CIDR.new(:CIDR => "192.168.1"),
    #]
    #list


    #cidr4 = IPAdmin::CIDR.new(ip)
    #list = cidr4.enumerate
    #  if list.count == 0
    #    raise "invalid ip"
    #  end
    #list
    #else
    #raise "invalid ip"
    #end

puts IPAddress.valid_ipv4?("192.168.1.16")

