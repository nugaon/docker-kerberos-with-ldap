#!/bin/bash

sleep 10

[[ "TRACE" ]] && set -x

: ${REALM:=EXAMPLE.COM}
: ${DOMAIN_REALM:=example.com}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}
: ${SEARCH_DOMAINS:=example.com}
: ${LDAP_DC:=dc=example,dc=com}
: ${LDAP_USER:=admin}
: ${LDAP_PASS:=admin}
: ${LDAP_URL:=ldap://ldap}

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

create_config() {
  KDC_ADDRESS=$(hostname -f)

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
  default_domain = $DOMAIN_REALM
  database_module = openldap_ldapconf
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM

[dbdefaults]
  ldap_kerberos_container_dn = cn=krbContainer,$LDAP_DC

[dbmodules]
  openldap_ldapconf = {
          db_library = kldap
          ldap_kdc_dn = "cn=$LDAP_USER,$LDAP_DC"

          # this object needs to have read rights on
          # the realm container, principal container and realm sub-trees
          ldap_kadmind_dn = "cn=$LDAP_USER,$LDAP_DC"

          # this object needs to have read and write rights on
          # the realm container, principal container and realm sub-trees
          ldap_service_password_file = /etc/krb5kdc/service.keyfile
          ldap_servers = $LDAP_URL
          ldap_conns_per_server = 5
  }
EOF
}

create_db() {
  kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

init_ldap() {
  kdb5_ldap_util -D cn=$LDAP_USER,$LDAP_DC create -subtrees $LDAP_DC -r $REALM -s -H $LDAP_URL <<EOF
$LDAP_PASS
$KERB_ADMIN_PASS
$KERB_ADMIN_PASS
EOF

  kdb5_ldap_util -D cn=$LDAP_USER.,$LDAP_DC stashsrvpw -f /etc/krb5kdc/service.keyfile cn=$LDAP_USER,$LDAP_DC <<EOF
$LDAP_PASS
$LDAP_PASS
$LDAP_PASS
EOF
}

start_kdc() {
  service krb5-kdc start
  service krb5-admin-server start
}

restart_kdc() {
  service krb5-kdc restart
  service krb5-admin-server restart
}

create_admin_user() {
  kadmin.local -q "addprinc -x dn=cn=$KERB_ADMIN_USER,$LDAP_DC admin" <<EOF
$LDAP_PASS
$LDAP_PASS
EOF
  echo "admin@$REALM *" > /etc/krb5kdc/kadm5.acl
}

if [ ! -f /kerberos_initialized ]; then
  mkdir -p /var/log/kerberos

  create_config
  init_ldap
  create_admin_user
  create_db
  start_kdc

  touch /kerberos_initialized
else
  start_kdc
fi

tail -F /var/log/kerberos/krb5kdc.log