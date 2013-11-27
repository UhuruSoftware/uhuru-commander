require 'ipaddr'

module Uhuru::BoshCommander
  # Helper class used to manipulate IP addresses
  class IPHelper
    IP_REGEX =  /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/

    # Returns a sublist of elements of a certain length from a IP list
    # ips = initial list of IPs
    # count = number of items to get from the initial list
    #
    def self.get_ips_from_range(ips, count)
      unless ips.is_a? Array
        ips = from_string(ips)
      end

      count_done = 0
      result = []

      ips.each do |range|
        ip_start = ip_to_int range[0]
        ip_end = ip_to_int range[1]

        max_ips = [(ip_end - ip_start + 1), count - count_done].min

        (0..max_ips - 1).each do |offset|
          result << ip_to_string(ip_start + offset)
          count_done = count_done + 1
        end
      end

      result
    end

    # Counts the IPs in a range
    # ips = ip list
    #
    def self.ip_count_in_range(ips)
      unless ips.is_a? Array
        ips = from_string(ips)
      end

      count = 0

      ips.each do |range|
        count = count + ip_to_int(range[1]) - ip_to_int(range[0]) + 1
      end

      count
    end

    # Search if an IP is in a given list
    # ips = list of IPs
    # ip = IP to search for
    #
    def self.ip_in_range?(ips, ip)
      unless ips.is_a? Array
        ips = from_string(ips)
      end

      is_in_range = false
      ip = ip_to_int ip

      ips.each do |range|
        low = ip_to_int range[0]
        high = ip_to_int range[1]

        if (low..high)===ip
          is_in_range = true
        end
      end

      is_in_range
    end

    # Returns the integer representation of the ip
    # ip = ip to be transformed
    #
    def self.ip_to_int(ip)
      IPAddr.new(ip).to_i
    end

    # Returns a string containing the IP address representation
    # ip = ip to be transformed
    #
    def self.ip_to_string(ip)
      IPAddr.new(ip, Socket::AF_INET).to_s
    end

    # Subtracts an ip range from another ip range
    # first_ip_range = ip range from where to be subtracted
    # second_ip_range = ip range to be subtracted
    #
    def self.subtract_range(first_ip_range, second_ip_range)
      b_first, b_last = second_ip_range

      b_first = ip_to_int b_first
      b_last = ip_to_int b_last

      result = []

      first_ip_range.each do |first, last|
        first = ip_to_int first
        last = ip_to_int last

        b_first_prev = b_first - 1
        b_last_next = b_last + 1

        if b_first < first
          if b_last < first
            #nothing to subtract
            result << [first, last]
          elsif b_last < last
            result << [b_last_next, last]
          else
            #nothing left
          end
        elsif b_first <= last
          if b_last < first
            #impossible
            raise "Improper IP ranges when subtracting."
          elsif b_last < last
            result << [first, b_first_prev] if first <= b_first_prev
            result << [b_last_next, last] if b_last_next <= last
          else
            result << [first, b_first_prev] if first <= b_first_prev
          end
        else
          #nothing to subtract
          result << [first, last]
        end
      end
      result.map do |interval|
        interval.map do |ip|
          ip_to_string ip
        end
      end
    end

    # Checks if a list of IPs is in the proper string format
    # ip_list = list of IPs
    #
    def self.is_valid_string?(ip_list)
      if ip_list == nil || ip_list.strip == ''
        return false
      end

      ranges = ip_list.gsub(/,/, ';').split(';').map(&:strip).reject(&:empty?)

      is_wrong = ranges.any? do |range|
        ips = range.split('-').map(&:strip).reject(&:empty?)
        if ips.size > 2
          true
        else
          ips.any? do |ip|
            !(ip =~ IP_REGEX)
          end
        end
      end

      !is_wrong
    end

    # Returns an array of IPs from a string
    # ip_list = string containing ip list
    #
    def self.from_string(ip_list)
      unless is_valid_string? ip_list
        raise "Invalid IP range '#{ip_list}'"
      end

      ranges = ip_list.gsub(/,/, ';').split(';').map(&:strip).reject(&:empty?)

      ranges.map do |range|
        ips = range.split('-').map(&:strip).reject(&:empty?)

        first_ip = ips[0]
        if ips.size == 1
          [first_ip, first_ip]
        else
          [first_ip, ips[1]]
        end
      end
    end

    # Returns a string containing IPs separated by '-' from an array
    # ip_list = list of IPs to be transformed
    #
    def self.to_string(ip_list)
      result = nil

      ip_list.each do |ip_range|
        first_ip_range = ip_range[0]
        second_ip_range = ip_range[1]
        if first_ip_range == second_ip_range
          result = [result, first_ip_range].join('; ')
        else
          result = [result, [first_ip_range, second_ip_range].join('-')].join('; ')
        end
      end

      2.times do result[0] = '' end

      result
    end

    # Returns the subnet limits for an IP
    # ip_with_subnet = ip to get limits from
    #
    def self.get_subnet_limits(ip_with_subnet)
      ipaddr = IPAddrWithMask.new(ip_with_subnet)
      ip = ipaddr.to_i
      mask = ipaddr.mask_to_i

      count = 1
      temp = mask

      while (temp & 1) == 0 do
        count *= 2
        temp >>= 1
      end

      result = []

      [1, count - 2].each do |index|
        new_ip = ((ip & mask) | index) & 0xFFFFFFFF;
        fourth = new_ip & 0xFF
        third = (new_ip / 256) & 0xFF
        second = (new_ip / 65536) & 0xFF
        first = (new_ip / 16777216) & 0xFF
        result << "#{first}.#{second}.#{third}.#{fourth}";
      end

      result
    end

    # Gets the short subnet from a subnet
    # subnet = subnet to be shortened
    #
    def self.get_subnet_short(subnet)
      IPAdmin.unpack_ip_netmask(IPAdmin.pack_ip_netmask(subnet))
    end

    # Gets IPv4 netmask in extended format
    # ip_with_subnet = ip with subnet to be transformed
    #
    def self.get_subnet_netmask(ip_with_subnet)
      IPAdmin::CIDR.new(ip_with_subnet).netmask_ext
    end
  end
end

# Class used to manipulate on IP address with mask
class IPAddrWithMask < IPAddr
  def mask_to_i
    @mask_addr
  end
end
