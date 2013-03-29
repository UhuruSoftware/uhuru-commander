#!/bin/bash

echo "Loading configuration"

micro_bosh_vm_user="vcap"
micro_bosh_vm_password="c1oudc0w"
micro_bosh_vm_ip="10.151.0.150"
micro_stemcell="micro-bosh.tgz"

micro_reserved_ips="10.151.0.2-10.151.88.2;10.151.88.201-10.151.255.254"
micro_static_ips="10.151.88.3-10.151.88.125"
micro_network_range="10.151.0.0/16"
micro_gateway="10.151.0.1"
micro_dns="10.0.0.130;8.8.8.8;192.168.1.130"
micro_vm_network="VM Network"

git_user="uhurugit"
git_password="Uhuruv0ice"

git_bosh_repo="https://${git_user}:${git_password}@github.com/UhuruSoftware/private-bosh"
git_commander_repo="https://${git_user}:${git_password}@github.com/UhuruSoftware/private-uhuru-commander"
git_ttyjs="https://${git_user}:${git_password}@github.com/UhuruSoftware/private-ttyjs"
git_cf_release="https://${git_user}:${git_password}@github.com/UhuruSoftware/private-cf-release"

git_bosh_commit=""
git_commander_commit=""
git_ttyjs_commit=""
git_cf_release_commit=""

ftp_user="jira"
ftp_password="uhuruservice1234!"
ftp_host="192.168.1.136"

vsphere_host="192.168.1.114"
vsphere_user="administrator"
vsphere_password="password1234!"
vm_folder="mcalin_vms"
template_folder="mcalin_templates"
disk_path="mcalin_deployer"
datastore="flash"
datacenter="uhuru"
cluster="Staging"
version="1.0.15"

windows_stemcell="uhuru-windows-2008R2-vsphere-0.9.5.tgz"
windows_sql_stemcell="uhuru-windows-2008R2-sqlserver-vsphere-0.9.5.tgz"
linux_stemcell="bosh-stemcell-vsphere-1.5.0.pre.3.tgz"
linux_php_stemcell="bosh-stemcell-php-vsphere-1.5.0.pre.3.tgz"

color_black="\e[0;30m"
color_dark_gray="\e[1;30m"
color_blue="\e[0;34m"
color_light_blue="\e[1;34m"
color_green="\e[0;32m"
color_light_green="\e[1;32m"
color_cyan="\e[0;36m"
color_light_cyan="\e[1;36m"
color_red="\e[0;31m"
color_light_red="\e[1;31m"
color_purple="\e[0;35m"
color_light_purple="\e[1;35m"
color_brown="\e[0;33m"
color_yellow="\e[1;33m"
color_light_gray="\e[0;37m"
color_white="\e[1;37m"
color_normal="\e[00m"

function param_present()
{
    echo ${@:2} | grep $1 >> /dev/null && return 0 || return 1
}


