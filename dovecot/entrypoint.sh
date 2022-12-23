#!/bin/sh
/bin/cat << EOF > /etc/dovecot/dovecot-userdb.conf.ext
hosts = openldap
dn = cn=reader,cn=mail
dnpass = $(cat /run/secrets/mail-reader-ldap-password) 
base = cn=mail
EOF
/usr/sbin/dovecot -F
