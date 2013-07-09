#!/bin/bash

PATH_UHURU_COMMANDER=$1
PATH_TTY_JS="${PATH_UHURU_COMMANDER}/modules/private-tty.js"
PATH_TARGET=$2
PATH_BOSH="${PATH_UHURU_COMMANDER}/modules/private-bosh"

VERSION=$3


mkdir -p ${PATH_TARGET}
cd ${PATH_TARGET}

function make_ttyjs()
{
    local cwd=`pwd`

    rm -rf uhuru-ttyjs uhuru-ttyjs.deb

    mkdir -p uhuru-ttyjs/DEBIAN
    mkdir -p uhuru-ttyjs/var/vcap/store/tty.js
    mkdir -p uhuru-ttyjs/etc/monit/uhururc.d_pieces
    mkdir -p uhuru-ttyjs/usr/src/uhuru/nodejs

    cd uhuru-ttyjs/usr/src/uhuru/nodejs
    wget -N http://nodejs.org/dist/node-latest.tar.gz
    cd $cwd

    cat <<EOF >uhuru-ttyjs/DEBIAN/control
Package: uhuru-ttyjs
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: uhuru-ucc
Installed-Size: 0
Depends: monit, libxml2-dev, libxslt-dev, libsqlite3-dev, screen, libpq-dev
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru tty.js utility
 .
EOF

    cp -R ${PATH_TTY_JS}/* uhuru-ttyjs/var/vcap/store/tty.js/

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ttyjs_ctl uhuru-ttyjs/var/vcap/store/tty.js/ttyjs_ctl

    cat <<EOF >uhuru-ttyjs/etc/monit/uhururc.d_pieces/ttyjs.monit
check process ttyjs
  with pidfile /var/vcap/sys/run/ttyjs.pid
  start program "/var/vcap/store/tty.js/ttyjs_ctl start"
  stop program "/var/vcap/store/tty.js/ttyjs_ctl stop"
  group vcap
EOF

    cat <<EOF >uhuru-ttyjs/DEBIAN/postinst
#!/bin/bash
    cd /usr/src/uhuru/nodejs
    tar xzvf node-latest.tar.gz && cd \`ls -rd node-v*\`
    ./configure
    make install
    cd /var/vcap/store/tty.js
    npm install

    find /etc/monit/uhururc.d_pieces/ -type f -exec cat {} \; -exec echo -e "\n\n" \; > /etc/monit/uhururc.d/jobs

    service monit restart
    monit restart ttyjs    
EOF

    cat <<EOF >uhuru-ttyjs/DEBIAN/postrm
#!/bin/bash

monit stop ttyjs

rm -f /etc/monit/uhururc.d_pieces/ttyjs.monit
find /etc/monit/uhururc.d_pieces/ -type f -exec cat {} \; -exec echo -e "\n\n" \; > /etc/monit/uhururc.d/jobs
rm -rf /var/vcap/store/tty.js

EOF

    chmod 755 uhuru-ttyjs/DEBIAN/postinst
    chmod 755 uhuru-ttyjs/DEBIAN/postrm

    dpkg-deb --build uhuru-ttyjs .
}

function make_uccui()
{
    local cwd=`pwd`

    echo "Generating gems..."

    rm -rf ${PATH_BOSH}/pkg
    rm -rf uhuru-uccui uhuru-uccui.deb

    mkdir -p uhuru-uccui/DEBIAN
    mkdir -p uhuru-uccui/var/vcap/store/ucc
    mkdir -p uhuru-uccui/etc/monit/uhururc.d_pieces

    cat <<EOF >uhuru-uccui/DEBIAN/control
Package: uhuru-uccui
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: uhuru-ucc
Installed-Size: 0
Depends: monit, libxml2-dev, libxslt-dev, libsqlite3-dev, screen, libpq-dev, uhuru-bosh-package-ruby
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru Cloud Commander User Interface utility
 .
EOF

    cp -R ${PATH_UHURU_COMMANDER}/web-ui uhuru-uccui/var/vcap/store/ucc/

    rm uhuru-uccui/var/vcap/store/ucc/web-ui/config/properties.yml

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ucc_ctl uhuru-uccui/var/vcap/store/ucc/ucc_ctl

    cd uhuru-uccui/var/vcap/store/ucc/web-ui

    mv Gemfile Gemfile.bk
    cat Gemfile.bk|grep -v git >Gemfile;cat Gemfile.bk |grep git|cut -f 1 -d \:|rev|cut -b 3-|rev >>Gemfile
    rm Gemfile.bk Gemfile.lock
    rm -rf .bundle

    cd ${PATH_BOSH}

    bundle exec rake all:pre_stage_latest

    mkdir -p $cwd/uhuru-uccui/var/vcap/store/ucc/web-ui/vendor/cache

    cp -f ${PATH_BOSH}/pkg/gems/* ${cwd}/uhuru-uccui/var/vcap/store/ucc/web-ui/vendor/cache/
    cp -f ${PATH_BOSH}/vendor/cache/* ${cwd}/uhuru-uccui/var/vcap/store/ucc/web-ui/vendor/cache/

    cp -f $PATH_UHURU_COMMANDER/web-ui/vendor/cache/* ${cwd}/uhuru-uccui/var/vcap/store/ucc/web-ui/vendor/cache/

    rm -rf ${cwd}/uhuru-uccui/var/vcap/store/ucc/web-ui/vendor/bundle

    cd $cwd
    
    cat <<EOF >uhuru-uccui/DEBIAN/postinst
#!/bin/bash
cd /var/vcap/store/ucc/web-ui
GEM_HOME=/var/vcap/store/ucc/web-ui/gem_home
/var/vcap/packages/ruby/bin/bundle install --local

if [ ! -f /var/vcap/store/ucc/web-ui/config/properties.yml ]; then
    erb -r securerandom /var/vcap/store/ucc/web-ui/config/properties.yml.erb > /var/vcap/store/ucc/web-ui/config/properties.yml
fi

find /etc/monit/uhururc.d_pieces/ -type f -exec cat {} \; -exec echo -e "\n\n" \; > /etc/monit/uhururc.d/jobs

service monit restart
monit restart all
EOF

    cat <<EOF >uhuru-uccui/DEBIAN/postrm
#!/bin/bash

monit stop ucc

rm -f /etc/monit/uhururc.d_pieces/ucc.monit

find /etc/monit/uhururc.d_pieces/ -type f -exec cat {} \; -exec echo -e "\n\n" \; > /etc/monit/uhururc.d/jobs

cp -f /var/vcap/store/ucc/web-ui/config/properties.yml /tmp/ucc_properties.yml
rm -rf /var/vcap/store/ucc/web-ui
mkdir -p /var/vcap/store/ucc/web-ui/config/
cp -f /tmp/ucc_properties.yml /var/vcap/store/ucc/web-ui/config/properties.yml

EOF

chmod 755 uhuru-uccui/DEBIAN/postinst
chmod 755 uhuru-uccui/DEBIAN/postrm

    cat <<EOF >uhuru-uccui/etc/monit/uhururc.d_pieces/ucc.monit
check process ucc
  with pidfile /var/vcap/sys/run/ucc.pid
  start program "/var/vcap/store/ucc/ucc_ctl start"
  stop program "/var/vcap/store/ucc/ucc_ctl stop"
  group vcap

  depends on postgres,director,nagios,ttyjs
EOF

    dpkg-deb --build uhuru-uccui .
}

make_ttyjs
make_uccui