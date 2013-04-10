require 'ipaddr'

module Uhuru::BoshCommander
  class IPHelper
    IP_REGEX =  /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/

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

    def self.ip_to_int(ip)
      IPAddr.new(ip).to_i
    end

    def self.ip_to_string(ip)
      IPAddr.new(ip, Socket::AF_INET).to_s
    end

    def self.subtract_range(a, b)
      b_first, b_last = b

      b_first = ip_to_int b_first
      b_last = ip_to_int b_last

      result = []

      a.each do |first, last|
        first = ip_to_int first
        last = ip_to_int last

        if b_first < first
          if b_last < first
            #nothing to subtract
            result << [first, last]
          elsif b_last < last
            result << [b_last + 1, last]
          else
            #nothing left
          end
        elsif b_first <= last
          if b_last < first
            #impossible
            raise "Improper IP ranges when subtracting."
          elsif b_last < last
            result << [first, b_first - 1] if first <= b_first - 1
            result << [b_last + 1, last] if b_last + 1 <= last
          else
            result << [first, b_first - 1] if first <= b_first - 1
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

    def self.from_string(ip_list)
      unless is_valid_string? ip_list
        raise "Invalid IP range '#{ip_list}'"
      end

      ranges = ip_list.gsub(/,/, ';').split(';').map(&:strip).reject(&:empty?)

      ranges.map do |range|
        ips = range.split('-').map(&:strip).reject(&:empty?)

        if ips.size == 1
          [ips[0], ips[0]]
        else
          [ips[0], ips[1]]
        end
      end
    end

    def self.to_string(ip_list)
      result = nil

      ip_list.each do |ip_range|
        if ip_range[0] == ip_range[1]
          result = [result, ip_range[0]].join('; ')
        else
          result = [result, [ip_range[0], ip_range[1]].join('-')].join('; ')
        end
      end

      2.times do result[0] = '' end

      result
    end

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
        newIP = ((ip & mask) | index) & 0xFFFFFFFF;
        d = newIP & 0xFF
        c = (newIP / 256) & 0xFF
        b = (newIP / 65536) & 0xFF
        a = (newIP / 16777216) & 0xFF
        result << "#{a}.#{b}.#{c}.#{d}";
      end

      result
    end

    def self.get_subnet_short(subnet)
      IPAdmin.unpack_ip_netmask(IPAdmin.pack_ip_netmask(subnet))
    end

    def self.get_subnet_netmask(ip_with_subnet)
      IPAdmin::CIDR.new(ip_with_subnet).netmask_ext
    end
  end
end

class IPAddrWithMask < IPAddr
  def mask_to_i
    @mask_addr
  end
end
