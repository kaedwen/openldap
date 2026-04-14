# Minimal OpenLDAP Container
FROM alpine:latest

# Install OpenLDAP
RUN apk add --no-cache \
    openldap \
    openldap-back-mdb \
    openldap-clients \
    openldap-overlay-all \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /var/lib/openldap/openldap-data \
    && mkdir -p /etc/openldap/slapd.d \
    && chown -R ldap:ldap /var/lib/openldap \
    && chown -R ldap:ldap /etc/openldap/slapd.d

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose LDAP ports
EXPOSE 389 636

# Run as ldap user
USER ldap

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ldapsearch -x -H ldap://localhost -b "" -s base || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["slapd", "-d", "256", "-h", "ldap:/// ldaps:///", "-u", "ldap", "-g", "ldap"]
