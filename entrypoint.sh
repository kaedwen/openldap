#!/bin/bash
# OpenLDAP entrypoint script

set -e

LDAP_DOMAIN="${LDAP_DOMAIN:-example.local}"
LDAP_ORGANISATION="${LDAP_ORGANISATION:-Example}"

# Read password from Podman secret (mounted as file) or environment variable
if [ -f "/run/secrets/ldap_admin_password" ]; then
    LDAP_ADMIN_PASSWORD=$(cat /run/secrets/ldap_admin_password)
    echo "Password loaded from Podman secret"
elif [ -n "$LDAP_ADMIN_PASSWORD" ]; then
    echo "Password loaded from environment variable"
else
    echo "ERROR: No password provided!"
    echo "Either mount Podman secret or set LDAP_ADMIN_PASSWORD environment variable"
    exit 1
fi

# Extract base DN from domain
LDAP_BASE_DN=$(echo "$LDAP_DOMAIN" | sed 's/^/dc=/' | sed 's/\./,dc=/g')

echo "Starting OpenLDAP..."
echo "Domain: $LDAP_DOMAIN"
echo "Base DN: $LDAP_BASE_DN"
echo "Organization: $LDAP_ORGANISATION"

# Check if cn=config database already exists
if [ ! -d /etc/openldap/slapd.d/cn=config ]; then
    echo "First run - initializing OpenLDAP configuration..."

    # Generate password hash
    ADMIN_PASSWORD_HASH=$(slappasswd -s "$LDAP_ADMIN_PASSWORD")

    # Create cn=config configuration
    cat > /tmp/config.ldif << EOF
dn: cn=config
objectClass: olcGlobal
cn: config
olcLogLevel: stats

dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib/openldap
olcModuleLoad: back_mdb.so

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file:///etc/openldap/schema/core.ldif
include: file:///etc/openldap/schema/cosine.ldif
include: file:///etc/openldap/schema/inetorgperson.ldif
include: file:///etc/openldap/schema/nis.ldif

dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbDirectory: /var/lib/openldap/openldap-data
olcSuffix: $LDAP_BASE_DN
olcRootDN: cn=admin,$LDAP_BASE_DN
olcRootPW: $ADMIN_PASSWORD_HASH
olcDbIndex: objectClass eq
olcDbIndex: cn eq
olcDbIndex: uid eq
olcAccess: to attrs=userPassword
  by self write
  by anonymous auth
  by * none
olcAccess: to *
  by self write
  by * read
EOF

    # Import cn=config
    mkdir -p /etc/openldap/slapd.d
    slapadd -n 0 -F /etc/openldap/slapd.d -l /tmp/config.ldif

    # Create base data structure
    cat > /tmp/init.ldif << EOF
dn: $LDAP_BASE_DN
objectClass: top
objectClass: dcObject
objectClass: organization
o: $LDAP_ORGANISATION
dc: $(echo "$LDAP_DOMAIN" | cut -d. -f1)

dn: cn=admin,$LDAP_BASE_DN
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword: $ADMIN_PASSWORD_HASH

dn: ou=users,$LDAP_BASE_DN
objectClass: organizationalUnit
ou: users

dn: ou=groups,$LDAP_BASE_DN
objectClass: organizationalUnit
ou: groups
EOF

    # Import base structure
    mkdir -p /var/lib/openldap/openldap-data
    slapadd -n 1 -F /etc/openldap/slapd.d -l /tmp/init.ldif

    # Fix permissions
    chown -R ldap:ldap /var/lib/openldap/openldap-data 2>/dev/null || true
    chown -R ldap:ldap /etc/openldap/slapd.d 2>/dev/null || true

    echo "Configuration initialized!"
    rm -f /tmp/config.ldif /tmp/init.ldif
else
    echo "Configuration exists, skipping initialization."
fi

# Start slapd with cn=config
echo "Starting slapd..."
exec slapd -d 256 -h "ldap:/// ldaps:///" -F /etc/openldap/slapd.d -u ldap -g ldap
