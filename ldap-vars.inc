# vim: set filetype=sh:

# Have to explicity tell the openldap utilies (ldapsearch)
# where to find the list of valid CA's
export LDAPTLS_CACERT=/etc/pki/tls/certs/ca-bundle.crt

# LDAP connection details
ldaphost="dsa01.dfw01.socius.strings-service.net"
ldapbinddn="uid=...,dc=example-infra,dc=net"
ldappass=""
ldapbasedn="dc=example-infra,dc=net"
