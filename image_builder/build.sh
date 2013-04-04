#!/bin/bash

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

    log_builder "Installing node.js"
    cd /tmp
    mkdir nodejs
    cd nodejs
    wget -N http://nodejs.org/dist/node-latest.tar.gz
    tar xzvf node-latest.tar.gz && cd `ls -rd node-v*`
    ./configure
    make install

    cd /root/

    log_builder "Done installing packages on micro bosh"
}

function get_commander()
{
    log_builder "Setting up Commander on micro bosh"

    rm -rf /tmp/ucc_bkp
    mkdir /tmp/ucc_bkp
    cp -R /var/vcap/store/ucc/web-ui/cf_deployments /tmp/ucc_bkp/
    cp /var/vcap/store/ucc/web-ui/config/infrastructure.yml /tmp/ucc_bkp/

    rm -rf /var/vcap/store/ucc

    pwd=`pwd`
    cd /root
    log_builder "Cloning commander git repo"
    git clone ${git_commander_repo}
    cd private-uhuru-commander
    git reset --hard ${git_commander_commit}

    find . -name Gemfile -print0 | xargs -0 sed -i "s/ssh:\/\/git@github.com/https:\/\/${git_user}:${git_password}@github.com/g"
    find . -name Gemfile -print0 | xargs -0 sed -i "s/git@github.com:/https:\/\/${git_user}:${git_password}@github.com\//g"
    find . -name Gemfile.lock -print0 | xargs -0 sed -i "s/ssh:\/\/git@github.com/https:\/\/${git_user}:${git_password}@github.com/g"

    cd ..

    mkdir /var/vcap/store/ucc
    log_builder "Moving Commander files to '/var/vcap/store/ucc/'"
    mv private-uhuru-commander/* /var/vcap/store/ucc/
    rm -rf private-uhuru-commander

    log_builder "Linking stemcells from '/var/vcap/store/ucc_stemcells/'"
    ln -s /var/vcap/store/ucc_stemcells/${windows_stemcell}     /var/vcap/store/ucc/web-ui/resources/${windows_stemcell}
    ln -s /var/vcap/store/ucc_stemcells/${windows_sql_stemcell} /var/vcap/store/ucc/web-ui/resources/${windows_sql_stemcell}
    ln -s /var/vcap/store/ucc_stemcells/${linux_php_stemcell}   /var/vcap/store/ucc/web-ui/resources/${linux_php_stemcell}

    cd /var/vcap/store/ucc/web-ui/config
    rm -f /var/vcap/store/ucc/web-ui/config/infrastructure.yml
    rm -rf /var/vcap/store/ucc/web-ui/cf_deployments

    cp -R /tmp/ucc_bkp/cf_deployments /var/vcap/store/ucc/web-ui/
    mkdir /var/vcap/store/ucc/web-ui/cf_deployments
    cp /tmp/ucc_bkp/infrastructure.yml /var/vcap/store/ucc/web-ui/config/

    log_builder "Installing Commander ruby gems"
    cd /var/vcap/store/ucc/web-ui/
    export BUNDLE_GEMFILE=/var/vcap/store/ucc/web-ui/Gemfile
    bundle install
    export BUNDLE_GEMFILE=/root/Gemfile

    log_builder "Configuring commander"

  ruby -e "
require 'yaml'
config = YAML.load_file('/var/vcap/store/ucc/web-ui/config/config.yml')

config['local_route'] = '${micro_gateway}'
config['port'] = 80
config['bosh_commander']['skip_check_monit'] = false
config['bosh']['base_dir'] = '/var/vcap'
config['bosh']['target'] = '127.0.0.1'
config['bosh']['stemcells']['linux_php_stemcell']['name'] = '${linux_php_stemcell_name}'
config['bosh']['stemcells']['linux_php_stemcell']['version'] = '${linux_php_stemcell_version}'
config['bosh']['stemcells']['windows_stemcell']['name'] = '${windows_stemcell_name}'
config['bosh']['stemcells']['windows_stemcell']['version'] = '${windows_stemcell_version}'
config['bosh']['stemcells']['mssql_stemcell']['name'] = '${windows_sql_stemcell_name}'
config['bosh']['stemcells']['mssql_stemcell']['version'] = '${windows_sql_stemcell_version}'

File.open('/var/vcap/store/ucc/web-ui/config/config.yml', 'w') do |file|
 yaml = YAML.dump(config)
 file.write(yaml.gsub(\" \n\", \"\n\"))
 file.flush
end
"

    cd ${pwd}

    log_builder "Done settting up commander"
}


function stemcells()
{
    log_builder "Setting up stemcells in micro bosh"
    rm -rf /var/vcap/store/ucc_stemcells

    pwd=`pwd`

    cd /root/

    log_builder "Removing existing stemcells from bosh"
    bundle exec bosh -u admin -p admin -t 127.0.0.1 stemcells | grep -v Name | grep \| | tr -d \| | awk '{print $1,$2}'| while read line;do echo "bundle exec bosh delete stemcell ${line}";done | bash

    mkdir /var/vcap/data/permanenttmp

    mount -o bind /var/vcap/data/permanenttmp /tmp
    chmod 1777 /tmp

    mkdir -p /var/vcap/store/ucc_stemcells

    log_builder "Downloading stemcells from ftp"
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${windows_stemcell}" -o /var/vcap/store/ucc_stemcells/${windows_stemcell}
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${windows_sql_stemcell}" -o /var/vcap/store/ucc_stemcells/${windows_sql_stemcell}
    curl -u ${ftp_user}:${ftp_password} "ftp://${ftp_host}/bosh/stemcells/${linux_php_stemcell}" -o /var/vcap/store/ucc_stemcells/${linux_php_stemcell}

    log_builder "Uploading stemcells to bosh"
    bundle exec bosh -u admin -p admin -t 127.0.0.1 upload stemcell /var/vcap/store/ucc_stemcells/${windows_stemcell}
    bundle exec bosh -u admin -p admin -t 127.0.0.1 upload stemcell /var/vcap/store/ucc_stemcells/${windows_sql_stemcell}
    bundle exec bosh -u admin -p admin -t 127.0.0.1 upload stemcell /var/vcap/store/ucc_stemcells/${linux_php_stemcell}

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

    find . -name Gemfile -print0 | xargs -0 sed -i "s/ssh:\/\/git@github.com/https:\/\/${git_user}:${git_password}@github.com/g"
    find . -name Gemfile -print0 | xargs -0 sed -i "s/git@github.com:/https:\/\/${git_user}:${git_password}@github.com\//g"
    find . -name Gemfile.lock -print0 | xargs -0 sed -i "s/ssh:\/\/git@github.com/https:\/\/${git_user}:${git_password}@github.com/g"


    log_builder "Executing bosh create release with tarball"
    bundle exec bosh -u admin -p admin -t 127.0.0.1 --non-interactive create release --with-tarball --force
    release_tarball=`ls /var/vcap/store/ucc_release/private-cf-release/dev_releases/*.tgz`
    log_builder "Uploading release to bosh"
    bundle exec bosh -u admin -p admin -t 127.0.0.1 upload release ${release_tarball}
    cd ${pwd}

    log_builder "Done creating cloud foundry release"
}

function cleanup()
{
    log_builder "Cleaning up micro bosh VM"

    rm -rf /var/vcap/store/ucc_release/
    rm -f /root/.bash_history
    rm -f /root/.ssh/*
    rm -f /root/build.sh
    rm -f /root/config.sh
    rm -f /root/compilation_manifest.yml
    rm -f /root/Gemfile
    rm -f /root/Gemfile.lock

    touch /root/passwd.lock

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

    [ -z "`cat /var/spool/cron/crontabs/root | grep ucc`" ] && echo "*/1 * * * * service ucc status || service ucc restart" >>/var/spool/cron/crontabs/root
    [ -z "`cat /var/spool/cron/crontabs/root | grep ttyjs`" ] && echo "*/1 * * * * service ttyjs status || service ttyjs restart" >>/var/spool/cron/crontabs/root

    log_builder "Done configuring daemons and crontab"
}

function deploy_cf()
{
    log_builder "Compiling cloud foundry packages"

    echo "update stemcells set name=replace(name, 'empty-', '')" | PGPASSWORD="postgres" psql -U postgres -h localhost -d bosh


    bundle exec bosh --user admin --password admin target 127.0.0.1
    uuid=`bundle exec bosh -u admin -p admin -t 127.0.0.1 status|grep UUID|awk '{print $2}'`
    sed -i s/REPLACEME/${uuid}/g /root/compilation_manifest.yml
    release_yml=`ls /var/vcap/store/ucc_release/private-cf-release/dev_releases/*.yml | grep -v index.yml`
    log_builder "Updating cloud foundry deployment yml"

  ruby -e "
require 'yaml'
release_yml = YAML.load_file('${release_yml}')
config = YAML.load_file('/root/compilation_manifest.yml')

config['release']['version'] = release_yml['version']
config['release']['name'] = release_yml['name']

config['networks'][0]['subnets'][0]['reserved'] = '${micro_reserved_ips}'.split(';')
config['networks'][0]['subnets'][0]['static'] = '${micro_static_ips}'.split(';')
config['networks'][0]['subnets'][0]['range'] = '${micro_network_range}'
config['networks'][0]['subnets'][0]['gateway'] = '${micro_gateway}'
config['networks'][0]['subnets'][0]['dns'] = '${micro_dns}'.split(';')
config['networks'][0]['subnets'][0]['cloud_properties']['name'] = '${micro_vm_network}'

config['resource_pools'].find {|rp| rp['name'] == 'windows' }['stemcell']['name'] = '${windows_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'windows' }['stemcell']['version'] = '${windows_stemcell_version}'

config['resource_pools'].find {|rp| rp['name'] == 'sqlserver' }['stemcell']['name'] = '${windows_sql_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'sqlserver' }['stemcell']['version'] = '${windows_sql_stemcell_version}'

config['resource_pools'].find {|rp| rp['name'] == 'tiny' }['stemcell']['name'] = '${linux_php_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'tiny' }['stemcell']['version'] = '${linux_php_stemcell_version}'
config['resource_pools'].find {|rp| rp['name'] == 'small' }['stemcell']['name'] = '${linux_php_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'small' }['stemcell']['version'] = '${linux_php_stemcell_version}'
config['resource_pools'].find {|rp| rp['name'] == 'medium' }['stemcell']['name'] = '${linux_php_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'medium' }['stemcell']['version'] = '${linux_php_stemcell_version}'
config['resource_pools'].find {|rp| rp['name'] == 'large' }['stemcell']['name'] = '${linux_php_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'large' }['stemcell']['version'] = '${linux_php_stemcell_version}'
config['resource_pools'].find {|rp| rp['name'] == 'deas' }['stemcell']['name'] = '${linux_php_stemcell_name}'
config['resource_pools'].find {|rp| rp['name'] == 'deas' }['stemcell']['version'] = '${linux_php_stemcell_version}'

File.open('/root/compilation_manifest.yml', 'w') do |file|
 yaml = YAML.dump(config)
 file.write(yaml.gsub(\" \n\", \"\n\"))
 file.flush
end
"

    log_builder "Executing bosh deployment"
    bundle exec bosh -u admin -p admin -t 127.0.0.1 deployment /root/compilation_manifest.yml

    for i in `seq 1 10` ;
    do
        bundle exec bosh -u admin -p admin -t 127.0.0.1 --non-interactive deploy
        [ $? -eq 0 ] &&
        {
            echo "update stemcells set name='empty-' || name" | PGPASSWORD="postgres" psql -U postgres -h localhost -d bosh
            break
        }

        log_builder "Retrying bosh deployment"
    done

    bundle exec bosh -u admin -p admin -t 127.0.0.1 -n delete deployment compilation_manifest --force

    log_builder "Done compiling cloud foundry"
}

function install_tty_js()
{
    log_builder "Setting up tty.js"
    cwd=`pwd`
    rm -rf /var/vcap/store/tty.js

    log_builder "Cloning tty.js repo"
    git clone ${git_ttyjs}
    cd private-tty.js
    git reset --hard ${git_ttyjs_commit}
    cd ..

    mkdir /var/vcap/store/tty.js
    mv private-tty.js/* /var/vcap/store/tty.js/

    rm -rf private-tty.js npm nodejs

    log_builder "Installing tty.js dependencies"
    cd /var/vcap/store/tty.js/
    npm install

    cd ${cwd}
    log_builder "Done setting up tty.js"
}

function zero_free()
{
    log_builder "Running zerofree"
    cd /root


    log_builder "Pausing cron"
    mv -f /var/spool/cron/crontabs/root /var/spool/cron/crontabs/.root
    log_builder "Stopping UCC and tty.js"
    service ucc stop
    service ttyjs stop

    log_builder "Stopping BOSH"
    monit stop all

    log_builder "Nani un minut"
    sleep 60
    log_builder "Unmount temp dir"
    umount /tmp
    umount /tmp
    umount /tmp
    umount /dev/sdc1
    log_builder "Zeroing hdd1"
    zerofree /dev/sdc1
    umount /dev/loop0
    log_builder "Zeroing hdd2"
    umount /dev/sdb2
    zerofree /dev/sdb2

    log_builder "Restoring cron"
    mv -f /var/spool/cron/crontabs/.root /var/spool/cron/crontabs/root

    log_builder "Done running zerofree"
}


param_present 'micro_packages'          $* && install_packages
param_present 'micro_stemcells'         $* && stemcells
param_present 'micro_create_release'    $* && create_release
param_present 'micro_compile'           $* && deploy_cf
param_present 'micro_ttyjs'             $* && install_tty_js
param_present 'micro_commander'         $* && get_commander
param_present 'micro_config_daemons'    $* && configure_init
param_present 'micro_zero_free'         $* && zero_free
param_present 'micro_cleanup'           $* && cleanup
