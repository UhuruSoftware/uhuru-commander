#!/bin/bash

[ `id -u` -ne 0 ] &&
  {
  echo "You are not root"
#  exit 1
  }



trap abusive_interruption SIGINT

echo "Checking for necessary packages..."
dpkg -s dialog 1>/dev/null 2>/dev/null || sudo apt-get install dialog
dpkg -s ipcalc 1>/dev/null 2>/dev/null || sudo apt-get install ipcalc

[ ! -z "`cat /etc/lsb-release|grep 'DISTRIB_RELEASE=10.'`" ] && 
  {
  dpkg -s mkpasswd 1>/dev/null 2>/dev/null || sudo apt-get install mkpasswd
  } || 
  {
  dpkg -s whois 1>/dev/null 2>/dev/null || sudo apt-get install whois
  }

bgtitle="Uhuru Software"
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
version_bosh_cli=1.0.2
version_cloudfoundry=119
version_bosh=10

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
help_datacenter_vmfolder="The vCenter folder that is going to hold the deployment VMs. This folder must exist and be accessible."
help_datacenter_templatefolder="The vCenter folder that is going to hold the templates used for deploying. This folder must exist and be accessible."
help_datacenter_bosh_diskpath="The Datastore folder that is going to contain the necessary  files used by bosh. This folder must exist in the appropriate datastores"
help_datacenter_micro_diskpath="The Datastore folder that is going to contain the necessary  files used by micro bosh. This folder must exist in the appropriate datastores"
help_datacenter_datastorepattern="The pattern for the datastore that is going to contain the non-persistent disks."
help_datacenter_persistentpattern="The pattern for the datastore that is going to contain the persistent disks."
help_datacenter_mixeddatastores="Are mixed datastores allowed ?"
help_datacenter_deployer_diskpath="The Datastore folder that is going to contain the necessary  files used by the deployer. This folder must exist in the appropriate datastores"

help_datacenter_host="vCenter IP address"
help_datacenter_user="The vCenter user"
help_datacenter_password="The password tor the vCenter user"
help_datacenter_cluster_name="The vCenter Cluster name on witch cloud foundry is going to be deployed to"

progress_success="INSTALLED"
progress_failure="FAILURE"
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

  $bosh login admin admin
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
  --menu "\nPlease input the network subnet, the network mask and the gateway.\nThe netmask must be at least a /24 (255.255.255.0),\nbut we recomend using a /16 (255.255.0.0).\nThe network must end in '.0'" 12 0 0 \
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
    "Subnet") inputbox "Subnet" "Enter an unused subnet. It will hold the Cloud Foundry deployment. Its strongly recomended that you use a /16 subnet." "$conf_network" && validate_subnet `cat $tmpdir/input.out` &&
      {
      conf_network=`cat $tmpdir/input.out`
      calc_bosh_ips
      calc_cloudfoundry_ips
      } ;;
    "Netmask") inputbox "Netmask" "Enter the netmask for the Cloud Foundry subnet. Its strongly recomended that you use a /16 subnet (255.255.0.0) " "$conf_network_netmask" && validate_ip `cat $tmpdir/input.out` && conf_network_netmask=`cat $tmpdir/input.out` ;;
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

#msgbox "this is the vsphere help\nit will describe something\nquite important"
textbox "Necessary permissions" $pwd/resources/permissions.txt

while [ $ret -eq 0 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " VCenter configuration " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --item-help \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 10 0 0 \
  "vCenter IP" "$conf_vcenter_host" "$help_datacenter_host" \
  "vCenter user" "$conf_vcenter_user" "$help_datacenter_user" \
  "Password" "<hidden>" "$help_datacenter_password" \
  "Cluster Name" "$conf_vcenter_clustername" "$help_datacenter_cluster_name" \
  "Datacenter name" "$conf_datacenter_name" "$help_datacenter_name" \
  "VM Folder" "$conf_datacenter_vmfolder" "$help_datacenter_vmfolder" \
  "Template Folder" "$conf_datacenter_templatefolder" "$help_datacenter_templatefolder" \
  " " " " " " \
  "Deployer Disk Path" "$conf_datacenter_deployer_diskpath" "$help_datacenter_deployer_diskpath" \
  "Micro Disk Path" "$conf_datacenter_micro_diskpath" "$help_datacenter_micro_diskpath" \
  "Bosh Disk Path" "$conf_datacenter_bosh_diskpath" "$help_datacenter_bosh_diskpath" \
  "Datastore Pattern" "$conf_datacenter_datastorepattern" "$help_datacenter_datastorepattern" \
  "Persistent Datastore Pattern" "$conf_datacenter_persistentpattern" "$help_datacenter_persistentpattern" \
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
    "Deployer Disk Path") inputbox "Disk path" "$help_datacenter_deployer_diskpath" "$conf_datacenter_deployer_diskpath" && conf_datacenter_deployer_diskpath=`cat $tmpdir/input.out` ;;
    "Micro Disk Path") inputbox "Disk path" "$help_datacenter_micro_diskpath" "$conf_datacenter_micro_diskpath" && conf_datacenter_micro_diskpath=`cat $tmpdir/input.out` ;;
    "Bosh Disk Path") inputbox "Disk path" "$help_datacenter_bosh_diskpath" "$conf_datacenter_bosh_diskpath" && conf_datacenter_bosh_diskpath=`cat $tmpdir/input.out` ;;
    "Datastore Pattern") inputbox "Datastore pattern" "$help_datacenter_datastorepattern" "$conf_datacenter_datastorepattern" && conf_datacenter_datastorepattern=`cat $tmpdir/input.out` ;;
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
  --item-help \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 9 0 0 \
  "Name" "$conf_datacenter_name" "$help_datacenter_name" \
  "VM-Folder" "$conf_datacenter_vmfolder" "$help_datacenter_vmfolder" \
  "Template-Folder" "$conf_datacenter_templatefolder" "$help_datacenter_templatefolder" \
  "Micro-Disk-Path" "$conf_datacenter_micro_diskpath" "$help_datacenter_diskpath" \
  "Bosh-Disk-Path" "$conf_datacenter_bosh_diskpath" "$help_datacenter_diskpath" \
  "Datastore-Pattern" "$conf_datacenter_datastorepattern" "$help_datacenter_datastorepattern" \
  "Persistent-Pattern" "$conf_datacenter_persistentpattern" "$help_datacenter_persistentpattern" \
  "Mixed-Datastores" "$conf_datacenter_mixeddatastores" "$help_datacenter_mixeddatastores" \
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

function print_ips()
{
msgbox " Information " "Please keep this information :\n
\n
VCenter username : $conf_vcenter_user\n
VCenter password : $conf_vcenter_password\n
VCenter host     : $conf_vcenter_host\n
\n
MicroBOSH IP     : $conf_bosh_micro_ip\n
NATS      IP     : $conf_bosh_nats_ip\n
Postgres  IP     : $conf_bosh_postgres_ip\n
Redis     IP     : $conf_bosh_redis_ip\n
Director  IP     : $conf_bosh_director_ip\n
Blobstore IP     : $conf_bosh_blobstore_ip\n
\n
Network          : $conf_network\n
Netmask          : $conf_network_netmask\n
Gateway          : $conf_network_gateway\n
\n
You can always review bosh.yml and micro_bosh.yml
"
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

function deploy_main_menu()
{
local ret=0
local sel="Everything"

while [ $ret -eq 0 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Deploy $deployment " \
  --default-item "$sel" \
  --cancel-label "Back" \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 9 0 0 \
  "Everything" "Deploy everything" \
  "Packages" "Install system packages" \
  "Micro-Stemcell" "Install micro stemcell" \
  "Bosh-Stemcell" "Download BOSH stemcell" \
  "Deploy-Micro" "Deploy micro bosh" \
  "Upload-BOSH" "Upload BOSH stemcell" \
  "Get-BOSH" "Get latest BOSH" \
  "Deploy-BOSH" "Deploy BOSH" \
  2>$tmpdir/deploy_main_menu.out
  ret=$?

  sel=`cat $tmpdir/deploy_main_menu.out`
  rm -f $tmpdir/deploy_main_menu.out

  [ $ret -eq 0 ] &&
    {
    case "$sel" in
    "Packages") install_packages_gui ;;
    "Micro-Stemcell") install_micro_stemcell_gui ;;
    "Bosh-Stemcell") download_bosh_stemcell_gui ;;
    "Deploy-Micro") deploy_micro_bosh_gui ;;
    "Upload-BOSH") upload_bosh_stemcell_gui ;;
    "Get-BOSH") get_latest_bosh_gui ;;
    "Deploy-BOSH") deploy_bosh_gui ;;
    esac
    }
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
  --extra-label "Save&Deploy" \
  --help-button \
  --help-label "Back" \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 9 0 0 \
  "Network" "Configure basic network settings" \
  "Domain" "Set up the domain name" \
  "vSphere" "Configure vSphere settings" \
  "Cloud Foundry components" "Configure the number of VMs" \
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
  --extra-label "Save&Deploy" \
  --help-button \
  --help-label "Back" \
  --menu "\nSelect which item you want to configure.\nIn the right column you see the current value." 10 0 0 \
  "Network" "Configure basic network settings" \
  "Domain" "Set up the domain name" \
  "vSphere" "Configure vSphere settings" \
  "Cloud Foundry components" "Configure the number of VMs" \
  "Uhuru" "Configure Uhuru cloud settings" \
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
      "Domain") inputbox "Domain" "Enter a valid domain used for Cloud Foundry" "$cloudfoundry_domain" && cloudfoundry_domain=`cat $tmpdir/input.out` ;;
      "Uhuru") configure_uhuru ;;
    esac ;;
    3) confirm_install && install_steps ;;
    1) save_conf
       msgbox "Settings saved" ;;
  esac
done

}

echo "Loading program functions..."
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

[ "$1" == "-x" ] && mode="advanced" || mode="basic"

mode="basic"
case "$1" in
  "-x"|"--advanced") mode=advanced ;;
  "-s"|"--setup") install_packages ;;
esac

select_deployment

cleanup
