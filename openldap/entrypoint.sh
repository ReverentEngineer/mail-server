#!/bin/sh
set -eo pipefail
setup() {
	echo -ne "Admin password: "
	read -s ROOT_PASSWORD;
	echo
	/usr/sbin/slapadd -n 0 -F /etc/openldap/slapd.d  << EOF
dn: cn=config
objectClass: olcGlobal
cn: config

dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath:	/usr/lib/openldap
olcModuleload:	back_mdb.so

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file:///etc/openldap/schema/core.ldif
include: file:///etc/openldap/schema/cosine.ldif
include: file:///etc/openldap/schema/inetorgperson.ldif
include: file:///etc/openldap/schema/nis.ldif

dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
olcDatabase: frontend

dn: olcDatabase=config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break

dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbMaxSize: 1073741824
olcSuffix: cn=mail
olcRootDN: cn=admin,cn=mail
olcRootPW: $(/usr/sbin/slappasswd -s $ROOT_PASSWORD)
olcDbDirectory:	/var/lib/openldap/openldap-data
olcDbIndex: objectClass eq
olcAccess: {0}to attrs=shadowLastChange,userPassword by dn.base="cn=admin,cn=mail" write by self write by anonymous auth by * none
olcAccess: {1}to dn.children="cn=people,cn=mail" attrs=uid,objectClass by dn="cn=reader,cn=mail" read
olcAccess: {1}to * by users read by anonymous auth by * none

dn: olcDatabase=monitor,cn=config
objectClass: olcDatabaseConfig
olcDatabase: monitor
olcRootDN: cn=config
olcMonitoring: FALSE
EOF
	chown -R ldap:ldap /etc/openldap/slapd.d/*
	/usr/sbin/slapadd -n 1 -F /etc/openldap/slapd.d << EOF
dn: cn=mail
objectClass: nisNetgroup
cn: mail

dn: cn=people,cn=mail
objectClass: nisNetgroup
cn: people

dn: cn=reader,cn=mail
objectClass: applicationProcess
objectClass: simpleSecurityObject
cn: reader
userPassword: $(/usr/sbin/slappasswd -T /run/secrets/mail-reader-ldap-password)
EOF
	chown -R ldap:ldap /var/lib/openldap/openldap-data/*
}

run() {
	/usr/sbin/slapd -F /etc/openldap/slapd.d -h "ldapi:// ldap://" -u ldap -g ldap -d 64
}


if [ $# -ne 1 ]; then
	exit -1;	
fi

COMMAND=$1 &&\
case $COMMAND in
	setup)
		setup;;
	run)
		run;;
	*)
		exit 1;;
esac
