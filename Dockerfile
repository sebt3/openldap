FROM alpine

ENV LDAP_ORGANISATION "Example Ltd"
ENV LDAP_DOMAIN "example.com"
ENV LDAP_ROOT_USER "admin"
ENV LDAP_ADMIN_PASSWORD "admin"
ENV LDAP_CONFIG_PASSWORD "config"
ENV ACCESS_CONTROL "access to * by * read"
ENV LOG_LEVEL "stats"


RUN sed -i 's/dl-cdn.alpinelinux.org/ftp.halifax.rwth-aachen.de/g' /etc/apk/repositories \
 && apk add --update --no-cache --no-progress openldap openldap-overlay-all openldap-clients openldap-back-mdb \
 && mkdir -p /run/openldap /var/lib/ldap /var/lib/openldap  \
 && rm -rf /var/cache/apk/* /var/lib/openldap/openldap-data \
 && ln -s /var/lib/ldap /var/lib/openldap/openldap-data

COPY root/ /

EXPOSE 389
EXPOSE 636

VOLUME ["/var/lib/ldap", "/etc/ldap/slapd.d"]

ENTRYPOINT ["/bin/entrypoint.sh"]

