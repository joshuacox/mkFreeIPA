.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs example temp prod pull

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make temp   - build and run docker container
	@echo ""   2. make grab   - grab persistent data directories
	@echo ""   3. make prod   - run production container with persistent directories
	@echo ""   4. make jabber - make a jabber container that connects to our new FreeIPA server

temp: TAG NAME IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS runtempCID templogs

# after letting temp settle you can `make grab` and grab the data directory for persistence
prod: TAG NAME IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS freeipaCID

jabber: prod FREEIPA_DOMAIN FREEIPA_EJABBER_LDAP_ROOTDN FREEIPA_EJABBER_LDAP_UID FREEIPA_EJABBER_LDAP_FILTER FREEIPA_EJABBER_LDAP_BASE FREEIPA_EJABBER_LDAP_PASS ejabberdCID

replica: FREEIPA_EJABBER_CLUSTER_PARENT replicaCID ejabberdCID registerJabberReplicant

replicaCID:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	@docker run --name=$(NAME) \
	--cidfile="freeipaCID" \
	-d \
	-p 53:53/udp -p 53:53 \
	-p 80:80 -p 443:443 -p 389:389 -p 636:636 -p 88:88 -p 464:464 \
	-p 88:88/udp -p 464:464/udp -p 123:123/udp -p 7389:7389 \
	-p 9443:9443 -p 9444:9444 -p 9445:9445 \
	-h $(FREEIPA_FQDN) \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
	-v $(FREEIPA_DATADIR):/data:Z \
	-t $(TAG)
	docker ps -ql >replicaCID

runtempCID:
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IPA_SERVER_IP := $(shell cat IPA_SERVER_IP))
	@docker run --name=$(NAME) \
	--cidfile="runtempCID" \
	-d \
	-e IPA_SERVER_IP=$(IPA_SERVER_IP) \
	-p 53:53/udp -p 53:53 \
	-p 80:80 -p 443:443 -p 389:389 -p 636:636 -p 88:88 -p 464:464 \
	-p 88:88/udp -p 464:464/udp -p 123:123/udp -p 7389:7389 \
	-p 9443:9443 -p 9444:9444 -p 9445:9445 \
	-h $(FREEIPA_FQDN) \
	-e PASSWORD=$(FREEIPA_MASTER_PASS) \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
	-t $(TAG)

freeipaCID:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IPA_SERVER_IP := $(shell cat IPA_SERVER_IP))
	@docker run --name=$(NAME) \
	--cidfile="freeipaCID" \
	-d \
	-e IPA_SERVER_IP=$(IPA_SERVER_IP) \
	-p 53:53/udp -p 53:53 \
	-p 80:80 -p 443:443 -p 389:389 -p 636:636 -p 88:88 -p 464:464 \
	-p 88:88/udp -p 464:464/udp -p 123:123/udp -p 7389:7389 \
	-p 9443:9443 -p 9444:9444 -p 9445:9445 \
	-h $(FREEIPA_FQDN) \
	-e PASSWORD=$(FREEIPA_MASTER_PASS) \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
	-v $(FREEIPA_DATADIR):/data:Z \
	-t $(TAG)

kill:
	-@docker kill `cat freeipaCID`

rm-image:
	-@docker rm `cat freeipaCID`
	-@rm freeipaCID

rmtemp:
	-@docker kill `cat runtempCID`
	-@docker rm `cat runtempCID`
	-@rm runtempCID

rm: kill rm-image

clean: rmall

pull:
	docker pull `cat TAG`

enter:
	docker exec -i -t `cat freeipaCID` /bin/bash

logs:
	docker logs -f `cat freeipaCID`

templogs:
	docker logs -f `cat runtempCID`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container, hint `make example` [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

rmall: rm rmtemp

grab: FREEIPA_DATADIR

FREEIPA_DATADIR:
	-mkdir -p datadir
	docker cp `cat runtempCID`:/data  - |sudo tar -C datadir/ -pxvf -
	echo `pwd`/datadir/data > FREEIPA_DATADIR

FREEIPA_FQDN:
	@while [ -z "$$FREEIPA_FQDN" ]; do \
		read -r -p "Enter the FQDN you wish to associate with this container [FREEIPA_FQDN]: " FREEIPA_FQDN; echo "$$FREEIPA_FQDN">>FREEIPA_FQDN; cat FREEIPA_FQDN; \
	done ;

FREEIPA_EJABBER_ERLANG_COOKIE:
	@while [ -z "$$FREEIPA_EJABBER_ERLANG_COOKIE" ]; do \
		read -r -p "Enter the EJABBER_ERLANG_COOKIE you wish to associate with this container [FREEIPA_EJABBER_ERLANG_COOKIE]: " FREEIPA_EJABBER_ERLANG_COOKIE; echo "$$FREEIPA_EJABBER_ERLANG_COOKIE">>FREEIPA_EJABBER_ERLANG_COOKIE; cat FREEIPA_EJABBER_ERLANG_COOKIE; \
	done ;

FREEIPA_EJABBER_LDAP_ROOTDN:
	@while [ -z "$$FREEIPA_EJABBER_LDAP_ROOTDN" ]; do \
		read -r -p "Enter the EJABBER_LDAP_ROOTDN you wish to associate with this container [FREEIPA_EJABBER_LDAP_ROOTDN]: " FREEIPA_EJABBER_LDAP_ROOTDN; echo "$$FREEIPA_EJABBER_LDAP_ROOTDN">>FREEIPA_EJABBER_LDAP_ROOTDN; cat FREEIPA_EJABBER_LDAP_ROOTDN; \
	done ;

FREEIPA_EJABBER_CLUSTER_PARENT:
	@while [ -z "$$FREEIPA_EJABBER_CLUSTER_PARENT" ]; do \
		read -r -p "Enter the EJABBER_CLUSTER_PARENT you wish to associate with this container [FREEIPA_EJABBER_CLUSTER_PARENT]: " FREEIPA_EJABBER_CLUSTER_PARENT; echo "$$FREEIPA_EJABBER_CLUSTER_PARENT">>FREEIPA_EJABBER_CLUSTER_PARENT; cat FREEIPA_EJABBER_CLUSTER_PARENT; \
	done ;

FREEIPA_EJABBER_LDAP_PASS:
	@while [ -z "$$FREEIPA_EJABBER_LDAP_PASS" ]; do \
		read -r -p "Enter the EJABBER_LDAP_PASS you wish to associate with this container [FREEIPA_EJABBER_LDAP_PASS]: " FREEIPA_EJABBER_LDAP_PASS; echo "$$FREEIPA_EJABBER_LDAP_PASS">>FREEIPA_EJABBER_LDAP_PASS; cat FREEIPA_EJABBER_LDAP_PASS; \
	done ;

FREEIPA_EJABBER_LDAP_BASE:
	@while [ -z "$$FREEIPA_EJABBER_LDAP_BASE" ]; do \
		read -r -p "Enter the EJABBER_LDAP_BASE you wish to associate with this container [FREEIPA_EJABBER_LDAP_BASE]: " FREEIPA_EJABBER_LDAP_BASE; echo "$$FREEIPA_EJABBER_LDAP_BASE">>FREEIPA_EJABBER_LDAP_BASE; cat FREEIPA_EJABBER_LDAP_BASE; \
	done ;

FREEIPA_EJABBER_LDAP_FILTER:
	@while [ -z "$$FREEIPA_EJABBER_LDAP_FILTER" ]; do \
		read -r -p "Enter the EJABBER_LDAP_FILTER you wish to associate with this container [FREEIPA_EJABBER_LDAP_FILTER]: " FREEIPA_EJABBER_LDAP_FILTER; echo "$$FREEIPA_EJABBER_LDAP_FILTER">>FREEIPA_EJABBER_LDAP_FILTER; cat FREEIPA_EJABBER_LDAP_FILTER; \
	done ;

FREEIPA_EJABBER_LDAP_UID:
	@while [ -z "$$FREEIPA_EJABBER_LDAP_UID" ]; do \
		read -r -p "Enter the EJABBER_LDAP_UID you wish to associate with this container [FREEIPA_EJABBER_LDAP_UID]: " FREEIPA_EJABBER_LDAP_UID; echo "$$FREEIPA_EJABBER_LDAP_UID">>FREEIPA_EJABBER_LDAP_UID; cat FREEIPA_EJABBER_LDAP_UID; \
	done ;

FREEIPA_DOMAIN:
	@while [ -z "$$FREEIPA_DOMAIN" ]; do \
		read -r -p "Enter the DOMAIN you wish to associate with this container [FREEIPA_DOMAIN]: " FREEIPA_DOMAIN; echo "$$FREEIPA_DOMAIN">>FREEIPA_DOMAIN; cat FREEIPA_DOMAIN; \
	done ;

IPA_SERVER_IP:
	@while [ -z "$$IPA_SERVER_IP" ]; do \
		read -r -p "Enter the public IP address of this container [IPA_SERVER_IP]: " IPA_SERVER_IP; echo "$$IPA_SERVER_IP">>IPA_SERVER_IP; \
	done ;

FREEIPA_MASTER_PASS: SHELL:=/bin/bash
FREEIPA_MASTER_PASS:
	@while [ -z "$$FREEIPA_MASTER_PASS" ]; do \
	 	read -r -e -s -p "Enter the Master password you wish to associate with this container [FREEIPA_MASTER_PASS]: " FREEIPA_MASTER_PASS; echo "$$FREEIPA_MASTER_PASS">>FREEIPA_MASTER_PASS;  \
	done ;
	echo ' '

example:
	cp -i TAG.example TAG

entropy:
	docker run --privileged -d joshuacox/havegedocker:latest

config: configinit configcarry

configinit:
	cp -i TAG.example TAG
	curl icanhazip.com > IPA_SERVER_IP
	dig -x `cat IPA_SERVER_IP` +short | sed 's/\.$//' > FREEIPA_FQDN
	cut -f2,3 -d'.' FREEIPA_FQDN > FREEIPA_DOMAIN
	cut -f2 -d'.' FREEIPA_FQDN > FREEIPA_SLD
	cut -f3 -d'.' FREEIPA_FQDN > FREEIPA_TLD
	echo 'uid' >FREEIPA_EJABBER_LDAP_UID

configcarry:
	$(eval FREEIPA_DOMAIN := $(shell cat FREEIPA_DOMAIN))
	$(eval FREEIPA_TLD := $(shell cat FREEIPA_TLD))
	$(eval FREEIPA_SLD := $(shell cat FREEIPA_SLD))
	$(eval FREEIPA_EJABBER_LDAP_FILTER := $(shell echo  "(memberOf=cn=jabber_users,cn=groups,cn=accounts,dc=$(FREEIPA_SLD),dc=$(FREEIPA_TLD))"))
	echo $(FREEIPA_EJABBER_LDAP_FILTER) > FREEIPA_EJABBER_LDAP_FILTER
	$(eval FREEIPA_EJABBER_LDAP_BASE := $(shell echo  "dc=$(FREEIPA_SLD),dc=$(FREEIPA_TLD))"))
	echo $(FREEIPA_EJABBER_LDAP_BASE) > FREEIPA_EJABBER_LDAP_BASE
	$(eval FREEIPA_EJABBER_LDAP_ROOTDN := $(shell echo  "uid=ejabberd,cn=sysaccounts,cn=etc,dc=$(FREEIPA_SLD),dc=$(FREEIPA_TLD))"))
	echo $(FREEIPA_EJABBER_LDAP_ROOTDN) > FREEIPA_EJABBER_LDAP_ROOTDN
	tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_ERLANG_COOKIE
	tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_MASTER_PASS
	tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_LDAP_PASS


ejabberdCID:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval FREEIPA_DOMAIN := $(shell cat FREEIPA_DOMAIN))
	$(eval FREEIPA_EJABBER_LDAP_ROOTDN := $(shell cat FREEIPA_EJABBER_LDAP_ROOTDN))
	$(eval FREEIPA_EJABBER_LDAP_PASS := $(shell cat FREEIPA_EJABBER_LDAP_PASS))
	$(eval FREEIPA_EJABBER_LDAP_BASE := $(shell cat FREEIPA_EJABBER_LDAP_BASE))
	$(eval FREEIPA_EJABBER_LDAP_FILTER := $(shell cat FREEIPA_EJABBER_LDAP_FILTER))
	$(eval FREEIPA_EJABBER_LDAP_UID := $(shell cat FREEIPA_EJABBER_LDAP_UID))
	$(eval FREEIPA_EJABBER_ERLANG_COOKIE := $(shell cat FREEIPA_EJABBER_ERLANG_COOKIE))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IPA_SERVER_IP := $(shell cat IPA_SERVER_IP))
	docker run -d \
	--name "ejabberd" \
	--cidfile="ejabbderdCID" \
	-p 5222:5222 \
	-p 5269:5269 \
	--restart=always \
	-p 5280:5280 \
	-p 5443:5443 \
	-h $(FREEIPA_FQDN) \
	-e "XMPP_DOMAIN=$(FREEIPA_DOMAIN) \
	-e "ERLANG_NODE=ejabberd" \
	-e "ERLANG_COOKIE=$(FREEIPA_EJABBER_ERLANG_COOKIE)" \
	-e "TZ=America/Chicago" \
	-e "EJABBERD_ADMIN=admin@$(FREEIPA_DOMAIN)" \
	-e "EJABBERD_AUTH_METHOD=ldap" \
	-e "EJABBERD_WEB_ADMIN_SSL=true" \
	-e "EJABBERD_STARTTLS=true" \
	-e "EJABBERD_S2S_SSL=true" \
	-e "EJABBERD_LDAP_SERVERS=$(FREEIPA_FQDN)" \
	-e "EJABBERD_LDAP_ROOTDN=$(FREEIPA_EJABBER_LDAP_ROOTDN)" \
	-e "EJABBERD_LDAP_PASSWORD=$(FREEIPA_EJABBER_LDAP_PASS)" \
	-e "EJABBERD_LDAP_DEREF_ALIASES=always" \
	-e "EJABBERD_LDAP_BASE=$(FREEIPA_EJABBER_LDAP_BASE)" \
	-e "EJABBERD_LDAP_FILTER=$(FREEIPA_EJABBER_LDAP_FILTER)" \
	-e "EJABBERD_LDAP_UIDS=$(FREEIPA_EJABBER_LDAP_UID)" \
	-v "/exports/whc-ejabberd/ssl:/opt/ejabberd/ssl" \
	rroemhild/ejabberd

 # View the docs here https://github.com/rroemhild/docker-ejabberd#cluster-example
 # This is a local copy for quick reference of the main values
	# -e "EJABBERD_ADMIN_RANDPWD=true" \
	# -v "/exports/whc-ejabberd/database:/opt/ejabberd/database" \
	# -v "/exports/whc-ejabberd/conf:/opt/ejabberd/conf" \
	#EJABBERD_LDAP_SERVERS: List of IP addresses or DNS names of your LDAP servers. This option is required.
	#EJABBERD_LDAP_ENCRYPT: The value tls enables encryption by using LDAP over SSL. The default value is: none.
	#EJABBERD_LDAP_TLS_VERIFY: false|soft|hard This option specifies whether to verify LDAP server certificate or not when TLS is enabled. The default is false which means no checks are performed.
	#EJABBERD_LDAP_TLS_CACERTFILE: Path to file containing PEM encoded CA certificates.
	#EJABBERD_LDAP_TLS_DEPTH: Specifies the maximum verification depth when TLS verification is enabled. The default value is 1.
	#EJABBERD_LDAP_PORT: The default port is 389 if encryption is disabled; and 636 if encryption is enabled.
	#EJABBERD_LDAP_ROOTDN: Bind DN. The default value is "" which means ‘anonymous connection’.
	#EJABBERD_LDAP_PASSWORD: Bind password. The default value is "".
	#EJABBERD_LDAP_DEREF_ALIASES: never|always|finding|searching Whether or not to dereference aliases. The default is never.
	#EJABBERD_LDAP_BASE: LDAP base directory which stores users accounts. This option is required.
	#EJABBERD_LDAP_UIDS: ldap_uidattr:ldap_uidattr_format The default attributes are uid:%u.
	#EJABBERD_LDAP_FILTER: RFC 4515 LDAP filter. The default Filter value is undefined.
	#EJABBERD_LDAP_DN_FILTER: { Filter: FilterAttrs } This filter is applied on the results returned by the main filter. By default ldap_dn_filter is undefined.

cookie:
	tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_ERLANG_COOKIE

registerJabberReplicant:
	docker exec `cat ejabberdCID` ejabberdctl join_cluster 'ejabberd@$(FREEIPA_EJABBER_CLUSTER_PARENT)'

replicant: replica

cert:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	@while [ -z "$$EMAIL" ]; do \
		read -r -p "Enter the contact email you wish to associate with $(FREEIPA_FQDN) [EMAIL]: " EMAIL; echo "$$EMAIL" > $(TMP)/EMAIL; \
	done ;
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	docker run -it --rm -p 443:443 -p 80:80 --name certbot \
	-v "$(FREEIPA_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(FREEIPA_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest auth --standalone -n -d "$(FREEIPA_FQDN)" --agree-tos --email "`cat $(TMP)/EMAIL`"
	rm -Rf $(TMP)

renew:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	docker run -it --rm -p 443:443 -p 80:80 --name certbot \
	-v "$(FREEIPA_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(FREEIPA_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest renew

