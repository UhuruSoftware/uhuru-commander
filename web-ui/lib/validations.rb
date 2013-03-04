require 'ip_admin'
require "ipaddress"

#
#HERE WOULD BE REQUIRED THE SPECIFIC VALIDATION CLASS WITCH WILL INCLUDE IP CHECKING AND SO ON
#

class Validations
  def self.validate_field(value, type)
    begin
      error = ''
      case type
        when "ip"
          unless IPAddress.valid_ipv4?(value)
            error = "This is not of type IP!"
          end

        when "ip_range"
          begin
            if value.include?("-")
              unless IPAddress.valid_ipv4?(value.split('-')[0].strip) || IPAddress.valid_ipv4?(value.split('-')[1].strip)
                error = "This is not a proper IP range!"
              end
            else
              cidr4 = IPAdmin::CIDR.new(value)
              list = cidr4.enumerate
              if list.count == 0
                error = "This is not a proper IP range!"
              end
            end
          rescue
            error = "This is not a proper IP range!"
          end

        when "numeric"
          unless /^\d*\.{0,1}\d*$/.match(value)
            error = "This is not a number!"
          end

        when "netmask"
          unless IPAddress.valid_ipv4_netmask?(value)
            error = "It is not a valid netmask!"
          end

        when "string"
          unless value.size < 256
            error = "The length of this field exceeds 255 characters!"
          end

        when "text"
            error = ''

        when "product_key"
          unless /^([A-Z0-9]{5})-([A-Z0-9]{5})-([A-Z0-9]{5})-([A-Z0-9]{5})-([A-Z0-9]{5})$/.match(value)
            error = "Invalid product key!"
          end

        when "boolean"
          unless value == 'true' || value == 'false'
            error = "This is not a boolean"
          end

        when "list"
          if value.kind_of?(Array)
            return true
          elsif value = nil && value = ""
            return "Empty box!"
          else
            return "This is not a list!"
          end
      end
      error
    rescue Exception => e
      puts e.to_s + "<<< - ------- validation class"
      return "Server error for this field!"
    end
      #list = IPAdmin.range :Boundaries => [
      #    IPAdmin::CIDR.new(:CIDR => "192.167.2.1"),
      #    IPAdmin::CIDR.new(:CIDR => "192.168.1"),
      #]
      #list
  end
end