#!/bin/bash
# OpenLDAP entrypoint script
# Minimal container - supports runtime configuration via ldapi:///

set -e

MINIMAL_INIT_LDIF="/usr/local/share/openldap/minimal-init.ldif"

echo "Starting OpenLDAP..."

# Check if configuration exists
if [ ! -d /etc/openldap/slapd.d/cn=config ] || [ ! -f /etc/openldap/slapd.d/cn=config.ldif ]; then
    echo "No configuration found - performing minimal initialization..."
    echo ""
    echo "This container uses runtime configuration via ldapi://"
    echo "After startup, configure using:"
    echo "  podman exec <container> ldapadd -Y EXTERNAL -H ldapi:/// -f config.ldif"
    echo ""

    # Create minimal cn=config that allows runtime configuration
    mkdir -p /etc/openldap/slapd.d

    if [ -f "$MINIMAL_INIT_LDIF" ]; then
        echo "Loading minimal configuration from $MINIMAL_INIT_LDIF"
        slapadd -n 0 -F /etc/openldap/slapd.d -l "$MINIMAL_INIT_LDIF"
    else
        echo "ERROR: Minimal init file not found: $MINIMAL_INIT_LDIF"
        exit 1
    fi

    echo "Minimal configuration created."
    echo "Add your database and suffix via ldapi:// after container starts!"
else
    echo "Existing configuration found, using it."
fi

# Ensure required directories exist
mkdir -p /var/lib/openldap/openldap-data
mkdir -p /var/lib/openldap/run

# Fix permissions
chown -R ldap:ldap /var/lib/openldap 2>/dev/null || true
chown -R ldap:ldap /etc/openldap/slapd.d 2>/dev/null || true

# Start slapd with ldapi:// enabled for runtime configuration
echo "Starting slapd with ldap://, ldaps://, and ldapi:// support..."
echo "Runtime configuration available via: ldapi:///"
exec slapd -d 256 -h "ldap:/// ldaps:/// ldapi:///" -F /etc/openldap/slapd.d -u ldap -g ldap
