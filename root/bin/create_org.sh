#!/bin/sh

# REQUIRED ENV VARS:
# LDAP_URI: 		URI to connect to the LDAP server
# LDAP_BASE_DN: 	exemple : dc=example,dc=com
# LDAP_ADMIN_PASSWORD:	password for the admin account
# ORGANISATION_NAME

unset LDAP_AUTO_APPLY

LDAP_BASE_DN="${LDAP_BASE_DN:-"$(echo $LDAP_DOMAIN|sed 's/^/dc=/;s/\./,dc=/g')"}"
export CHANGES_SUFFIX="%SUFFIX%=$LDAP_BASE_DN"
export CHANGES_ONAME="%ORGANISATION_NAME%=$LDAP_ORGANISATION"

/bin/ldap_apply.sh /etc/openldap/organisation.ldif
