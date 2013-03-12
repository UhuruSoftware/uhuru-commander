require "rubygems"
require "sinatra"
require "yaml"

module Uhuru::BoshCommander

  class BoshMethods < Sinatra::Base

    def self.save(*args)
      form = args[0]

      if args.count == 6
        form['infrastructures'].each do |infrastructure|
          infrastructure['fields'].each do |field|
            if field['name'] == "ip"
              field['value'] = args[1]
            end
            if field['name'] == "netmask"
              field['value'] = args[2]
            end
            if field['name'] == "gateway"
              field['value'] = args[3]
            end
            if field['name'] == "dns"
              field['value'] = args[4]
            end
            if field['name'] == "vcentername"
              field['value'] = args[5]
            end
          end
        end
        File.open("../config/spec.yaml", "w") {|f|  f.write(YAML.dump(form))}
      else
        form['infrastructures'].each do |infrastructure|
          infrastructure['fields'].each do |field|
            if field['name'] == "ip"
              #p args[1]
            end
            if field['name'] == "netmask"
              #p args[2]
            end
            if field['name'] == "gateway"
              #p args[3]
            end
            if field['name'] == "dns"
              #p args[4]
            end
          end
        end
      end
    end


    def self.save_and_deploy(forms)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "IP --> " + ip
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
          p "DNS --> " + dns
          p "Name --> " + vcentername
        end
      end
    end


    def self.test(forms, ip, netmask, gateway, dns, vcentername)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "IP --> " + ip
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
          p "DNS --> " + dns
          p "Name --> " + vcentername
        end
      end
    end


    def self.update(forms, ip, netmask, gateway, dns, vcentername)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |field|
          if field['name'] == "ip"
            p "IP --> UPDATED"
          end
          if field['name'] == "netmask"
            p "Netmask --> UPDATED"
          end
          if field['name'] == "gateway"
            p "Gateway --> UPDATED"
          end
          if field['name'] == "dns"
            p "DNS --> UPDATED"
          end
          if field['name'] == "vcentername"
            p "Name --> UPDATED"
          end
        end
      end
    end


    def self.tear_down(forms)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
        end
      end
    end


    def self.delete(forms)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
        end
      end
    end


    def self.export(forms)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
        end
      end
    end


    def self.import(forms)
      forms['infrastructures'].each do |infrastructure|
        infrastructure['fields'].each do |gatewayfield|
          p "Netmask --> " + netmask
          p "Gateway --> " + gateway
        end
      end
    end


  end

end

