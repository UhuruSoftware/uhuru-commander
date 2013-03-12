require '../../web-ui/lib/network_helper'
require 'ipaddr'
require 'yaml'

@deployment = File.open('/home/vladi/Desktop/code/private-uhuru-commander/web-ui/cf_deployments/test/test.yml') { |file| YAML.load(file)}

nh = NetworkHelper.new(cloud_manifest: @deployment)


subnet = @deployment["networks"][0]["subnets"][0]["range"]

tthen = Time.now

nh.get_dynamic_ip_range

p Time.now - tthen
