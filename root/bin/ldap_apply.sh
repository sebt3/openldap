#!/bin/sh
# REQUIRED ENV VARS:
# LDAP_URI: 		URI to connect to the LDAP server
# LDAP_DOMAIN:		exemple.com
# LDAP_BASE_DN: 	may derive from LDAP_DOMAIN, exemple : dc=example,dc=com
# LDAP_ADMIN_PASSWORD:	password for the admin account

#if you set LDAP_AUTO_APPLY, then all the *.ldif files from /ldif/ will be a

# exemple usage, set var :
# CHANGES_myKey="mykey=new values"
updateFile() {
	local FILE=$1
	local KEY VAL SRC DESC
	cp -f $FILE /tmp
	FILE=/tmp/$(basename $FILE)
	for KEY in $(set|awk -F= 'NF>2&&$1~/^CHANGES_.*$/{print $1}');do 
		VAL=$(eval echo \${$KEY})
		SRC=$(echo $VAL|sed 's/=.*//');
		DEST=$(echo $VAL|sed "s/^$SRC=//")
		sed -i "s/$SRC/$DEST/g" "$FILE"
	done
	echo $FILE
}

LDAP_BASE_DN="${LDAP_BASE_DN:-"$(echo $LDAP_DOMAIN|sed 's/^/dc=/;s/\./,dc=/g')"}"

ldapApply() {
	local LDIF_FILE=$(updateFile "$1")

	if grep -iq changetype "$LDIF_FILE" ; then
		ldapmodify -H "${LDAP_URI:-"ldap:///"}" -D "cn=admin,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" -f "$LDIF_FILE"
	else
		ldapadd -H "${LDAP_URI:-"ldap:///"}" -D "cn=admin,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" -f "$LDIF_FILE"
	fi
}

waitDirectory() {
	local cnt=0
	while ldapsearch -H "${LDAP_URI:-"ldap:///"}" -D "cn=admin,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" -LL -b $LDAP_BASE_DN 2>&1|grep -q "Can't contact LDAP server";do
		echo "LDAP server ($LDAP_URI) is not ready yet.... cnt=$((cnt+=1))"
		sleep 5
	done
}

waitDirectory
if [ -z "$LDAP_AUTO_APPLY" ];then
	for i in "$@";do
		ldapApply "$i"
	done
else
	for i in /ldif/*.ldif;do
		ldapApply "$i"
	done
fi
exit 0
