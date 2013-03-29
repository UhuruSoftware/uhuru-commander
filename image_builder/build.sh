#!/bin/bash

local_ip=`ifconfig eth0|grep -w inet|cut -f 2 -d ":"|cut -f 1 -d " "`
PATH="/var/vcap/bosh/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin"
TERM="xterm"
export BUNDLE_GEMFILE=/root/Gemfile

cd /root/
. config.sh

function switch_to_http_sub_modules()
{
    sed -i "s/git@github.com:/https:\/\/${git_user}:${git_password}@github.com\//g" .gitmodules
}

function install_packages()
{
    log_builder "Installing needed packages on micro bosh"
    apt-get update
    apt-get -y install git-core ftp zerofree postgresql-client gpm dialog ipcalc libsqlite3-dev

    cd /root/
    log_builder "Installing bundler"
    gem install -r bundler
    log_builder "Installing ruby gems"
    bundle install --system

    log_builder "Done installing packages on micro bosh"
}

function get_commander()
{
    log_builder "Setting up Commander on micro bosh"

    rm -rf /var/vcap/store/ucc

    pwd=`pwd`
    cd /root
    log_builder "Cloning commander git repo"
    git clone ${git_commander_repo}
    cd private-uhuru-commander
    git reset --hard ${git_commander_commit}
    switch_to_http_sub_modules

    mkdir /var/vcap/store/ucc
    log_builder "Moving Commander files to '/var/vcap/store/ucc/'"
    mv private-uhuru-commander/* /var/vcap/store/ucc/
    rm -rf private-uhuru-commander

    log_builder "Linking stemcells from '/var/vcap/store/ucc_stemcells/'"
    ln -s /var/vcap/store/ucc_stemcells/${windows_stemcell}     /var/vcap/store/ucc/resources/${windows_stemcell}
    ln -s /var/vcap/store/ucc_stemcells/${windows_sql_stemcell} /var/vcap/store/ucc/resources/${windows_sql_stemcell}
    ln -s /var/vcap/store/ucc_stemcells/${linux_stemcell}       /var/vcap/store/ucc/resources/${linux_stemcell}
    ln -s /var/vcap/store/ucc_stemcells/${linux_php_stemcell}   /var/vcap/store/ucc/resources/${linux_php_stemcell}

    cd /var/vcap/store/ucc/web-ui/config
    rm -f /var/vcap/store/ucc/web-ui/config/infrastructure.yml

    log_builder "Installing Commander ruby gems"
    cd /var/vcap/store/ucc/web-ui/
    bundle install
    cd ${pwd}

    log_builder "Done settting up commander"
}


function stemcells()
{
    log_builder "Setting up stemcells in micro bosh"
    rm -rf /var/vcap/store/ucc_stemcells

    pwd=`pwd`

    bundle exec bosh --user admin --password admin target localhost
    bundle exec bosh login admin admin

    log_builder "Removing existing stemcells from bosh"
    bundle exec bosh stemcells | grep -v Name | grep \| | tr -d \| | awk '{print $1,$2}'| while read line;do echo "bundle exec bosh delete stemcell ${line}";done | bash

    mkdir /var/vcap/data/permanenttmp

    mount -o bind /var/vcap/data/permanenttmp /tmp
    chmod 1777 /tmp

    mkdir -p /var/vcap/store/ucc_stemcells

    log_builder "Downloading stemcells from ftp"
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${windows_stemcell}" -o /var/vcap/store/ucc_stemcells/${windows_stemcell}
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${windows_sql_stemcell}" -o /var/vcap/store/ucc_stemcells/${windows_sql_stemcell}
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${linux_stemcell}" -o /var/vcap/store/ucc_stemcells/${linux_stemcell}
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${linux_php_stemcell}" -o /var/vcap/store/ucc_stemcells/${linux_php_stemcell}

    log_builder "Uploading stemcells to bosh"
    bundle exec bosh upload stemcell /var/vcap/store/ucc_stemcells/${windows_stemcell}
    bundle exec bosh upload stemcell /var/vcap/store/ucc_stemcells/${windows_sql_stemcell}
    bundle exec bosh upload stemcell /var/vcap/store/ucc_stemcells/${linux_stemcell}
    bundle exec bosh upload stemcell /var/vcap/store/ucc_stemcells/${linux_php_stemcell}

    cd ${pwd}
    log_builder "Done setting up stemcells"
}

function create_release()
{
    log_builder "Creating cloud foundry release"

    pwd=`pwd`

    rm -rf /var/vcap/store/ucc_release/
    mkdir -p /var/vcap/store/ucc_release/

    cd /var/vcap/store/ucc_release/

    log_builder "Cloning cloud foundry release git repo"
    git clone ${git_cf_release}
    cd private-cf-release
    git reset --hard ${git_cf_release_commit}
    switch_to_http_sub_modules
    log_builder "Updating git submodules"
    ./update

    log_builder "Executing bosh create release with tarball"
    bundle exec bosh --non-interactive create release --with-tarball
    release_tarball=`ls /var/vcap/store/ucc_release/private-cf-release/dev_releases/*.tgz`
    log_builder "Uploading release to bosh"
    bundle exec bosh upload release ${release_tarball}
    cd ${pwd}

    rm -rf /var/vcap/store/ucc_release/

    log_builder "Done creating cloud foundry release"
}

function cleanup()
{
    log_builder "Cleaning up micro bosh VM"

    rm -f /root/.bash_history
    rm -f /root/.ssh/*
    rm -f /root/build.sh
    rm -f /root/config.sh
    rm -rf /var/vcap/data/tmp/private-cf-release/dev_releases
    rm -f /root/compilation_manifest.yml
    rm -f /root/Gemfile
    rm -f /root/Gemfile.lock

    touch /var/lock/passwd

    passwd -d vcap
    chage -d 0 vcap
    log_builder "Done cleaning up micro bosh VM"
}

function configure_init()
{
    log_builder "Configuring daemons and crontab"
    chmod 1777 /tmp

    update-rc.d ucc defaults 99
    update-rc.d ttyjs defaults 99

    cat /etc/service/agent/run|grep -v "/var/vcap/bosh/agent/bin/agent" >/tmp/agent_run
    echo '#exec /usr/bin/nice -n -10 /var/vcap/bosh/agent/bin/agent -c -I $(cat /etc/infrastructure)' >>/tmp/agent_run
    mv -f /tmp/agent_run /etc/service/agent/run

    echo "*/1 * * * * service ucc status || service ucc restart" >/var/spool/cron/crontabs/vcap
    echo "*/1 * * * * service ttyjs status || service ttyjs restart" >>/var/spool/cron/crontabs/vcap
    chown vcap.vcap /var/spool/cron/crontabs/vcap
    log_builder "Done configuring daemons and crontab"
}

function deploy_cf()
{
    log_builder "Compiling cloud foundry packages"

    echo "update stemcells set name=replace(name, 'empty-', '')" | PGPASSWORD="postgres" psql -U postgres -h localhost -d bosh

    uuid=`bundle exec bosh status|grep UUID|awk '{print $2}'`
    sed -i s/REPLACEME/${uuid}/g /root/compilation_manifest.yml
    release_yml=`ls /var/vcap/store/ucc/web-ui/resources/private-cf-release/dev_releases/*.yml | grep -v index.yml`
    log_builder "Updating cloud foundry deployment yml"

  ruby -e "
require 'yaml'
release_yml = YAML.load_file('${release_yml}')
config = YAML.load_file('/root/compilation_manifest.yml')

config['release']['version'] = release_yml['version']

config['networks'][0]['subnets'][0]['reserved'] = '${micro_reserved_ips}'.split(';')
config['networks'][0]['subnets'][0]['static'] = '${micro_static_ips}'.split(';')
config['networks'][0]['subnets'][0]['range'] = '${micro_network_range}'
config['networks'][0]['subnets'][0]['gateway'] = '${micro_gateway}'
config['networks'][0]['subnets'][0]['dns'] = '${micro_dns}'.split(';')
config['networks'][0]['subnets'][0]['cloud_properties']['name'] = '${micro_vm_network}'

config['cloud']['properties']['vcenters'][0]['host'] = '${vsphere_host}'
config['cloud']['properties']['vcenters'][0]['address'] = '${vsphere_host}'
config['cloud']['properties']['vcenters'][0]['user'] = '${vsphere_user}'
config['cloud']['properties']['vcenters'][0]['password'] = '${vsphere_password}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['name'] = '${datacenter}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['vm_folder'] = '${vm_folder}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['template_folder'] = '${template_folder}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['disk_path'] = '${disk_path}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['datastore_pattern'] = '${datastore}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['persistent_datastore_pattern'] = '${datastore}'
config['cloud']['properties']['vcenters'][0]['datacenters'][0]['clusters'][0] = '${cluster}'

File.open('/root/compilation_manifest.yml', 'w') do |file|
 yaml = YAML.dump(config)
 file.write(yaml.gsub(\" \n\", \"\n\"))
 file.flush
end
"

    log_builder "Executing bosh deployment"
    bundle exec bosh deployment /root/compilation_manifest.yml

    for i in `seq 1 10` ;
    do
        bundle exec bosh --non-interactive deploy
        [ $? -eq 0 ] &&
        {
            echo "update stemcells set name='empty-' || name" | PGPASSWORD="postgres" psql -U postgres -h localhost -d bosh
            break
        }

        log_builder "Retrying bosh deployment"
    done

    log_builder "Done compiling cloud foundry"
}

function install_tty_js()
{
    log_builder "Setting up tty.js"
    cwd=`pwd`
    rm -rf /var/vcap/store/ucc/tty.js

    log_builder "Installing node.js"
    cd /tmp
    mkdir nodejs
    cd nodejs
    wget -N http://nodejs.org/dist/node-latest.tar.gz
    tar xzvf node-latest.tar.gz && cd `ls -rd node-v*`
    ./configure
    make install

    log_builder "Installing npm"
    cd ..
    mkdir npm
    cd npm
    wget http://npmjs.org/install.sh --no-check-certificate
    bash install.sh
    cd ..

    log_builder "Cloning tty.js repo"
    git clone ${git_ttyjs}
    cd private-ttyjs
    git reset --hard ${git_ttyjs_commit}
    cd ..

    mkdir /var/vcap/store/ucc/tty.js
    mv private-tty.js/* /var/vcap/store/ucc/tty.js/

    rm -rf private-tty.js npm nodejs

    log_builder "Installing tty.js dependencies"
    cd /var/vcap/store/ucc/tty.js/
    npm install

    cd ${cwd}
    log_builder "Done setting up tty.js"
}

function zero_free()
{
    log_builder "Running zerofree"
    cd /root
    monit stop all
    sleep 60
    umount /tmp
    umount /tmp
    umount /tmp
    umount /dev/sdc1
    zerofree /dev/sdc1
    umount /dev/loop0
    umount /dev/sdb2
    zerofree /dev/sdb2
    log_builder "Done running zerofree"
}


param_present 'micro_packages'          $* && install_packages
param_present 'micro_stemcells'         $* && stemcells
param_present 'micro_commander'         $* && get_commander
param_present 'micro_create_release'    $* && create_release
param_present 'micro_config_daemons'    $* && configure_init
param_present 'micro_ttyjs'             $* && install_tty_js
param_present 'micro_compile'           $* && deploy_cf
param_present 'micro_cleanup'           $* && cleanup
param_present 'micro_zero_free'         $* && zero_free
