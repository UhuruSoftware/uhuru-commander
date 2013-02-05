require 'ip_admin'
require "ipaddress"

#
#HERE WOULD BE REQUIRED THE SPECIFIC VALIDATION CLASS WITCH WILL INCLUDE IP CHECKING AND SO ON
#

class Validations
  def self.validate_field(value, type)
    begin
      case type
        when "ip"
          if IPAddress.valid_ipv4?(value)
            return true
          else
            return "This is not of type IP!"
          end

        when "ip_range"
          cidr4 = IPAdmin::CIDR.new(value)
          list = cidr4.enumerate
            if list.count == 0
              return "This is not a proper range!"
            end
          return true

        when "numeric"
          if /^[\d]+(\.[\d]+){0,1}$/.match(value)
            return true
          else
            return "This is not a number!"
          end

        when "netmask"
          if IPAddress.valid_ipv4_netmask?(value)
            return true
          else
            return "It is not NETMASK type!"
          end

        when "string"
          if /^[-a-zA-Z]+$/.match(value)
            return true
          else
            return "This is not a string!"
          end

        when "text"
          if value.count > 50                #
            return true                      #   THIS IS A TEXT AREA AND IT SHOULD BE MORE THAN 50 CHRS
          else                               #
            return "More words are needed for the rich text box!"
          end

        when "product_key"
          if /\d{4}-\d{4}-\d{4}-\d{4}-\d{4}/.match(value)
            return true
          else
            return "Invalid product key!"
          end

        when "boolean"
          if value.is_a?(Boolean)
            return true
          else
            return "This is not a boolean"
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