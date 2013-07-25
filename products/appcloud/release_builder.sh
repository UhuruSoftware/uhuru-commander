#!/bin/bash


function parse_changelog()
{
    local first_char=""
    local CHANGELOG_FILE=$1
    local file_line_count=`cat ${CHANGELOG_FILE}|wc -l`
    echo -n "<ul style='padding-left:16px'>"
    cat ${CHANGELOG_FILE} | tail -n $(( ${file_line_count} - 1 )) | while read line;
    do
        first_char=`echo ${line}|cut -b 1`

        [ ${#first_char} -eq 0 -o ! -z "`echo ${line}|cut -b 1-4|grep '[2000-3000]'`" ] && break
        echo -n "<li>${line}</li>" | tr -d \* | tr \" \'
    done
    echo -n "</ul>"
}

PRODUCT_NAME="appcloud"
CF_RELEASE_DIR=$(readlink -f ".")
COMMANDER_DIR="${CF_RELEASE_DIR}/private-uhuru-commander"
DEV_RELEASES_DIR=$(readlink -f "./dev_releases")
UCC_PLUGIN_DIR=$(readlink -f "./ucc-plugin")
PUBLISHER_DIR="${COMMANDER_DIR}/publisher"
WEBUI_DIR="${COMMANDER_DIR}/web-ui"


# git clone private-uhuru-commander
rm -rf ${COMMANDER_DIR}
git clone ssh://vlad.iovanov@gerrit.uhurusoftware.org:29418/private-uhuru-commander


rm -rf /tmp/${PRODUCT_NAME}/bits.tgz
mkdir -p /tmp/${PRODUCT_NAME}

rm -rf ${DEV_RELEASES_DIR}/*

CWD=`pwd`
echo "Release dir is: ${CWD}"

export BUNDLE_GEMFILE=${WEBUI_DIR}/Gemfile

echo "Gemfile is: ${BUNDLE_GEMFILE}"

bundle exec bosh --non-interactive create release --with-tarball --force

mv `ls ${DEV_RELEASES_DIR}/*.tgz` ${DEV_RELEASES_DIR}/release.tgz
rm -rf ${DEV_RELEASES_DIR}/*.yml

cp -r ${UCC_PLUGIN_DIR}/* ${DEV_RELEASES_DIR}/

erb ${DEV_RELEASES_DIR}/plugin.rb.erb > ${DEV_RELEASES_DIR}/plugin.rb
rm ${DEV_RELEASES_DIR}/plugin.rb.erb

CURRENT_VERSION=$(cat ${DEV_RELEASES_DIR}/plugin.rb | grep version | cut -f 2 -d \")

sed -i -e "s/###ucc_product_version###/${CURRENT_VERSION}/g" ${DEV_RELEASES_DIR}/config/${PRODUCT_NAME}.yml.erb

VERSION_DESCRIPTION=`parse_changelog ${UCC_PLUGIN_DIR}/Changelog`


# alter version in tgz
gunzip ${DEV_RELEASES_DIR}/release.tgz
tar xf ${DEV_RELEASES_DIR}/release.tar ./release.MF -C ${DEV_RELEASES_DIR}/release.MF

if [ -e  ${DEV_RELEASES_DIR}/release.MF ]; then
    release_manifest_line_count=`cat ${DEV_RELEASES_DIR}/release.MF | wc -l`
    head -n $((${release_manifest_line_count} -1)) > ${DEV_RELEASES_DIR}/release.MF.tmp
fi

echo "version: ${CURRENT_VERSION}" >> ${DEV_RELEASES_DIR}/release.MF.tmp
mv -f ${DEV_RELEASES_DIR}/release.MF.tmp ${DEV_RELEASES_DIR}/release.MF

tar --delete -f ${DEV_RELEASES_DIR}/release.tar ./release.MF
cd ${DEV_RELEASES_DIR}
tar --append -f ${DEV_RELEASES_DIR}/release.tar ./release.MF
cd ${CF_RELEASE_DIR}

gzip -9 ${DEV_RELEASES_DIR}/release.tar
mv ${DEV_RELEASES_DIR}/release.tar.gz ${DEV_RELEASES_DIR}/release.tgz


# creating bits tarball
tar -czvf /tmp/${PRODUCT_NAME}/bits.tgz -C ${DEV_RELEASES_DIR} .

echo "Current version is ${CURRENT_VERSION}"

export BUNDLE_GEMFILE=${PUBLISHER_DIR}/Gemfile
cd ${PUBLISHER_DIR}/bin/
./publisher upload version -n ${PRODUCT_NAME} -r ${CURRENT_VERSION} -t alpha -d "${VERSION_DESCRIPTION}" -f /tmp/${PRODUCT_NAME}/bits.tgz


#add dependencies

ruby -e "require 'yaml'; YAML.load_file('${UCC_PLUGIN_DIR}/config/dependencies.yml').each {|dep, ver| ver.each {|v| puts dep + ' ' + v}}" | while read name version;
do
    ./publisher add dependency -n ${PRODUCT_NAME} -r ${CURRENT_VERSION} -d ${name} -s ${version}
done