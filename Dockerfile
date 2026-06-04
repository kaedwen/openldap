# Minimal OpenLDAP Container
FROM alpine:latest

# Install OpenLDAP and bash (for better scripting)
RUN apk add --no-cache \
    openldap \
    openldap-back-mdb \
    openldap-clients \
    openldap-overlay-all \
    bash \
    && rm -rf /var/cache/apk/*

# Create necessary directories with proper permissions
RUN mkdir -p /var/lib/openldap/openldap-data \
    && mkdir -p /etc/openldap/slapd.d \
    && chown -R ldap:ldap /var/lib/openldap \
    && chown -R ldap:ldap /etc/openldap/slapd.d

# Copy entrypoint script and minimal init config
COPY entrypoint.sh /usr/local/bin/
COPY minimal-init.ldif /usr/local/share/openldap/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose LDAP ports
EXPOSE 389 636

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ldapsearch -Y EXTERNAL -H ldapi:/// -b "" -s base "(objectClass=*)" namingContexts || exit 1

# Keep as root for initialization, entrypoint will handle user switching
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
