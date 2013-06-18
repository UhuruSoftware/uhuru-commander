#!/bin/bash

pwd=`pwd`
mkdir /tmp/uhuru
cd /tmp/uhuru

packages="blobstore common director genisoimage health_monitor libpq nagios nagios_dashboard nats nginx postgres powerdns redis registry ruby"

for i in $packages;
do
mkdir -p "/tmp/uhuru/uhuru-bosh-packages-`echo ${i}|tr -d \_`/DEBIAN"
done


cat <<EOF >uhuru-bosh-packages-redis/DEBIAN/control
Package: uhuru-bosh-packages-redis
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH redis package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-ruby/DEBIAN/control
Package: uhuru-bosh-packages-ruby
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH ruby package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-powerdns/DEBIAN/control
Package: uhuru-bosh-packages-powerdns
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH powerdns package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-nats/DEBIAN/control
Package: uhuru-bosh-packages-nats
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH nats package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF


cat <<EOF >uhuru-bosh-packages-nginx/DEBIAN/control
Package: uhuru-bosh-packages-nginx
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH nginx package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-nagios/DEBIAN/control
Package: uhuru-bosh-packages-nagios
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH nagios package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-libpq/DEBIAN/control
Package: uhuru-bosh-packages-libpq
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH libpq package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF


cat <<EOF >uhuru-bosh-packages-blobstore/DEBIAN/control
Package: uhuru-bosh-packages-blobstore
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH blobstore package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-common/DEBIAN/control
Package: uhuru-bosh-packages-common
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH common package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-director/DEBIAN/control
Package: uhuru-bosh-packages-director
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby, uhuru-bosh-packages-libpq
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH director job
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-genisoimage/DEBIAN/control
Package: uhuru-bosh-packages-genisoimage
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH genisoimage package
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF


cat <<EOF >uhuru-bosh-packages-healthmonitor/DEBIAN/control
Package: uhuru-bosh-packages-healthmonitor
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH health_monitor job
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF


cat <<EOF >uhuru-bosh-packages-nagiosdashboard/DEBIAN/control
Package: uhuru-bosh-packages-nagiosdashboard
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby, uhuru-bosh-packages-libpq
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH nagios_dashboard job
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-postgres/DEBIAN/control
Package: uhuru-bosh-packages-postgres
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH postgres job
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF

cat <<EOF >uhuru-bosh-packages-registry/DEBIAN/control
Package: uhuru-bosh-packages-registry
Version: 1.4.24-4
Section: Libraries
Priority: important
Architecture: amd64
Depends: uhuru-bosh-packages-ruby, uhuru-bosh-packages-libpq
Suggests: uhuru-bosh-full
Installed-Size: 76
Maintainer: Uhuru Software <debs@uhurusoftware.com>
Description: BOSH registry job
 FIXME
 .
 Put long description here, use a single dot for empty lines.
 .
EOF




for i in $packages;
do
  right_name=`echo ${i}|tr -d \_`

  [ -e $pwd/../src/${i} ] &&
    {
    mkdir -p  /tmp/uhuru/uhuru-bosh-packages-${right_name}/tmp/uhuru/$i
    cp -r $pwd/../src/${right_name}/* /tmp/uhuru/uhuru-bosh-packages-${right_name}/tmp/uhuru/$i/

    }
  cat <<EOF >/tmp/uhuru/uhuru-bosh-packages-${right_name}/DEBIAN/postinst
BOSH_INSTALL_TARGET=/var/vcap/store
cd /tmp/uhuru
EOF

  cat $pwd/$i/packaging >> /tmp/uhuru/uhuru-bosh-packages-${right_name}/DEBIAN/postinst

  cat <<EOF >/tmp/uhuru/uhuru-bosh-packages-${right_name}/DEBIAN/postinst
rm -rf /tmp/uhuru
EOF
  chmod +x  /tmp/uhuru/uhuru-bosh-packages-${right_name}/DEBIAN/postinst

  find /tmp/uhuru/uhuru-bosh-packages-${right_name} -type d | xargs chmod 755

  dpkg-deb --build "uhuru-bosh-packages-`echo ${i}|tr -d \_`"

done

