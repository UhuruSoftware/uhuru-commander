#!/bin/bash

local_ip=`ifconfig eth0|grep -w inet|cut -f 2 -d ":"|cut -f 1 -d " "`
PATH="/var/vcap/bosh/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin"
TERM="xterm"

cd /var/vcap/store

function install_packages()
{
apt-get update
apt-get -y install git-core ftp zerofree postgresql-client gpm dialog ipcalc

gem install -r bosh_cli
gem install -r rake -v 10.0.3
gem install -r addressable -v 2.3.2
gem install -r mime-types -v 1.20.1
gem install -r bosh_common -v 0.5.4
gem install -r httpclient -v 2.3.2
gem install -r json_pure -v 1.7.6

}
function configure_ssh()
{
mkdir /root/.ssh
chmod 700 /root/.ssh

touch /root/.ssh/id_rsa
cat <<EOF > /root/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuY8bS9DeEfnp6MVW0yy1Ij/TsyO+ZrSN741YW1cakWlLhhqY
Uc7QoejHeifgDShDGznnZHxk0AXD2BfJ7SCkMZu8zEPApVx2I34GZG3TM4b7pbCe
V6E0nbEKxP+goSqOekSU/icsFifFflcjoTpjgO1HJxA7i/oONKS1IXN3tJdWolDP
bPJp7n8bes/Bxb39JPVwUojK5ocJ5lDoJFT1HoLhiDO3uCoNu9xGJEDxPD70WYC9
mu6iyBjgenExZaaBG9fS89OMDWzIXne7cKc/XNDa9SbeZMPE8qtdFLJIRG7gv84V
bV8Tg6lPrus2osjCJ7XGOcUe9Bl7/l6Vw7UWIwIBIwKCAQEAmb+3h/Y0WAmV7MDE
SJLB9858NVghawqhfVfbfuHFjm0v8sWUJobKH8Dfy51h3wQaWGMtcIRTh8pDL2Qq
961U2KWcbrvLgbMCzPNkYddXOVKV/lCDMqokSCT6S3S4SwYBBjjTOPvis0WGYV4k
1gvOyeksU5EbZVopBwwhDRaHwYNKDqyimBJxARfbuY9Epvky/lGvt4Fc+t7Tqs3k
mZWxBd6mU8cjDk9HWAmU3+xUIUe20yMo0oAeAdOEPg/rW4MXXkFuzVp/+jrTH7w4
ap7pga1sUZ5SvNdVtXRTpMKJmCTDU0WBBaN0xtpoUSATsIExnboNJcCLMQW0nI6i
HPtVCwKBgQDzvxfKXT7HPD0+PR8EdzzJjF6KsC+V2Q875vnipl9mTpHDuxnlMQfS
QFYpXO8hTFs+k9RMsS7p8pPYctidZ0ekQUdUrd/yjt4bBizq+B5ezFEmuNbGy/YV
qKxMMbCtMN9T8dWQpkBRhP6Jvym8ZzLagtEraKGulMudmAMBKYShQQKBgQDC4yrf
uUUaT9WfFx5P975f+7i5SUpSE6irOgZBCzgRcJTz9TsjziOnla+DlcHUVPcW6im7
OyUZCEf1qwnHY8l6B7RH/qmvly0y9DKvsTvYZsAOMhVtHtKgH40nhhbRtDcK/4om
2sw94oix98bm4iYehW39tTsPANQ5YsnrbmI6YwKBgQDl0W4z1EKBVg3bmLbYUyqv
ZxdPkCzdvgcMl/LrpC4QAO/VzaqzhgAPYTtLkiNLR/5CUN4cbItRm5K2IyQCH4yw
z9WKWsvWEazXpryjBzKT5TaSOT+IPKYxranELtnH3Z9dxsIMCncoSjHSVSdZ3aT5
6Q5cINL1D/MuMD1Y3gC1SwKBgQCyLsgdASk8oMNPoBu20+FB0DPcmsebf7AnhYIP
lTqTmiHJGrm6VhH4TldTvB7uBIojlENpWqWTOsVy5YVIlb+Fg2L//scG8J5aeN3i
digWT1CCAee0OXAdXqzw75/VrBURXqoyJyEiozsmXuG9JolAef4pykSgAMIIlNXe
kM7WSwKBgA8qHX4KwwJWAWGZ4pSBMp6jWjVACNVtx2zt+O9f1rj7AgZh7kDnOPqr
TFL0QQP2qZSLI53JpaV3soDnd+BypAx5YBGFZuX/cWK1REZ3iL+mFt8wxo2ZO6d9
uCGbvpnb1sO/7iQBY6j4TKs44IzhhJnvggI28MxhKggwDvRVdkMy
-----END RSA PRIVATE KEY-----
EOF

chmod 600 /root/.ssh/id_rsa

touch /root/.ssh/id_rsa.pub
cat <<EOF > /root/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuY8bS9DeEfnp6MVW0yy1Ij/TsyO+ZrSN741YW1cakWlLhhqYUc7QoejHeifgDShDGznnZHxk0AXD2BfJ7SCkMZu8zEPApVx2I34GZG3TM4b7pbCeV6E0nbEKxP+goSqOekSU/icsFifFflcjoTpjgO1HJxA7i/oONKS1IXN3tJdWolDPbPJp7n8bes/Bxb39JPVwUojK5ocJ5lDoJFT1HoLhiDO3uCoNu9xGJEDxPD70WYC9mu6iyBjgenExZaaBG9fS89OMDWzIXne7cKc/XNDa9SbeZMPE8qtdFLJIRG7gv84VbV8Tg6lPrus2osjCJ7XGOcUe9Bl7/l6Vw7UWIw== calin.miclaus@gmail.com
EOF

touch /root/.ssh/known_hosts
cat <<EOFasd > /root/.ssh/known_hosts
|1|0knjkQJOlQU86TGov8DAZt5IdKg=|q2U+Ac7rD4aZvGtTuscxKE758OI= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
|1|IPz5X+pnhfGNIXZHtf6dCD67zfc=|fs34lMLesOmJhsgfXH6+FdNKjsg= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOFasd
}

function get_commander()
{
pwd=`pwd`
cd /root
git clone git@github.com:UhuruSoftware/private-uhuru-commander

mkdir /var/vcap/store/ucc
mv private-uhuru-commander/* /var/vcap/store/ucc/
rm -rf private-uhuru-commander

cd /var/vcap/store/ucc/web-ui/config
rm -f /var/vcap/store/ucc/web-ui/config/infrastructure.yml

sed -i s/192.168.1.186/$local_ip/g uhuru-cloud-commander.yml
sed -i s/10.134.0.133/$local_ip/g uhuru-cloud-commander.yml

cd /var/vcap/store/ucc/web-ui/bin
bundle install
cd $pwd
}


function stemcells()
{
pwd=`pwd`

echo "insert into users (username,password) values ('admin','\$2a\$10\$LafWwJHPLOOGNmn0fcGeX.PjLfB/p3kF/3tb.YmvXV6jkfAr1Nngq');;" | PGPASSWORD="postgres" psql -U postgres -h $local_ip -d bosh

bosh --user admin --password admin target localhost
bosh login admin admin

mount -o bind /var/vcap/data/tmp /tmp

cd /var/vcap/store/ucc/web-ui/resources

ftp -inv ftp.uhurusoftware.org<<ENDFTP
user jira uhuruservice1234!
cd bosh/stemcells
binary
passive
get uhuru-windows-2008R2-vsphere-0.9.5.tgz
get bosh-stemcell-vsphere-1.5.0.pre.3.tgz
get bosh-stemcell-php-vsphere-1.5.0.pre.3.tgz
get uhuru-windows-2008R2-sqlserver-vsphere-0.9.4.tgz
bye
ENDFTP

chmod 700 /tmp/director

bosh upload stemcell /var/vcap/store/ucc/web-ui/resources/uhuru-windows-2008R2-vsphere-0.9.5.tgz
bosh upload stemcell /var/vcap/store/ucc/web-ui/resources/bosh-stemcell-vsphere-1.5.0.pre.3.tgz
bosh upload stemcell /var/vcap/store/ucc/web-ui/resources/bosh-stemcell-php-vsphere-1.5.0.pre.3.tgz
bosh upload stemcell /var/vcap/store/ucc/web-ui/resources/uhuru-windows-2008R2-sqlserver-vsphere-0.9.4.tgz

git clone git@github.com:UhuruSoftware/private-cf-release.git
cd private-cf-release
./update

bosh --non-interactive create release --with-tarball
bosh upload release /var/vcap/store/ucc/web-ui/resources/private-cf-release/dev_releases/bosh-release-122.1-dev.tgz

cd $pwd
umount /var/vcap/data/tmp
}

function cleanup()
{
rm -f /root/.bash_history
rm -f /root/.ssh/*
rm -rf /var/vcap/data/tmp/*
rm -f /root/do_everything
rm -f /var/vcap/data/tmp/private-cf-release/dev_releases/bosh-release-122.1-dev.tgz
rm -f /root/commands.sql
rm -f /root/step_0_ion.yml
}

function configure_init()
{
chmod 777 /tmp

update-rc.d ucc defaults 99
update-rc.d ttyjs defaults 99

cat /etc/service/agent/run|grep -v "/var/vcap/bosh/agent/bin/agent" >/tmp/agent_run
echo '#exec /usr/bin/nice -n -10 /var/vcap/bosh/agent/bin/agent -c -I $(cat /etc/infrastructure)' >>/tmp/agent_run
mv -f /tmp/agent_run /etc/service/agent/run

echo "*/1 * * * * service ucc status || service ucc restart" >>/var/spool/cron/crontabs/root
echo "*/1 * * * * service ttyjs status || service ttyjs restart" >>/var/spool/cron/crontabs/root
}

function deploy_cf()
{
echo "update releases set name='app-cloud' where id=1;" | PGPASSWORD="postgres" psql -U postgres -h $local_ip -d bosh

uuid=`bosh status|grep UUID|awk '{print $2}'`
sed -i s/REPLACEME/$uuid/g /root/step_0_ion.yml

bosh deployment /root/step_0_ion.yml
bosh --non-interactive deploy || bosh --non-interactive deploy || bosh --non-interactive deploy || bosh --non-interactive deploy || bosh --non-interactive deploy || bosh --non-interactive deploy || bosh --non-interactive deploy
}

function install_tty_js()
{
cwd=`pwd`

cd /tmp
mkdir nodejs
cd nodejs
wget -N http://nodejs.org/dist/node-latest.tar.gz
tar xzvf node-latest.tar.gz && cd `ls -rd node-v*`
./configure
make install

cd ${cwd}/nodejs
wget http://npmjs.org/install.sh  --no-check-certificate
bash install.sh

git clone git@github.com:UhuruSoftware/private-tty.js
mkdir /var/vcap/store/ucc/tty.js
mv private-tty.js/* /var/vcap/store/ucc/tty.js/

cd /var/vcap/store/ucc/tty.js/
npm install

cd $cwd
}

function do_sql()
{
PGPASSWORD="postgres" cat /root/commands.sql | PGPASSWORD="postgres" psql -U postgres -h $local_ip -d bosh
}

function zerofree()
{
cd /root
monit stop all
sleep 60
umount /tmp
umount /dev/sdc1
zerofree /dev/sdc1
umount /dev/loop0
umount /dev/sdb2
zerofree /dev/sdb2
}

install_packages
configure_ssh
get_commander
stemcells
configure_init
deploy_cf
do_sql
#cleanup
#zerofree
