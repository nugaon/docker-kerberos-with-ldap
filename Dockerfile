FROM ubuntu

LABEL MAINTAINER nugaon <toth.viktor.levente@gmail.com>

# kerberos
RUN apt-get update -y && apt-get install -y krb5-kdc-ldap krb5-admin-server \
ldap-utils

EXPOSE 88 464 749

ADD ./config.sh /config.sh

ENTRYPOINT ["/config.sh"]
