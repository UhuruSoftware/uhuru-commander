#!/bin/sh


cd ../../modules/private-cf-release

DEV_RELEASES_FOLDER=$(readlink -f "./dev_releases")
UCC_PLUGIN_FOLDER=$(readlink -f "./ucc-plugin")
PUBLISHER_FOLDER=$(readlink -f "../../publisher")
WEBUI_FOLDER=$(readlink -f "../../web-ui")

rm -rf /tmp/appcloud/bits.tgz

mkdir -p /tmp/appcloud

rm -rf ${DEV_RELEASES_FOLDER}/*

CWD=`pwd`
echo "Release dir is: ${CWD}"

export BUNDLE_GEMFILE=${WEBUI_FOLDER}/Gemfile

echo "Gemfile is: ${BUNDLE_GEMFILE}"

bundle exec bosh --non-interactive create release --with-tarball --force

mv `ls ${DEV_RELEASES_FOLDER}/*.tgz` ${DEV_RELEASES_FOLDER}/release.tgz
rm -rf ${DEV_RELEASES_FOLDER}/*.yml

cp -r ${UCC_PLUGIN_FOLDER}/* ${DEV_RELEASES_FOLDER}/

erb ${DEV_RELEASES_FOLDER}/plugin.rb.erb > ${DEV_RELEASES_FOLDER}/plugin.rb
rm ${DEV_RELEASES_FOLDER}/plugin.rb.erb

sed -i -e 's/###ucc_product_version###/1.1.0.a.a/g' ${DEV_RELEASES_FOLDER}/config/appcloud.yml.erb

tar -czvf /tmp/appcloud/bits.tgz -C ${DEV_RELEASES_FOLDER} .


WINDOWS_STEMCELLS="1.0.0, 1.0.1, 1.0.2"
WINDOWS_SQL_STEMCELLS="1.0.0, 1.0.1, 1.0.2"
LINUX_STEMCELLS="1.0.0, 1.0.1, 1.0.2"


export BUNDLE_GEMFILE=${PUBLISHER_FOLDER}/Gemfile

cd ${PUBLISHER_FOLDER}/bin/

./publisher upload version -n appcloud -r 1.1.0.a.a -t alpha -d "Fixed SSH connection to VMs and MongoDB." -f /tmp/appcloud/bits.tgz


./publisher add dependency -n appcloud -r 1.1.0.a.a -d bosh-stemcell-php -s 1.5.0.pre.4
./publisher add dependency -n appcloud -r 1.1.0.a.a -d uhuru-windows-2008R2 -s 0.9.11
./publisher add dependency -n appcloud -r 1.1.0.a.a -d uhuru-windows-2008R2-sqlserver -s 0.9.11

