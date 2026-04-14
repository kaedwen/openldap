# Minimal OpenLDAP Container

[![Build and Push](https://github.com/USERNAME/REPO/actions/workflows/build-openldap.yml/badge.svg)](https://github.com/USERNAME/REPO/actions/workflows/build-openldap.yml)

Minimal OpenLDAP container based on Alpine Linux.

## Quick Start

### Pull from GitHub Container Registry

```bash
podman pull ghcr.io/USERNAME/openldap-minimal:latest
```

### Run

```bash
# Create secret
echo -n "YourSecurePassword" | podman secret create ldap_admin_password -

# Run container
podman run -d \
  --name openldap \
  -p 389:389 \
  -p 636:636 \
  -e LDAP_DOMAIN=example.local \
  -e LDAP_ORGANISATION=WORKGROUP \
  --secret ldap_admin_password \
  -v openldap-data:/var/lib/openldap/openldap-data \
  -v openldap-config:/etc/openldap/slapd.d \
  ghcr.io/USERNAME/openldap-minimal:latest
```

## Build Locally

```bash
./build.sh
```

## Features

- ✅ **Minimal:** ~18 MB (Alpine Linux base)
- ✅ **Secure:** Non-root (runs as `ldap` user)
- ✅ **Auto-init:** Creates base structure on first run
- ✅ **Secrets:** Reads password from Podman/Docker secrets
- ✅ **Multi-arch:** amd64 and arm64

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LDAP_DOMAIN` | `example.local` | LDAP domain |
| `LDAP_ORGANISATION` | `Example` | Organization name |

### Secrets

Admin password is read from `/run/secrets/ldap_admin_password`

## Architecture

- **Base:** Alpine Linux (latest)
- **LDAP:** OpenLDAP from Alpine packages
- **Backend:** MDB (Lightning Memory-Mapped Database)
- **Size:** ~18 MB
- **User:** ldap (non-root)

## Auto-initialization

On first run, the container:
1. Creates base DN from `LDAP_DOMAIN`
2. Creates admin user: `cn=admin,dc=example,dc=local`
3. Creates organizational units: `ou=users`, `ou=groups`
4. Configures MDB backend with indexes

## Volumes

| Path | Description |
|------|-------------|
| `/var/lib/openldap/openldap-data` | LDAP database (MDB) |
| `/etc/openldap/slapd.d` | LDAP configuration |

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 389 | TCP | LDAP |
| 636 | TCP | LDAPS (TLS) |

## Health Check

Built-in health check runs:
```bash
ldapsearch -x -H ldap://localhost -b "" -s base
```

## Updates

Images are automatically rebuilt:
- ✅ Weekly (Sundays at 2am UTC) for security updates
- ✅ On every commit to main branch
- ✅ Manual trigger via GitHub Actions

## License

MIT

## Links

- [Source Code](https://github.com/USERNAME/REPO)
- [Container Registry](https://ghcr.io/USERNAME/openldap-minimal)
- [OpenLDAP Documentation](https://www.openldap.org/doc/)
