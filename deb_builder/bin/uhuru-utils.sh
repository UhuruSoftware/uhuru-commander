#!/bin/bash

PATH_UHURU_COMMANDER=$1
PATH_TTY_JS="${PATH_UHURU_COMMANDER}/modules/private-tty.js"
PATH_TARGET=$2
PATH_BOSH="${PATH_UHURU_COMMANDER}/modules/private-bosh"
PREFIX="uhuru-openstack-"

VERSION=$3


mkdir -p ${PATH_TARGET}
cd ${PATH_TARGET}

function make_ttyjs()
{
    local cwd=`pwd`

    rm -rf ${PREFIX}ttyjs ${PREFIX}ttyjs.deb

    mkdir -p ${PREFIX}ttyjs/DEBIAN
    mkdir -p ${PREFIX}ttyjs/var/vcap/store/tty.js
    mkdir -p ${PREFIX}ttyjs/etc/monit/uhururc.d_pieces
    mkdir -p ${PREFIX}ttyjs/usr/src/uhuru/nodejs

    cd ${PREFIX}ttyjs/usr/src/uhuru/nodejs

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ttyjs/node-latest.tar.gz .
    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ttyjs/node_modules.tar.gz .

    cd $cwd

    cat <<EOF >${PREFIX}ttyjs/DEBIAN/control
Package: ${PREFIX}ttyjs
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: ${PREFIX}ucc
Installed-Size: 20480
Depends: monit, libxml2-dev, libxslt-dev, libsqlite3-dev, screen, libpq-dev
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru tty.js utility
 .
EOF

    cp -R ${PATH_TTY_JS}/* ${PREFIX}ttyjs/var/vcap/store/tty.js/

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ttyjs_ctl ${PREFIX}ttyjs/var/vcap/store/tty.js/ttyjs_ctl

    cat <<EOF >${PREFIX}ttyjs/etc/monit/uhururc.d_pieces/ttyjs.monit
check process ttyjs
  with pidfile /var/vcap/sys/run/ttyjs.pid
  start program "/var/vcap/store/tty.js/ttyjs_ctl start"
  stop program "/var/vcap/store/tty.js/ttyjs_ctl stop"
  group ucc
EOF

    cat <<EOF >${PREFIX}ttyjs/DEBIAN/postinst
#!/bin/bash
    cd /usr/src/uhuru/nodejs

    mkdir -p /tmp/ucc_install/

    echo "Install logs available here: /tmp/ucc_install/ttyjs.log"
    (
    tar xzvf node-latest.tar.gz
    cd \`ls -rd node-v*\`
    ./configure
    make install

    cd ..

    tar xzvf node_modules.tar.gz

    cd /var/vcap/store/tty.js
    cp -R /usr/src/uhuru/nodejs/node_modules .
    ) 2>&1 1>/tmp/ucc_install/ttyjs.log

    exit 0
EOF

    cat <<EOF >${PREFIX}ttyjs/DEBIAN/prerm
#!/bin/bash

monit stop ttyjs

rm -f /etc/monit/uhururc.d_pieces/ttyjs.monit

rm -rf /var/vcap/store/tty.js

exit 0
EOF

    chmod 755 ${PREFIX}ttyjs/DEBIAN/postinst
    chmod 755 ${PREFIX}ttyjs/DEBIAN/prerm

    dpkg-deb --build ${PREFIX}ttyjs .
}

function make_uccui()
{
    local cwd=`pwd`

    echo "Generating gems..."

    rm -rf ${PATH_BOSH}/pkg
    rm -rf ${PREFIX}uccui ${PREFIX}uccui.deb

    mkdir -p ${PREFIX}uccui/DEBIAN
    mkdir -p ${PREFIX}uccui/var/vcap/store/ucc
    mkdir -p ${PREFIX}uccui/etc/monit/uhururc.d_pieces

    cat <<EOF >${PREFIX}uccui/DEBIAN/control
Package: ${PREFIX}uccui
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: ${PREFIX}ucc
Installed-Size: 13312
Depends: monit, mkpasswd, libxml2-dev, libxslt-dev, libsqlite3-dev, screen, libpq-dev, ${PREFIX}bosh-package-ruby
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru Cloud Commander User Interface utility
 .
EOF

    cp -R ${PATH_UHURU_COMMANDER}/web-ui ${PREFIX}uccui/var/vcap/store/ucc/

    rm ${PREFIX}uccui/var/vcap/store/ucc/web-ui/config/properties.yml

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ucc_ctl ${PREFIX}uccui/var/vcap/store/ucc/ucc_ctl

    cd ${PREFIX}uccui/var/vcap/store/ucc/web-ui

    mv Gemfile Gemfile.bk
    cat Gemfile.bk|grep -v git >Gemfile;cat Gemfile.bk |grep git|cut -f 1 -d \:|rev|cut -b 3-|rev >>Gemfile
    rm Gemfile.bk Gemfile.lock
    rm -rf .bundle

    cd ${PATH_BOSH}

    bundle exec rake all:pre_stage_latest

    mkdir -p $cwd/${PREFIX}uccui/var/vcap/store/ucc/web-ui/vendor/cache

    cp -f ${PATH_BOSH}/pkg/gems/* ${cwd}/${PREFIX}uccui/var/vcap/store/ucc/web-ui/vendor/cache/
    cp -f ${PATH_BOSH}/vendor/cache/* ${cwd}/${PREFIX}uccui/var/vcap/store/ucc/web-ui/vendor/cache/

    cp -f $PATH_UHURU_COMMANDER/web-ui/vendor/cache/* ${cwd}/${PREFIX}uccui/var/vcap/store/ucc/web-ui/vendor/cache/

    rm -rf ${cwd}/${PREFIX}uccui/var/vcap/store/ucc/web-ui/vendor/bundle

    cd $cwd
    
    cat <<EOF >${PREFIX}uccui/DEBIAN/postinst
#!/bin/bash
cd /var/vcap/store/ucc/web-ui
GEM_HOME=/var/vcap/store/ucc/web-ui/gem_home
/var/vcap/packages/ruby/bin/bundle install --local

if [ ! -f /var/vcap/store/ucc/web-ui/config/properties.yml ]; then
    erb -r securerandom /var/vcap/store/ucc/web-ui/config/properties.yml.erb > /var/vcap/store/ucc/web-ui/config/properties.yml
fi

echo -e "\nversion: ${VERSION}" > /var/vcap/store/ucc/web-ui/config/version.yml

exit 0
EOF

    cat <<EOF >${PREFIX}uccui/DEBIAN/prerm
#!/bin/bash

monit stop ucc

rm -f /etc/monit/uhururc.d_pieces/ucc.monit

rm -rf /tmp/deployments_bkp
mkdir -p /tmp/deployments_bkp

cp -Rf /var/vcap/store/ucc/web-ui/deployments /tmp/deployments_bkp

cp -f /var/vcap/store/ucc/web-ui/config/properties.yml /tmp/ucc_properties.yml
rm -rf /var/vcap/store/ucc/web-ui
mkdir -p /var/vcap/store/ucc/web-ui/config/

cp -f /tmp/ucc_properties.yml /var/vcap/store/ucc/web-ui/config/properties.yml
cp -Rf /tmp/deployments_bkp/deployments /var/vcap/store/ucc/web-ui/

exit 0
EOF

chmod 755 ${PREFIX}uccui/DEBIAN/postinst
chmod 755 ${PREFIX}uccui/DEBIAN/prerm

    cat <<EOF >${PREFIX}uccui/etc/monit/uhururc.d_pieces/ucc.monit
check process ucc
  with pidfile /var/vcap/sys/run/ucc.pid
  start program "/var/vcap/store/ucc/ucc_ctl start"
  stop program "/var/vcap/store/ucc/ucc_ctl stop"
  group ucc
EOF

    dpkg-deb --build ${PREFIX}uccui .
}

make_ttyjs
make_uccui
