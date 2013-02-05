require 'ip_admin'

#def ip_range(range, &block)
#  start, delta = range.split("-").map do |ipstr|
#    ipstr.split(".").map do |number| number.to_i end
#  end
#
#  (0..3).each do |pos|
#    delta[pos] -= start[pos]
#  end
#
#  (0..delta[0]).each do |d0|
#    (0..delta[1]).each do |d1|
#      (0..delta[2]).each do |d2|
#        (0..delta[3]).each do |d3|
#          yield [start[0] + d0, start[1] + d1, start[2] + d2, start[3] +
#              d3]
#        end
#      end
#    end
#  end
#end

#ip_range("192.167.1.1-192.169.2.5") do |ip|
#  pp ip
#end

list = IPAdmin.range :Boundaries => [
    IPAdmin::CIDR.new(:CIDR => "192.167.255.1"),
    IPAdmin::CIDR.new(:CIDR => "192.168.1.5"),
    ]

p list.count


cidr4 = IPAdmin::CIDR.new('192.168.1.1/24')
list = cidr4.enumerate

p list.count

#[byte].[byte].[byte].[byte]/[byte]
#[byte].[byte].[byte].[byte][whitespace] - [byte].[byte].[byte].[byte]

