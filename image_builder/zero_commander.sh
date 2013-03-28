#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config.sh

function as_root()
{
    sudo $*
}


function as_user()
{
    sudo -u ${SUDO_USER} $*
}

function packages()
{
    as_root aptitude install -y \
      sshpass \
      build-essential zlib1g-dev \
      libssl-dev openssl \
      libreadline-dev \
      libyaml-dev \
      libyaml-ruby \
      libpq-dev \
      sqlite3 libsqlite3-dev \
      libxslt-dev libxml2-dev \
      ftp \
      genisoimage \
      debootstrap \
      curl wget git-core
}

function prerequisites()
{
    as_user mkdir ~/prerequisites
    cd ~/prerequisites
    as_user wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz
    as_user tar xzf ruby-1.9.3-p392.tar.gz
    cd ruby-1.9.3-p392/
    as_user ./configure
    as_user make
    as_root make install

    as_root gem install bundler
}

function micro_bosh_stemcell()
{
    as_user mkdir ~/sources
    as_root rm -rf ~/sources/private-bosh
    cd ~/sources
    as_user git clone ${git_bosh_repo}
    cd private-bosh
    as_user git reset --hard ${git_bosh_commit}

    as_user sed -i "s/git@github.com:/https:\/\/${git_user}:${git_password}@github.com\//g" .gitmodules
    as_user git submodule update --init

    as_user bundle install
    as_root bundle exec rake all:install
    as_root bundle exec rake all:finalize_release_directory
    as_root bundle exec rake stemcell:micro[vsphere]
}

function deployer()
{
    as_user mkdir ~/sources
    as_user rm -rf ~/sources/private-uhuru-commander
    cd ~/sources
    as_user git clone ${git_commander_repo}
    cd private-uhuru-commander
    as_user git reset --hard ${git_commander_commit}

    micro_bosh_tarball=`ls ~/sources/private-bosh/release/dev_releases/*.tgz`
    as_root cp -f ${micro_bosh_tarball} ~/sources/private-uhuru-commander/image_builder/deployments/${micro_stemcell}

    # run install.sh
    cd ${original_dir}
    as_user cp -f config.sh ~/sources/private-uhuru-commander/image_builder/

    cd ~/sources/private-uhuru-commander/image_builder
    as_user sed -i "s/git@github.com:/https:\/\/${git_user}:${git_password}@github.com\//g" Gemfile
    as_root bundle install
    as_root bundle exec bash ./install.sh $*
}

function create_ovf()
{
    [  which ovftool >/dev/null  ] &&
    {
        micro_bosh_vm_name=`cat ~/sources/private-uhuru-commander/image_builder/deployments/bosh-deployments.yml | grep "vm_cid" | awk '{print $2}'`
        as_user mkdir ~/ovf
        cd ~/ovf
        vm="vi://vi://${vsphere_user}:${vsphere_password}@${vsphere_host}/${datacenter}/vm/${vm_folder}/${micro_bosh_vm_name}"
        as_user ovftool "ucc-${version}.ofv"
    } ||
    {
        echo '!!!WARNING!!! Skipping ovf generation because ovftool is not installed.'
    }
}

# delete deployment
original_dir=`pwd`
param_present 'local_packages'       $* && packages
param_present 'local_prerequisites'  $* && prerequisites
param_present 'local_create_micro'   $* && micro_bosh_stemcell
param_present 'local_run_deployer'   $* && deployer $*
param_present 'local_create_ovf'     $* && create_ovf