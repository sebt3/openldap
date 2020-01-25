#!/bin/sh
# docker entrypoint script
# configures and starts LDAP

LDAP_BASE_DN="${LDAP_BASE_DN:-"$(echo $LDAP_DOMAIN|sed 's/^/dc=/;s/\./,dc=/g')"}"

# test for ldaps configuration
LDAPS=true
if [ -z "$KEY_FILE" ] || [ -z "$CERT_FILE" ] || [ -z "$CA_FILE" ]; then
	LDAPS=false
fi

if [ "$LDAPS" = true ]; then
	# ensure certificates exist
	RETRY=0
	MAX_RETRIES=3
	until [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ] && [ -f "$CA_FILE" ] || [ "$RETRY" -eq "$MAX_RETRIES" ]; do
		RETRY=$((RETRY+1))
		echo "Cannot find certificates. Retry ($RETRY/$MAX_RETRIES) ..."
		sleep 1
	done

	# exit if no certificates were found after maximum retries
	if [ "$RETRY" -eq "$MAX_RETRIES" ]; then
		echo "Cannot start ldap, the following certificates do not exist"
		echo " CA_FILE:   $CA_FILE"
		echo " KEY_FILE:  $KEY_FILE"
		echo " CERT_FILE: $CERT_FILE"
		exit 1
	fi

fi
CREATE_ORG=0
[ ! -f "/var/lib/ldap/data.mdb" ] && CREATE_ORG=1

# replace variables in slapd.conf
SLAPD_CONF="/etc/openldap/slapd.conf"
confSed() { sed -i "$1" "$SLAPD_CONF"; }
confSet() { confSed "s~%$1%~$2~g"; }
if [ "$LDAPS" = true ]; then
	confSet CA_FILE "$CA_FILE"
	confSet KEY_FILE "$KEY_FILE"
	confSet CERT_FILE "$CERT_FILE"
	if [ -n "$TLS_VERIFY_CLIENT" ]; then
		confSed "/TLSVerifyClient/ s/demand/$TLS_VERIFY_CLIENT/"
	fi
else
	# comment out TLS configuration
	confSed "s~TLSCACertificateFile~#&~"
	confSed "s~TLSCertificateKeyFile~#&~"
	confSed "s~TLSCertificateFile~#&~"
	confSed "s~TLSVerifyClient~#&~"
fi

confSet ROOT_USER "$LDAP_ROOT_USER"
confSet SUFFIX "$LDAP_BASE_DN"
confSet ACCESS_CONTROL "$ACCESS_CONTROL"
confSet ROOT_PW "$(slappasswd -s "$LDAP_ADMIN_PASSWORD")"
confSet CONFIG_PW "$(slappasswd -s "$LDAP_CONFIG_PASSWORD")"
if ! [ -d "/etc/ldap/slapd.d/cn=config" ];then
	echo "Bootstrapping configuration"
	mkdir -p /etc/ldap/slapd.d/
	slapadd -l /dev/null -f "$SLAPD_CONF"
	slaptest -f "$SLAPD_CONF" -F /etc/ldap/slapd.d/
	slapindex
fi
cat >/etc/openldap/ldap.conf <<END
BASE   $LDAP_BASE_DN
URI    ldap://localhost
END

if [ $# -ne 0 ];then
	echo "Starting $@"
	exec "$@"
else
	if [ $CREATE_ORG -eq 1 ];then
		echo "Starting the initial population process"
		sh /bin/create_org.sh &
	fi
	ulimit -n 1024
	if [ "$LDAPS" = true ]; then
		echo "Starting LDAPS"
		exec slapd -d "$LOG_LEVEL" -h "ldaps:///" -F /etc/ldap/slapd.d/
	else
		echo "Starting LDAP"
		exec slapd -d "$LOG_LEVEL" -h "ldap:///" -F /etc/ldap/slapd.d/
	fi
fi
