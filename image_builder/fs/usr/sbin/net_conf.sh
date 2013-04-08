#!/bin/bash
dialog=`which dialog`
tmpdir="/var/tmp"

bgtitle="Network configuration"
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

[ -e /root/passwd.lock ] &&
{
    clear
    echo "Please input a new password for user 'vcap':"
    passwd vcap &&
    {
        rm /root/passwd.lock
    } ||
    {
        echo -n "Press ENTER to continue"
        read
        exit 1
    }
}

function validate_ip()
{
  local ret=1

  case "$*" in
    ""|*[!0-9.]*|*[!0-9]) return 1 ;;
  esac

  local IFS=.
  set -- $*

  [ $# -eq 4 ] && [ ${1:-300} -le 255 ] && [ ${2:-300} -le 255 ] && [ ${3:-300} -le 255 ] && [ ${4:-300} -le 255 ] && ret=0

  [ $ret -ne 0 ] && msgbox "Invalid IP" "This is not a valid IP address."

  return $ret
}

function validate_subnet()
{
  local ret=1

  case "$*" in
    ""|*[!0-9.]*|*[!0-9]) return 1 ;;
  esac

  local IFS=.
  set -- $*

  [ $# -eq 4 ] && [ ${1:-300} -le 255 ] && [ ${2:-300} -le 255 ] && [ ${3:-300} -eq 0 ] && [ ${4:-300} -eq 0 ] && ret=0

  [ $ret -ne 0 ] && msgbox "Invalid subnet" "Please enter a subnet which ends with '.0.0'"

  return $ret
}

function infobox()
{
  local msg title
  [ $# -eq 1 ] &&
    {
    title="Information"
    msg=$1
    } ||
    {
    title=$1
    msg=$2
    }

  $dialog --backtitle "$bgtitle" --title " $title " --infobox "\n${msg}\n\n" 0 0
}

function yesno()
{
  local msg title
  [ $# -eq 1 ] &&
    {
    title="Question"
    msg=$1
    } ||
    {
    title=$1
    msg=$2
    }

  $dialog --backtitle "$bgtitle" --title " $title " --yesno "\n${msg}\n\n" 0 0
}

function msgbox()
{
  local msg title
  [ $# -eq 1 ] &&
    {
    title="Message"
    msg=$1
    } ||
    {
    title=$1
    msg=$2
    }

  $dialog --backtitle "$bgtitle" --title " $title " --msgbox "\n${msg}\n\n" 0 0
}

function textbox()
{
  lines=`tput lines`
  cols=`tput cols`

  $dialog --backtitle "$bgtitle" --title " $1 " --textbox $2 $(( $lines - 4 )) $(( $cols - 6 ))
}

function inputbox()
{
  local msg title default
  [ $# -eq 1 ] &&
    {
    title="Input text"
    msg=$1
    default=""
    } ||
    {
    title=$1
    msg=$2
    default=$3
    }

  $dialog --backtitle "$bgtitle" --title " $title " --inputbox "\n${msg}\n\n" 0 0 "$default" 2>$tmpdir/input.out
}

function passwordbox()
{
  local pass

  $dialog --backtitle "$bgtitle" --title " $1 " --insecure --passwordbox "\nPlease enter password\n\n" 0 0 2>$tmpdir/password.out &&
    {
    pass=`cat $tmpdir/password.out`
    $dialog --backtitle "$bgtitle" --title " $1 " --insecure --passwordbox "\nEnter password again\n\n" 0 0 2>$tmpdir/password.out

    [ "`cat $tmpdir/password.out`" != "$pass" ] &&
      {
      msgbox "The passwords don't match"
      return 1
      } ||
      {
      return 0
      }
    } || return 1
}

function static_ip_change()
{

local ret=0
local interface=`ifconfig -a|grep ^eth|cut -f 1 -d " "|head -n 1`
local sel="IP"

until [ ! -z "$interface" ];
  do
  msgbox "There is no network interface present."
  interface=`ifconfig -a|grep ^eth|cut -f 1 -d " "|head -n 1`
  done

local_network_ip=`ifconfig|grep -w inet|grep -v 127.0.0.1|cut -f 2 -d \:|cut -f 1 -d \ `
local_network_netmask=`ifconfig|grep -w inet|grep -v 127.0.0.1|cut -f 4 -d ":"|cut -f 1 -d " "`
local_network_gateway=`route -n|grep ^0.0.0.0|awk '{print $2}'`
local_network_dns=`cat /etc/resolv.conf|grep ^nameserver|head -n 1|awk '{print $2}'`

[ -z "$local_network_ip" ] &&
  {
  local_network_ip="192.168.0.200"
  local_network_netmask="255.255.255.0"
  local_network_gateway="192.168.0.1"
  local_network_dns="8.8.8.8"
  }

while [ $ret -ne 1 ];
do
  $dialog --backtitle "$bgtitle" \
  --title " Local network configuration " \
  --default-item "$sel" \
  --ok-label "Change" \
  --cancel-label "Revert" \
  --colors \
  --extra-button \
  --extra-label "Apply" \
  --menu \
  "\nConfigure local network settings.\n
Please note that you can only use static network settings.\n
${color_magenta}${color_reverse}!!!IMPORTANT!!!${color_normal}${color_red}If you've already setup 'Infrastructure' in the Web Interface, changing network settings will break your existing cloud deployments.$color_normal" 12 0 0 \
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
    1) return ;;
    3) local_network_broadcast=`ipcalc ${local_network_ip}/${local_network_netmask}|grep Broadcast|cut -f 2 -d " "`
    echo "Applying new settings"
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
    echo "nameserver $local_network_dns" >/etc/resolv.conf
    /etc/init.d/networking restart
    /usr/sbin/change_ips.sh
    echo "Press ENTER to reboot"
    read
    reboot
    ;;
  esac
done
}


while true;
do
  static_ip_change
done
