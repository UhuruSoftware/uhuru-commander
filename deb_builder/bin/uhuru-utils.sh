#!/bin/bash

PATH_UHURU_COMMANDER=$1
PATH_TTY_JS="${PATH_UHURU_COMMANDER}/modules/private-tty.js"
PATH_TARGET=$2
VERSION=$3

mkdir -p ${PATH_TARGET}
cd ${PATH_TARGET}

function make_ttyjs()
{
    rm -rf uhuru-ttyjs uhuru-ttyjs.deb

    mkdir -p uhuru-ttyjs/DEBIAN
    mkdir -p uhuru-ttyjs/var/vcap/store/tty.js
    mkdir -p uhuru-ttyjs/etc/monit/uhururc.d

    cat <<EOF >uhuru-ttyjs/DEBIAN/control
Package: uhuru-ttyjs
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: uhuru-ucc
Installed-Size: 0
Depends: monit
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru tty.js utility
 .
EOF

    cp -R ${PATH_TTY_JS}/* uhuru-ttyjs/var/vcap/store/tty.js/

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ttyjs_ctl uhuru-ttyjs/var/vcap/store/tty.js/ttyjs_ctl

    cat <<EOF >uhuru-ttyjs/etc/monit/uhururc.d/ttyjs.monit
check process ttyjs
  with pidfile /var/run/ttyjs.pid
  start program "/var/vcap/store/tty.js/ttyjs_ctl start"
  stop program "/var/vcap/store/tty.js/ttyjs_ctl stop"
  group vcap
EOF

    dpkg-deb --build uhuru-ttyjs
}

function make_uccui()
{
    rm -rf uhuru-uccui uhuru-uccui.deb

    mkdir -p uhuru-uccui/DEBIAN
    mkdir -p uhuru-uccui/var/vcap/store/ucc
    mkdir -p uhuru-uccui/etc/monit/uhururc.d

    cat <<EOF >uhuru-uccui/DEBIAN/control
Package: uhuru-uccui
Version: ${VERSION}
Section: Utilities
Priority: important
Architecture: amd64
Suggests: uhuru-ucc
Installed-Size: 0
Depends: monit
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: Uhuru Cloud Commander User Interface utility
 .
EOF

    cp -R ${PATH_UHURU_COMMANDER}/web-ui uhuru-uccui/var/vcap/store/ucc/

    cp ${PATH_UHURU_COMMANDER}/deb_builder/assets/ucc_ctl uhuru-uccui/var/vcap/store/ucc/ucc_ctl

    cat <<EOF >uhuru-uccui/etc/monit/uhururc.d/ucc.monit
check process ucc
  with pidfile /tmp/boshcommander.pid
  start program "/var/vcap/store/ucc/ucc_ctl start"
  stop program "/var/vcap/store/ucc/ucc_ctl stop"
  group vcap
EOF

    dpkg-deb --build uhuru-uccui
}

make_ttyjs
make_uccui
