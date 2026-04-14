# Minimal OpenLDAP Build

Custom-built minimal OpenLDAP container based on Alpine Linux.

## Why Custom Build?

**Problem with existing images:**
- **osixia/openldap:** Last update 2018 (dead)
- **bitnami/openldap:** Moved to paywall
- **Others:** Abandoned or unmaintained

**Our solution:**
- ✅ Build from Alpine + OpenLDAP package
- ✅ Minimal (< 20 MB)
- ✅ We control updates
- ✅ No vendor lock-in
- ✅ Security updates from Alpine

## Build

```bash
cd build
./build.sh
```

This creates: `localhost/openldap-minimal:latest`

## What's Included

**Base:** Alpine Linux (latest)
**Packages:**
- `openldap` - LDAP server
- `openldap-back-mdb` - MDB backend
- `openldap-clients` - ldapsearch, ldapadd, etc.
- `openldap-overlay-all` - All overlays

**Size:** ~18 MB

## Features

- ✅ Auto-initialization on first run
- ✅ Environment-based configuration
- ✅ Runs as non-root (ldap user)
- ✅ Health check included
- ✅ Standard LDAP ports (389/636)

## Environment Variables

- `LDAP_DOMAIN` - Domain (e.g., heinrich.local)
- `LDAP_ORGANISATION` - Organization name
- Password via **Podman Secret** (mounted at `/run/secrets/ldap_admin_password`)

## Podman Secrets

The container reads the admin password from Podman secret:

```bash
# Create secret
echo -n "MySecurePassword" | podman secret create ldap_admin_password -

# Container automatically reads from /run/secrets/ldap_admin_password
```

**Fallback:** If no secret is mounted, it reads from `LDAP_ADMIN_PASSWORD` environment variable (not recommended for production).

## Automatic Setup

On first run, the container:
1. Creates base DN from domain
2. Sets up admin user: `cn=admin,dc=example,dc=local`
3. Creates OUs: `ou=users` and `ou=groups`
4. Configures MDB backend
5. Starts slapd

## Update Process

To update OpenLDAP:

```bash
# Rebuild image with latest Alpine
cd build
./build.sh

# Restart container
sudo systemctl restart openldap
```

## Files

- `Dockerfile` - Container build definition
- `entrypoint.sh` - Initialization script
- `build.sh` - Build script

## Comparison

| Feature | Our Build | osixia | bitnami |
|---------|-----------|--------|---------|
| **Active** | ✅ We control | ❌ Dead | ❌ Paywall |
| **Size** | 18 MB | 180 MB | 200 MB |
| **Updates** | Alpine repo | None | Paid only |
| **Base** | Alpine | Ubuntu | Debian |
| **User** | ldap (non-root) | root | bitnami |

## Security

- Runs as `ldap` user (UID/GID from Alpine)
- No unnecessary packages
- Alpine security updates
- Minimal attack surface

## Maintenance

**Update base image:**
```bash
cd build
podman pull alpine:latest
./build.sh
```

**Update OpenLDAP:**
Alpine updates their `openldap` package regularly. Rebuild to get updates.

**Frequency:** Rebuild monthly or when Alpine releases security updates.
