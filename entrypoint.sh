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

# Check if database already exists
if [ ! -f /var/lib/openldap/openldap-data/data.mdb ]; then
    echo "First run - initializing database..."

    # Create base configuration
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
userPassword: $(slappasswd -s "$LDAP_ADMIN_PASSWORD")

dn: ou=users,$LDAP_BASE_DN
objectClass: organizationalUnit
ou: users

dn: ou=groups,$LDAP_BASE_DN
objectClass: organizationalUnit
ou: groups
EOF

    # Create minimal slapd.conf for initial import
    cat > /tmp/slapd.conf << EOF
include /etc/openldap/schema/core.schema
include /etc/openldap/schema/cosine.schema
include /etc/openldap/schema/inetorgperson.schema
include /etc/openldap/schema/nis.schema

moduleload back_mdb

database mdb
suffix "$LDAP_BASE_DN"
rootdn "cn=admin,$LDAP_BASE_DN"
rootpw $LDAP_ADMIN_PASSWORD
directory /var/lib/openldap/openldap-data

index objectClass eq
EOF

    # Import base structure as root
    slapadd -f /tmp/slapd.conf -l /tmp/init.ldif

    # Fix permissions after import
    chown -R ldap:ldap /var/lib/openldap/openldap-data
    chown -R ldap:ldap /etc/openldap/slapd.d

    echo "Database initialized!"
    rm -f /tmp/init.ldif /tmp/slapd.conf
else
    echo "Database exists, skipping initialization."
fi

# Start slapd (will run as ldap user due to -u/-g flags in CMD)
echo "Starting slapd..."
exec "$@"
