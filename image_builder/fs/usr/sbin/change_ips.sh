#!/bin/bash

commander_yml='/var/vcap/store/ucc/web-ui/config/config.yml'
current_ip=`ifconfig|grep -w inet|grep -v 127.0.0.1|cut -f 2 -d \:|cut -f 1 -d \ `

[ ! -z "${current_ip}" ] && \
/var/vcap/bosh/bin/ruby -e "
require 'yaml'
config = YAML.load_file('${commander_yml}')
config['local_route'] = '${current_ip}'

File.open('${commander_yml}', 'w') do |file|
 yaml = YAML.dump(config)
 file.write(yaml.gsub(\" \n\", \"\n\"))
 file.flush
end
"
