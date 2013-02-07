#!/bin/bash

[ `id -u` -ne 0 ] &&
  {
  echo "You are not root"
  exit 1
  }

#TERM=linux

trap abusive_interruption SIGINT

dpkg -s dialog 1>/dev/null 2>/dev/null || sudo apt-get install dialog
dpkg -s ipcalc 1>/dev/null 2>/dev/null || sudo apt-get install ipcalc

[ ! -z "`cat /etc/lsb-release|grep 'DISTRIB_RELEASE=10.'`" ] && 
  {
  dpkg -s mkpasswd 1>/dev/null 2>/dev/null || sudo apt-get install mkpasswd
  } || 
  {
  dpkg -s whois 1>/dev/null 2>/dev/null || sudo apt-get install whois
  }

bgtitle="Uhuru Software Cloud Commander"
bosh="/usr/local/ruby/bin/bosh"
bosh_nonint="/usr/local/ruby/bin/bosh --non-interactive"
pid=$$
pwd=`pwd`
tmpdir="`mktemp -d`"
lines=`tput lines`
cols=`tput cols`
deployments=".uhuru-deployments"

function vars()
{
dialog=`which dialog`
color_black="\Z0"
color_red="\Z1"
color_green="\Z2"
color_yellow="\Z3"
color_blue="\Z4"
color_magenta="\Z5"
color_cyan="\Z6"
color_white="\Z7"
color_normal="\Zn"
color_bold="\Zb"
color_no_bold="\ZB"
color_reverse="\Zr"
color_no_reverse="\ZR"
color_underline="\Zu"
color_no_underline="\ZU"
uuid=""

help_micro_persistent="This represents the total amount of disk space (MB) to be persisted."
help_micro_memory="This represents the amount of RAM (MB) to be reserved for Micro BOSH."
help_micro_disk="This represents the amount of disk space (MB) to be reserved for Micro BOSH."
help_micro_cpu="This represents the number of CPUs to be alocated for Micro BOSH."

help_datacenter_name="The name of the vCenter datacenter used for Cloud Foundry"
help_datacenter_vmfolder="The vCenter folder that is going to hold the deployment VMs. This folder must exist and be accessible"
help_datacenter_templatefolder="The vCenter folder that is going to hold the templates used for deploying. This folder must exist and be accessible"
help_datacenter_bosh_diskpath="The Datastore folder that is going to contain the necessary files used by bosh. This folder must exist in the appropriate datastore"
help_datacenter_micro_diskpath="The Datastore folder that is going to contain the necessary files used by micro bosh. This folder must exist in the appropriate datastore"
help_datacenter_datastorepattern="The pattern for the datastore that is going to contain the non-persistent disks."
help_datacenter_persistentpattern="The pattern for the datastore that is going to contain the persistent disks."
help_datacenter_mixeddatastores="Are mixed datastores allowed ?"
help_datacenter_deployer_diskpath="The Datastore folder that is going to contain the necessary files used by the deployer. This folder must exist in the appropriate datastore"

help_datacenter_host="vCenter IP address"
help_datacenter_user="The vCenter user"
help_datacenter_password="The password for the vCenter user"
help_datacenter_cluster_name="The vCenter Cluster name on which cloud foundry is going to be deployed to"

progress_success="INSTALLED"
progress_failure="NOT INSTALLED"
progress_install_packages="not done yet"
progress_install_micro_stemcell="not done yet"
progress_download_bosh_stemcell="not done yet"
progress_deploy_micro_bosh="not done yet"
progress_upload_bosh_stemcell="not done yet"
progress_get_latest_bosh="not done yet"
progress_deploy_bosh="not done yet"
}

function abusive_interruption()
{
reset
clear
echo "Ouch! You're not playing nicely... I'm leaving..."
cleanup
exit 42
}

function get_bosh_uuid()
{
#  local ret=0
  rm -f ~/.bosh_config 2>/dev/null
  $bosh --user admin --password admin target ${conf_network_micro_ip}:25555 2>&1
  ret=$(( $ret + $? ))

  uuid=`$bosh status|grep UUID|awk '{print $2}'`
#  return $?
}

function set_bosh_uuid()
{
  [ -z "$uuid" -o ${#uuid} -lt 5 ] ||
    {
    sed -i s/"DO NOT CHANGE THIS STRING"/"$uuid"/g $pwd/.uhuru-deployments/$deployment/deployments/bosh/bosh.yml
#    sed -i s/"DO NOT CHANGE THIS STRING"/"$uuid"/g $pwd/.uhuru-deployments/$deployment/deployments/cloudfoundry/cloudfoundry.yml
    } ||
    {
    echo "Error replacing uuid in bosh.yml or cloudfoundry.yml"
    return 1
    }
}


function get_cloudfoundry_uuid()
{
#  local ret=0
  rm -f ~/.bosh_config 2>/dev/null
  $bosh --user admin --password admin target ${conf_bosh_director_ip}:25555
  ret=$(( $ret + $? ))

  uuid=`$bosh status|grep UUID|awk '{print $2}'`
#  return $?
}

function set_cloudfoundry_uuid()
{
  [ -z "$uuid" -o ${#uuid} -lt 5 ] ||
    {
#    sed -i s/"DO NOT CHANGE THIS STRING"/"$uuid"/g $pwd/.uhuru-deployments/$deployment/deployments/bosh/bosh.yml
    sed -i s/"DO NOT CHANGE THIS STRING"/"$uuid"/g $pwd/.uhuru-deployments/$deployment/deployments/cloudfoundry/cloudfoundry.yml
    } ||
    {
    echo "Error replacing uuid in bosh.yml or cloudfoundry.yml"
    return 1
    }
}

function deploy_bosh()
{
  local ret=0
  
  touch $tmpdir/deploy_bosh.lock
  
  echo "Deploying bosh"

  $bosh_nonint login admin admin
  ret=$(( $ret + $? ))

  $bosh deployment $pwd/.uhuru-deployments/$deployment/deployments/bosh/bosh.yml
  ret=$(( $ret + $? ))

  $bosh_nonint deploy 2>&1
  ret=$(( $ret + $? ))

  rm -f $tmpdir/deploy_bosh.lock

  return $ret
}


function configure_network()
{
local ret=0
local sel="Subnet"

while [ $ret -eq 0 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Network configuration " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nPlease input the network subnet, the network mask and the gateway.\nThe netmask must be at least a /16 (255.255.0.0),\nThe subnet must end in '.0.0'" 12 0 0 \
  "Subnet" "$conf_network" \
  "Netmask" "$conf_network_netmask" \
  "Gateway" "$conf_network_gateway" \
  "DNS1" "$conf_network_dns1" \
  "DNS2" "$conf_network_dns2" \
  "NTP1" "$conf_network_ntp1" \
  "NTP2" "$conf_network_ntp2" \
  2>$tmpdir/conf_network_menu.out
  ret=$?

  sel=`cat $tmpdir/conf_network_menu.out`
  rm -f $tmpdir/conf_network_menu.out

  [ $ret -eq 0 ] &&
    {
    case "$sel" in
    "Subnet") inputbox "Subnet" "Enter an unused subnet. It will hold the Cloud Foundry deployment. It's strongly recomended that you use a /16 subnet." "$conf_network" && validate_subnet `cat $tmpdir/input.out` &&
      {
      conf_network=`cat $tmpdir/input.out`
      calc_bosh_ips
      calc_cloudfoundry_ips
      } ;;
    "Netmask") inputbox "Netmask" "Enter the netmask for the Cloud Foundry subnet. It's strongly recomended that you use a /16 subnet (255.255.0.0) " "$conf_network_netmask" && validate_ip `cat $tmpdir/input.out` && conf_network_netmask=`cat $tmpdir/input.out` ;;
    "Gateway") inputbox "Gateway" "Enter the gateway IP address for the cloudfoundry subnet." "$conf_network_gateway" && validate_ip `cat $tmpdir/input.out` && conf_network_gateway=`cat $tmpdir/input.out` ;;
    "DNS1") inputbox "DNS 1" "Enter first DNS server" "$conf_network_dns1" && conf_network_dns1=`cat $tmpdir/input.out` ;;
    "DNS2") inputbox "DNS 2" "Enter second DNS server" "$conf_network_dns2" && conf_network_dns2=`cat $tmpdir/input.out` ;;
    "NTP1") inputbox "NTP 1" "Enter first Network Time Protocol server" "$conf_network_ntp1" && conf_network_ntp1=`cat $tmpdir/input.out` ;;
    "NTP2") inputbox "NTP 2" "Enter second Network Time Protocol server" "$conf_network_ntp2" && conf_network_ntp2=`cat $tmpdir/input.out` ;;
    esac
    rm -f $tmpdir/input.out
    }
done
}


function configure_vcenter()
{
local ret=0
local sel="Host"

textbox "Necessary permissions" $pwd/resources/permissions.txt

while [ $ret -eq 0 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " VCenter configuration " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 10 0 0 \
  "vCenter IP" "$conf_vcenter_host" \
  "vCenter user" "$conf_vcenter_user" \
  "Password" "<hidden>" \
  "Cluster Name" "$conf_vcenter_clustername" \
  "Datacenter name" "$conf_datacenter_name" \
  "VM Folder" "$conf_datacenter_vmfolder" \
  "Template Folder" "$conf_datacenter_templatefolder" \
  " " " " \
  "Datastore Pattern" "$conf_datacenter_datastorepattern" \
  2>$tmpdir/conf_vcenter_menu.out
  ret=$?

  sel=`cat $tmpdir/conf_vcenter_menu.out`
  rm -f $tmpdir/conf_vcenter_menu.out

  [ $ret -eq 0 ] &&
    {
    case "$sel" in
    "vCenter IP") inputbox "IP" "Enter VCenter host" "$conf_vcenter_host" && conf_vcenter_host=`cat $tmpdir/input.out` ;;
    "vCenter user") inputbox "Netmask" "Enter VCenter user" "$conf_vcenter_user" && conf_vcenter_user=`cat $tmpdir/input.out` ;;
    "Cluster Name") inputbox "Cluster name" "Enter cluster name" "$conf_vcenter_clustername" && conf_vcenter_clustername=`cat $tmpdir/input.out` ;;
    "Password") passwordbox "Enter the password for the vCenter user" && conf_vcenter_password=`cat $tmpdir/password.out`
      rm -f $tmpdir/password.out ;;
    "Datacenter") configure_datacenter ;;
    "Datacenter name") inputbox "Datacenter name" "$help_datacenter_name" "$conf_datacenter_name" && conf_datacenter_name=`cat $tmpdir/input.out` ;;
    "VM Folder") inputbox "VM Folder" "$help_datacenter_vmfolder" "$conf_datacenter_vmfolder" && conf_datacenter_vmfolder=`cat $tmpdir/input.out` ;;
    "Template Folder") inputbox "Templates folder" "$help_datacenter_templatefolder" "$conf_datacenter_templatefolder" && conf_datacenter_templatefolder=`cat $tmpdir/input.out` ;;
    "Datastore Pattern") inputbox "Datastore pattern" "$help_datacenter_datastorepattern" "$conf_datacenter_datastorepattern" &&
      {
      conf_datacenter_datastorepattern=`cat $tmpdir/input.out`
      conf_datacenter_persistentpattern=`cat $tmpdir/input.out`
      } ;;
    "Persistent Datastore Pattern") inputbox "Persistent pattern" "$help_datacenter_persistentpattern" "$conf_datacenter_persistentpattern" && conf_datacenter_persistentpattern=`cat $tmpdir/input.out` ;;
    "Mixed Datastores") $dialog --backtitle "$bgtitle" --title " Mixed datastores " --yesno "\n$help_datacenter_mixeddatastores\n" 8 0 && conf_datacenter_mixeddatastores="true" || conf_datacenter_mixeddatastores="false" ;;
    esac
    rm -f $tmpdir/input.out
    }
done
}


function configure_datacenter()
{
local ret=0
local sel="Name"

while [ $ret -eq 0 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Datacenter configuration " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 9 0 0 \
  "Name" "$conf_datacenter_name" \
  "VM-Folder" "$conf_datacenter_vmfolder" \
  "Template-Folder" "$conf_datacenter_templatefolder" \
  "Micro-Disk-Path" "$conf_datacenter_micro_diskpath" \
  "Bosh-Disk-Path" "$conf_datacenter_bosh_diskpath" \
  "Datastore-Pattern" "$conf_datacenter_datastorepattern" \
  "Persistent-Pattern" "$conf_datacenter_persistentpattern" \
  "Mixed-Datastores" "$conf_datacenter_mixeddatastores" \
  2>$tmpdir/conf_datacenter_menu.out
  ret=$?

  sel=`cat $tmpdir/conf_datacenter_menu.out`
  rm -f $tmpdir/conf_datacenter_menu.out

  [ $ret -eq 0 ] &&
    {
    case "$sel" in
    "Name") inputbox "Datacenter name" "$help_datacenter_name" "$conf_datacenter_name" && conf_datacenter_name=`cat $tmpdir/input.out` ;;
    "VM-Folder") inputbox "VM Folder" "$help_datacenter_vmfolder" "$conf_datacenter_vmfolder" && conf_datacenter_vmfolder=`cat $tmpdir/input.out` ;;
    "Template-Folder") inputbox "Templates folder" "$help_datacenter_templatefolder" "$conf_datacenter_templatefolder" && conf_datacenter_templatefolder=`cat $tmpdir/input.out` ;;
    "Micro-Disk-Path") inputbox "Disk path" "$help_datacenter_micro_diskpath" "$conf_datacenter_micro_diskpath" && conf_datacenter_micro_diskpath=`cat $tmpdir/input.out` ;;
    "Bosh-Disk-Path") inputbox "Disk path" "$help_datacenter_bosh_diskpath" "$conf_datacenter_bosh_diskpath" && conf_datacenter_bosh_diskpath=`cat $tmpdir/input.out` ;;
    "Datastore-Pattern") inputbox "Datastore pattern" "$help_datacenter_datastorepattern" "$conf_datacenter_datastorepattern" && conf_datacenter_datastorepattern=`cat $tmpdir/input.out` ;;
    "Persistent-Pattern") inputbox "Persistent pattern" "$help_datacenter_persistentpattern" "$conf_datacenter_persistentpattern" && conf_datacenter_persistentpattern=`cat $tmpdir/input.out` ;;
    "Mixed-Datastores") $dialog --backtitle "$bgtitle" --title " Mixed datastores " --yesno "\n$help_datacenter_mixeddatastores\n" 8 0 && conf_datacenter_mixeddatastores="true" || conf_datacenter_mixeddatastores="false" ;;
    esac
    rm -f $tmpdir/input.out
    }
done
}

function review_main_menu()
{
local ret=0 sel="Micro"
while [ $ret -ne 1 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Review deployment files " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nSelect which item you want to configure." 8 0 0 \
  "Micro" "Reviev micro_bosh.yml" \
  "Bosh" "Review bosh.yml" \
  "Cloudfoundry" "Review cloudfoundry.yml" \
  2>$tmpdir/review_main_menu.out
  ret=$?

  sel=`cat $tmpdir/review_main_menu.out`
  rm -f $tmpdir/review_main_menu.out

  case "$sel" in
  "Micro") edit_file $pwd/.uhuru-deployments/$deployment/deployments/micro_bosh/micro_bosh.yml ;;
  "Bosh") edit_file $pwd/.uhuru-deployments/$deployment/deployments/bosh/bosh.yml ;;
  "Cloudfoundry") edit_file $pwd/.uhuru-deployments/$deployment/deployments/cloudfoundry/cloudfoundry.yml ;;
  esac
done
}

function advanced_main_menu()
{
local ret=0 sel="Network"
while [ $ret -ne 1 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Deployment $deployment advanced main menu " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nSelect which item you want to configure." 8 0 0 \
  "Micro resources" "Fine tune micro-bosh resources" \
  "Bosh pools" "Fine tune bosh resource pools" \
  "Bosh IPs" "Fine tune bosh IPs" \
  " " " " \
  "Cloudfoundry domain" "Set the cloudfoundry domain" \
  "Cloudfoundry pools" "Edit cloudfoundry resource pools" \
  "Plans" "Edit service plans" \
  "Machines" "Edit the number of VM instances" \
  " " " " \
  "Review" "Review deployment yml files" \
  2>$tmpdir/advanced_main_menu.out
  ret=$?

  sel=`cat $tmpdir/advanced_main_menu.out`
  rm -f $tmpdir/advanced_main_menu.out

  case "$sel" in
  "Micro resources") configure_micro_resources ;;
  "Bosh pools") configure_bosh_resources ;;
  "Bosh IPs") configure_bosh_ips ;;
  "Review") review_main_menu  ;;
  "Cloudfoundry domain") inputbox "Domain" "The cloudfoundry domain" "$cloudfoundry_domain" && cloudfoundry_domain=`cat $tmpdir/input.out` ;;
  "Cloudfoundry pools") cloudfoundry_pools ;;
  "Plans") services_menu ;;
  "Machines") cloudfoundry_vms_count ;;
  esac
done
}

function configure_main_menu()
{
local ret=0
local sel="Network"

while [ $ret -ne 2 ];
do
  [ "$mode" == "advanced" ] &&
  {
  $dialog --backtitle "$bgtitle" \
  --title " Deployment $deployment main menu " \
  --default-item "$sel" \
  --cancel-label "Save" \
  --extra-button \
  --extra-label "Save and Deploy" \
  --help-button \
  --help-label "Back" \
  --menu "\nSelect which section you want to configure." 8 75 0 \
  "Network" "Configure basic network settings" \
  "Domain" "Set up the domain name" \
  "vSphere" "Configure vSphere settings" \
  "Cloud Foundry components" "Configure Cloud Foundry features" \
  "Advanced" "In depth settings" \
  2>$tmpdir/conf_main_menu.out
  ret=$?
  } ||
  {
  $dialog --backtitle "$bgtitle" \
  --title " Deployment $deployment main menu " \
  --default-item "$sel" \
  --cancel-label "Save" \
  --extra-button \
  --extra-label "Save and Deploy" \
  --help-button \
  --help-label "Back" \
  --menu "\nSelect which section you want to configure." 9 75 0 \
  "Network" "Configure basic network settings" \
  "Domain" "Set up the domain name" \
  "vSphere" "Configure vSphere settings" \
  "Cloud Foundry components" "Configure Cloud Foundry features" \
  "Uhuru cloud settings" "Configure Uhuru cloud settings" \
  2>$tmpdir/conf_main_menu.out
  ret=$?

  }
  sel=`cat $tmpdir/conf_main_menu.out`
  rm -f $tmpdir/conf_main_menu.out

  case $ret in
    0)
    case "$sel" in
      "Network") configure_network ;;
      "vSphere") configure_vcenter ;;
      "Cloud Foundry components") cloudfoundry_vms_count_simple ;;
      "Advanced") advanced_main_menu ;;
      "Domain") inputbox "Domain" "Enter a valid domain used for your cloud" "$cloudfoundry_domain" && 
	    {
		cloudfoundry_domain=`cat $tmpdir/input.out`
		cloudfoundry_srv_api_uri="api.$cloudfoundry_domain"
		
		} ;;
      "Uhuru cloud settings") configure_uhuru ;;
    esac ;;
    3) save_conf
       confirm_install && install_steps ;;
    1) save_conf
       msgbox "Settings saved" ;;
  esac
done
}

function local_network_config()
{
local ret=0 ret_type=0 net_type=""
local sel="IP"
local interface=`ifconfig -a|grep ^eth|cut -f 1 -d " "|head -n 1`

[ -z "$interface" ] &&
  {
  msgbox "There is no network interface present."
  return 1
  }

[ -z "$local_network_ip" ] &&
  {
  local_network_ip="192.168.0.200"
  local_network_netmask="255.255.255.0"
  local_network_gateway="192.168.0.1"
  local_network_dns="8.8.8.8"
  }

$dialog --backtitle "$bgtitle" \
	--title "Networking" \
	--cancel-label "Back" \
	--menu "Select a method of configuring the local network interface" 8 0 0 \
	"DHCP" "Get the ip address dynamically" \
	"Static" "Set up a static ip address" \
	2>$tmpdir/local_network_type.out
	ret_type=$?

[ $ret_type -eq 0 ] && 
  {
  net_type=`cat $tmpdir/local_network_type.out`
  rm -f $tmpdir/local_network_type.out
  } || 
  {
  rm -f $tmpdir/local_network_type.out
  return 1
  }

[ "$net_type" == "DHCP" ] &&
  {
  cat <<EOF>/etc/network/interfaces
auto lo
iface lo inet loopback

auto $interface
iface $interface inet dhcp
EOF

  ifconfig $interface up
  /etc/init.d/networking restart
  echo "Press ENTER to continue"
  read
  return 0
  }

while [ $ret -ne 1 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Local network configuration " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --extra-button \
  --extra-label "Apply" \
  --menu "\nConfigure the local network settings." 9 0 0 \
  "IP" "$local_network_ip" \
  "Netmask" "$local_network_netmask" \
  "Gateway" "$local_network_gateway" \
  "DNS" "$local_network_dns" \
  2>$tmpdir/local_network.out
  ret=$?

  sel=`cat $tmpdir/local_network.out`
  rm -f $tmpdir/local_network.out

  case $ret in
    0)
    case "$sel" in
      "IP") inputbox "IP" "Enter the Local IP Address" "$local_network_ip" && local_network_ip=`cat $tmpdir/input.out` ;;
      "Netmask") inputbox "Netmask" "Enter the Netmask for the local IP address" "$local_network_netmask" && local_network_netmask=`cat $tmpdir/input.out` ;;
      "Gateway") inputbox "Gateway" "Enter the Gateway Address" "$local_network_gateway" && local_network_gateway=`cat $tmpdir/input.out` ;;
      "DNS") inputbox "DNS" "Enter the IP address of a DNS server" "$local_network_dns" && local_network_dns=`cat $tmpdir/input.out` ;;
    esac ;;
    3) local_network_broadcast=`ipcalc ${local_network_ip}/${local_network_netmask}|grep Broadcast|cut -f 2 -d " "`
cat <<EOF>/etc/network/interfaces
auto lo
iface lo inet loopback

auto $interface
iface $interface inet static
address $local_network_ip
netmask $local_network_netmask
gateway $local_network_gateway
broadcast $local_network_broadcast
EOF
    echo "nameserver $local_network_dns" >>/etc/resolv.conf
    /etc/init.d/networking restart
    echo "Press ENTER to continue"
    read
    ;;
  esac
done
}

vars

. /etc/environment
. functions/general_functions
. functions/cloudfoundry_functions
. functions/bosh_functions
. functions/micro_functions
. functions/plans_functions
. functions/deployments_functions
. functions/install_functions
. functions/uhuru_functions

mode="basic"

case "$1" in
  "-x"|"--advanced") mode=advanced ;;
  "-s"|"--setup") install_packages ;;
esac

select_deployment

cleanup