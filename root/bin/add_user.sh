#!/bin/sh

# REQUIRED ENV VARS:
# LDAP_URI: 		URI to connect to the LDAP server
# LDAP_BASE_DN: 	exemple : dc=example,dc=com
# LDAP_ADMIN_PASSWORD:	password for the admin account
# USER_UID:		UID of tthe user
# USER_GIVEN_NAME
# USER_SURNAME
# USER_PW
# USER_EMAIL

unset LDAP_AUTO_APPLY

LDAP_BASE_DN="${LDAP_BASE_DN:-"$(echo $LDAP_DOMAIN|sed 's/^/dc=/;s/\./,dc=/g')"}"
export CHANGES_SUFFIX="%SUFFIX%=$LDAP_BASE_DN"
export CHANGES_UID="%USER_UID%=$USER_UID"
export CHANGES_GIVEN="%USER_GIVEN_NAME%=$USER_GIVEN_NAME"
export CHANGES_SURNAME="%USER_SURNAME%=$USER_SURNAME"
export CHANGES_PW="%USER_PW%=$(slappasswd -s "$USER_PW")"
export CHANGES_EMAIL="%USER_EMAIL%=$USER_EMAIL"
export CHANGES_ORG="%USER_ORG%=${USER_ORG:-""}"

/bin/ldap_apply.sh /etc/openldap/users.ldif
