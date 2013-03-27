#!/bin/bash

user="vcap"
password="c1oudc0w"
ip="10.150.0.150"


function deploy_micro()
{
  rm deployments/bosh-deployments.yml

  cat deployments/micro_bosh/micro_bosh.yml.orig|sed s/10.150.0.69/$ip/g >deployments/micro_bosh/micro_bosh.yml

  cd deployments
  echo "Downloading BOSH micro stemcell"

  [ -e micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz ] ||
    {
#    bosh download public stemcell micro-bosh-stemcell-vsphere-0.8.1.tgz
    bosh download public stemcell micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz

    }

  echo "Running: bosh micro deployment micro_bosh"
  bosh micro deployment micro_bosh

  echo "Running: bosh micro deploy micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz"
#  bosh -n micro deploy micro-bosh-stemcell-vsphere-0.8.1.tgz || bosh -n micro deploy micro-bosh-stemcell-vsphere-0.8.1.tgz --update
  bosh -n micro deploy micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz || bosh -n micro deploy micro-bosh-stemcell-nagios-vsphere-0.8.1.1.tgz --update
  cd ..
}

function upload_files()
{
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bk

  sshpass -p $password scp -o StrictHostKeyChecking=no build.sh                     ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no compilation_manifest.yml     ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no fs/etc/init.d/ucc            ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no fs/etc/init.d/ttyjs          ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no fs/etc/rc.local              ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no fs/usr/sbin/change_ips.sh    ${user}@${ip}:/tmp
  sshpass -p $password scp -o StrictHostKeyChecking=no fs/usr/sbin/net_conf.sh      ${user}@${ip}:/tmp

  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/build.sh                   /root/"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/compilation_manifest.yml   /root/"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/ucc                        /etc/init.d"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/ttyjs                      /etc/init.d"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/rc.local                   /etc"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/change_ips.sh              /usr/sbin/"
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S mv /tmp/net_conf.sh                /usr/sbin/"

  mv ~/.ssh/known_hosts.bk ~/.ssh/known_hosts
}

function start_stuff()
{
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bk
  sshpass -p $password ssh -o StrictHostKeyChecking=no ${user}@${ip} "echo $password|sudo -S /root/build.sh"
  mv ~/.ssh/known_hosts.bk ~/.ssh/known_hosts
}

deploy_micro
upload_files
start_stuff
