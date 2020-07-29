## Docker kerberos
This image is for testing purposes for Kerberos/LDAP environments. 
With this Kerberos image you can initialize an Ubuntu based Kerberos server with LDAP connections.
The whole project based on `mrenouf/docker-images` repository, but this codebase is not compatible with that.

# Quick start
> docker run -d --net docker_overlay -v /dev/urandom:/dev/random --name kerberos nugaon/kerberos-with-ldap

The containers have a pretty bad entropy level so the KDC won't start because of this. We can overcome this by using `/dev/urandom` which is less secure but does not care about entropy. 
Obviously, this Kerberos container has to be run on the same network as the ldap container or make it possible to reach the outsider LDAP server. For the former case,
I suggest for you to use my compatible LDAP docker with Kerberos image `nugaon/openldap-with-kerberos`, 
that you can find on [GitHub](https://github.com/nugaon/docker-openldap-with-kerberos) as well.

Useful environment variables:

| Environment variables | Description                   | Default value            |
| --------------------- | ----------------------------- | ------------------------ |
| `REALM`               | the Kerberos realm            | EXAMPLE.COM              |
| `DOMAIN_REALM`        | the DNS domain for the realm  | example.com              |
| `KERB_MASTER_KEY`     | master key for the KDC        | masterkey                |
| `KERB_ADMIN_USER`     | administrator account name    | admin                    |
| `KERB_ADMIN_PASS`     | administrator's password      | admin                    |
| `SEARCH_DOMAINS`      | domain suffix search list     | example.com              |
| `LDAP_DC`             | domain suffix search list     | dc=example,dc=com        |
| `LDAP_USER`           | ldap service user             | admin                    |
| `LDAP_PASS`           | ldap service pass             | admin                    |
| `LDAP_URL`            | ldap url                      | ldap://ldap              |

# Bind LDAP user to Kerberos DB
If you add new users in LDAP you have to register them in Kerberos as well in order to utilize Kerberos authentication. It is possible by the following command:
> docker exec -ti $KERBEROS_CONTAINER kadmin.local -q 'addprinc -x dn=$USER_DN $USER_KERB_NAME'

example
> docker exec -ti kerberos kadmin.local -q 'addprinc -x dn=cn=Teszt" "Elek,cn=users,dc=ldap,dc=hiflylabs,dc=hu telek'

# Test
Once kerberos is enabled you need a `ticket` to execute any job on the cluster. Here's an example to get a ticket:
> docker exec -ti kerberos sh -c "kinit admin && klist"

It authenticates the LDAP associated admin user by the Kerberos server.