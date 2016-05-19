.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs example temp prod pull config passwords waitforport80

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make temp   - build and run docker container
	@echo ""   2. make grab   - grab persistent data directories
	@echo ""   3. make prod   - run production container with persistent directories
	@echo ""   4. make jabber - make a jabber container that connects to our new FreeIPA server

temp: TAG NAME IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS runtempCID waitforport80 templogs

# after letting temp settle you can `make grab` and grab the data directory for persistence
prod: TAG NAME IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS freeipaCID

jabber: prod FREEIPA_DOMAIN FREEIPA_EJABBER_LDAP_ROOTDN FREEIPA_EJABBER_LDAP_UID FREEIPA_EJABBER_LDAP_FILTER FREEIPA_EJABBER_LDAP_BASE FREEIPA_EJABBER_LDAP_PASS ejabberdCID

replica: NAME TAG FREEIPA_EJABBER_CLUSTER_PARENT replicaCID 

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
	-v `pwd`/portal/:/root/portal \
	-t $(TAG)
	@cp freeipaCID replicaCID

runtempCID:
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IPA_SERVER_IP := $(shell cat IPA_SERVER_IP))
	$(eval IPA_SERVER_INSTALL_OPTS := $(shell cat IPA_SERVER_INSTALL_OPTS))
	@docker run --name=$(NAME) \
	--cidfile="runtempCID" \
	-d \
	-e IPA_SERVER_IP=$(IPA_SERVER_IP) \
	-e IPA_SERVER_INSTALL_OPTS="$(IPA_SERVER_INSTALL_OPTS)" \
	-p 53:53/udp -p 53:53 \
	-p 80:80 -p 443:443 -p 389:389 -p 636:636 -p 88:88 -p 464:464 \
	-p 88:88/udp -p 464:464/udp -p 123:123/udp -p 7389:7389 \
	-p 9443:9443 -p 9444:9444 -p 9445:9445 \
	-h $(FREEIPA_FQDN) \
	-e PASSWORD=$(FREEIPA_MASTER_PASS) \
	-v `pwd`/portal/:/root/portal \
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
	-v `pwd`jabber.ldif:/root/jabber.ldif \
	-v `pwd`/portal/:/root/portal \
	-v $(FREEIPA_DATADIR):/data:Z \
	-t $(TAG)

kill:
	-@docker kill `cat freeipaCID`
	-@docker kill `cat replicaCID`
	-@docker kill `cat ejabberdCID`

rm-image:
	-@docker rm `cat freeipaCID`
	-@rm freeipaCID
	-@docker rm `cat replicaCID`
	-@rm replicaCID
	-@docker rm `cat ejabberdCID`
	-@rm ejabberdCID

rmtemp:
	-@docker kill `cat runtempCID`
	-@docker rm `cat runtempCID`
	-@rm runtempCID

rm: kill rm-image

rmjabber:
	-@docker kill `cat ejabberdCID`
	-@docker rm `cat ejabberdCID`
	-@rm ejabberdCID

clean: rmall

enter:
	@docker exec -i -t `cat freeipaCID` /bin/bash

logs:
	@docker logs -f `cat freeipaCID`

templogs:
	@docker logs -f `cat runtempCID`

jabberlogs:
	@docker logs -f `cat ejabberdCID`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container, hint `make example` [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

rmall: rm rmtemp

grab: FREEIPA_DATADIR ejabberDirs

FREEIPA_DATADIR:
	-mkdir -p datadir
	@docker cp `cat runtempCID`:/data  - |sudo tar -C datadir/ -pxvf -
	@echo `pwd`/datadir/data > FREEIPA_DATADIR

ejabberDirs:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	@mkdir -p "$(FREEIPA_DATADIR)/ejabberd/ssl"
	@mkdir -p "$(FREEIPA_DATADIR)/ejabberd/backup"
	@mkdir -p "$(FREEIPA_DATADIR)/ejabberd/upload"
	@mkdir -p "$(FREEIPA_DATADIR)/ejabberd/database"
	@chown -R 999:999 "$(FREEIPA_DATADIR)/ejabberd"

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
	@cp -i TAG.example TAG

entropy: entropyCID

entropyCID:
	@docker run --privileged \
	--cidfile="entropyCID" \
	-d \
	joshuacox/havegedocker:latest

auto: passwords config IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS runtempCID entropy waitforport80

config: configinit configcarry portal/jabber.ldif

configinit:
	@cp TAG.example TAG
	@echo 'freeipa' > NAME
	@curl -s icanhazip.com > IPA_SERVER_IP
	@/bin/bash ./config.sh
	@cut -f2,3 -d'.' FREEIPA_FQDN > FREEIPA_DOMAIN
	@cut -f2 -d'.' FREEIPA_FQDN > FREEIPA_SLD
	@cut -f3 -d'.' FREEIPA_FQDN > FREEIPA_TLD
	@echo 'uid' >FREEIPA_EJABBER_LDAP_UID

configcarry:
	$(eval FREEIPA_DOMAIN := $(shell cat FREEIPA_DOMAIN))
	$(eval FREEIPA_TLD := $(shell cat FREEIPA_TLD))
	$(eval FREEIPA_SLD := $(shell cat FREEIPA_SLD))
	@/bin/bash ./carry.sh

passwords:
	@tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_ERLANG_COOKIE
	@tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_MASTER_PASS
	@tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_LDAP_PASS

tempejabberdCID:
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
	--cidfile="tempejabberdCID" \
	-p 5222:5222 \
	--link $(NAME):freeipa \
	-p 5269:5269 \
	--restart=always \
	-p 5280:5280 \
	-p 5443:5443 \
	-p 4369:4369 \
	-h $(FREEIPA_FQDN) \
	-e "XMPP_DOMAIN=$(FREEIPA_DOMAIN)" \
	-e "ERLANG_NODE=ejabberd" \
	-e "TZ=America/Chicago" \
	-e "EJABBERD_ADMIN=admin@$(FREEIPA_DOMAIN)" \
	-e "EJABBERD_AUTH_METHOD=ldap" \
	-e "EJABBERD_WEB_ADMIN_SSL=true" \
	-e "EJABBERD_STARTTLS=true" \
	-e "EJABBERD_S2S_SSL=true" \
	-e "EJABBERD_LDAP_SERVERS=freeipa" \
	-e "EJABBERD_LDAP_ROOTDN=$(FREEIPA_EJABBER_LDAP_ROOTDN)" \
	-e "EJABBERD_LDAP_PASSWORD=$(FREEIPA_EJABBER_LDAP_PASS)" \
	-e "EJABBERD_LDAP_DEREF_ALIASES=always" \
	-e "EJABBERD_LDAP_BASE=$(FREEIPA_EJABBER_LDAP_BASE)" \
	-e "EJABBERD_LDAP_FILTER=$(FREEIPA_EJABBER_LDAP_FILTER)" \
	-e "EJABBERD_LDAP_UIDS=$(FREEIPA_EJABBER_LDAP_UID)" \
	rroemhild/ejabberd

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
	--cidfile="ejabberdCID" \
	-p 5222:5222 \
	--link $(NAME):freeipa \
	-p 5269:5269 \
	--restart=always \
	-p 5280:5280 \
	-p 5443:5443 \
	-p 4369:4369 \
	-h $(FREEIPA_FQDN) \
	-e "XMPP_DOMAIN=$(FREEIPA_DOMAIN)" \
	-e "ERLANG_NODE=ejabberd" \
	-e "ERLANG_COOKIE=$(FREEIPA_EJABBER_ERLANG_COOKIE)" \
	-e "TZ=America/Chicago" \
	-e "EJABBERD_ADMIN=admin@$(FREEIPA_DOMAIN)" \
	-e "EJABBERD_AUTH_METHOD=ldap" \
	-e "EJABBERD_WEB_ADMIN_SSL=true" \
	-e "EJABBERD_STARTTLS=true" \
	-e "EJABBERD_S2S_SSL=true" \
	-e "EJABBERD_LDAP_SERVERS=freeipa" \
	-e "EJABBERD_LDAP_ROOTDN=$(FREEIPA_EJABBER_LDAP_ROOTDN)" \
	-e "EJABBERD_LDAP_PASSWORD=$(FREEIPA_EJABBER_LDAP_PASS)" \
	-e "EJABBERD_LDAP_DEREF_ALIASES=always" \
	-e "EJABBERD_LDAP_BASE=$(FREEIPA_EJABBER_LDAP_BASE)" \
	-e "EJABBERD_LDAP_FILTER=$(FREEIPA_EJABBER_LDAP_FILTER)" \
	-e "EJABBERD_LDAP_UIDS=$(FREEIPA_EJABBER_LDAP_UID)" \
	-e "ERLANG_COOKIE=$(FREEIPA_EJABBER_ERLANG_COOKIE)" \
	-v "$(FREEIPA_DATADIR)/data/etc/letsencrypt/live/$(FREEIPA_FQDN):/opt/ejabberd/ssl" \
	-v "$(FREEIPA_DATADIR)/ejabberd/ssl:/opt/ejabberd/ssl" \
	-v "$(FREEIPA_DATADIR)/ejabberd/backup:/opt/ejabberd/backup" \
	-v "$(FREEIPA_DATADIR)/ejabberd/upload:/opt/ejabberd/upload" \
	-v "$(FREEIPA_DATADIR)/ejabberd/database:/opt/ejabberd/database" \
	rroemhild/ejabberd

 # For ejabberd view the docs here https://github.com/rroemhild/docker-ejabberd#cluster-example
 # not working yet
	#-v "$(FREEIPA_DATADIR)/ejabberd:/opt/ejabberd" \

cookie:
	@tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1 > FREEIPA_EJABBER_ERLANG_COOKIE

registerJabberReplicant: FREEIPA_EJABBER_CLUSTER_PARENT registerJabberReplicantMeat

registerJabberReplicantMeat:
	$(eval FREEIPA_EJABBER_CLUSTER_PARENT := $(shell cat FREEIPA_EJABBER_CLUSTER_PARENT))
	@docker exec `cat ejabberdCID` ejabberdctl join_cluster 'ejabberd@$(FREEIPA_EJABBER_CLUSTER_PARENT)'

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

renew: renewmeat host.pem

renewmeat:
	rm host.pem
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	docker run -it --rm -p 443:443 -p 80:80 --name certbot \
	-v "$(FREEIPA_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(FREEIPA_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest renew

hardclean:
	-rm  FREEIPA_*
	-rm  IPA_SERVER_*
	-rm -Rf portal
	-rm host.pem

updateUbuntuTrusty:
	apt-get update -y
	apt-get upgrade -y
	apt-get install linux-generic-lts-vivid linux-headers-generic-lts-vivid
	-@wget get.docker.com -O - | sh
	-@service docker stop
	-@echo 'DOCKER_OPTS="-s overlay"' >> /etc/default/docker
	-@echo 'you should reboot this VM to get the new kernel'
	#service docker start

pull:
	docker pull -t $(TAG)
	docker pull quay.io/letsencrypt/letsencrypt:latest
	docker pull rroemhild/ejabberd

portal/jabber.ldif:
	@/bin/bash ./jabberconf.sh

registerJabberServer:
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	-@docker exec -i -t `cat freeipaCID` /bin/bash -c 'echo "$(FREEIPA_MASTER_PASS)"|kinit admin'
	-@docker exec -i -t `cat freeipaCID` ipa group-add jabber_users --desc="Group used to validate Jabber authentication to allowed users"
	-@docker exec -i -t `cat freeipaCID` ldapmodify -h $(FREEIPA_FQDN) -p 389 -x -D "cn=Directory Manager" -w $(FREEIPA_MASTER_PASS) -f /root/portal/jabber.ldif

host.pem:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	cat $(FREEIPA_DATADIR)/etc/letsencrypt/live/$(FREEIPA_FQDN)/privkey.pem $(FREEIPA_DATADIR)/etc/letsencrypt/live/$(FREEIPA_FQDN)/privkey.pem > host.pem
	cp -i host.pem $(FREEIPA_DATADIR)/etc/letsencrypt/live/$(FREEIPA_FQDN)/

next: grab rmtemp nextmeat prod waitforport80 displaycreds

nextmeat:
	@mkdir -p /exports/freeipa
	@rm -Rf /exports/freeipa/datadir
	@mv datadir /exports/freeipa/
	@echo '/exports/freeipa/datadir/data' > FREEIPA_DATADIR

jabberinit: registerJabberServer

prepMaster:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	@while [ -z "$$REPLICANT_HOSTNAME" ]; do \
		read -r -p "Enter the replicant hostname you wish to associate with $(FREEIPA_FQDN) [REPLICANT_HOSTNAME]: " REPLICANT_HOSTNAME; echo "$$REPLICANT_HOSTNAME" > $(TMP)/REPLICANT_HOSTNAME; \
	done ;
	@while [ -z "$$REPLICANT_IP" ]; do \
		read -r -p "Enter the replicant hostname you wish to associate with $(FREEIPA_FQDN) [REPLICANT_IP]: " REPLICANT_IP; echo "$$REPLICANT_IP" > $(TMP)/REPLICANT_IP; \
	done ;
	@docker exec -i -t `cat freeipaCID` ipa-replica-prepare `cat $(TMP)/REPLICANT_HOSTNAME` --ip-address `cat $(TMP)/REPLICANT_IP` --password=$(FREEIPA_MASTER_PASS)
	@mkdir -p $(TMP)/mkFreeIPA
	@docker cp `cat freeipaCID`:/var/lib/ipa/replica-info-`cat $(TMP)/REPLICANT_HOSTNAME`.gpg - |sudo tar -C $(TMP)/mkFreeIPA -pxvf -
	@cp FREEIPA_MASTER_PASS $(TMP)/mkFreeIPA/
	@cp FREEIPA_MASTER_PASS $(TMP)/mkFreeIPA/FREEIPA_EJABBER_CLUSTER_PARENT
	@cp FREEIPA_EJABBER_ERLANG_COOKIE $(TMP)/mkFreeIPA/
	@cp FREEIPA_EJABBER_LDAP_PASS $(TMP)/mkFreeIPA/
	@cd $(TMP); tar zcvf mkFreeIPA.tgz mkFreeIPA;
	@rm -f /tmp/mkFreeIPA.tgz
	@mv $(TMP)/mkFreeIPA.tgz /tmp/
	@rm -Rf $(TMP)
	@echo "you should copy /tmp/mkFreeIPA.tgz to the replicant"

autoprepMaster:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	@while [ -z "$$REPLICANT_HOSTNAME" ]; do \
		read -r -p "Enter the replicant hostname you wish to associate with $(FREEIPA_FQDN) [REPLICANT_HOSTNAME]: " REPLICANT_HOSTNAME; echo "$$REPLICANT_HOSTNAME" > $(TMP)/REPLICANT_HOSTNAME; dig $$REPLICANT_HOSTNAME +short > $(TMP)/REPLICANT_IP; \
	done ;
	@docker exec -i -t `cat freeipaCID` ipa-replica-prepare `cat $(TMP)/REPLICANT_HOSTNAME` --ip-address `cat $(TMP)/REPLICANT_IP` --password=$(FREEIPA_MASTER_PASS)
	@mkdir -p $(TMP)/mkFreeIPA
	@docker cp `cat freeipaCID`:/var/lib/ipa/replica-info-`cat $(TMP)/REPLICANT_HOSTNAME`.gpg - |sudo tar -C $(TMP)/mkFreeIPA -pxvf -
	@cp FREEIPA_MASTER_PASS $(TMP)/mkFreeIPA/
	@cp FREEIPA_MASTER_PASS $(TMP)/mkFreeIPA/FREEIPA_EJABBER_CLUSTER_PARENT
	@cp FREEIPA_EJABBER_ERLANG_COOKIE $(TMP)/mkFreeIPA/
	@cp FREEIPA_EJABBER_LDAP_PASS $(TMP)/mkFreeIPA/
	@cd $(TMP); tar zcf mkFreeIPA.tgz mkFreeIPA
	@rm -f /tmp/mkFreeIPA.tgz
	@mv $(TMP)/mkFreeIPA.tgz /tmp/
	@rm -Rf $(TMP)
	@echo "you should copy /tmp/mkFreeIPA.tgz to the replicant"

prepReplica: passwords config untarMasterCreds prepReplicaMeat

prepReplicaMeat:
	$(eval FREEIPA_DATADIR := $(shell cat FREEIPA_DATADIR))
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	-@rm -Rf $(FREEIPA_DATADIR)
	-@mkdir -p $(FREEIPA_DATADIR)
	-@cp *.gpg  $(FREEIPA_DATADIR)/
	-@echo "--password=$(FREEIPA_MASTER_PASS)" > $(FREEIPA_DATADIR)/ipa-replica-install-options
	-@echo "--admin-password=$(FREEIPA_MASTER_PASS)" >> $(FREEIPA_DATADIR)/ipa-replica-install-options
	-@echo "--forwarder=8.8.8.8" >> $(FREEIPA_DATADIR)/ipa-replica-install-options

prepCentOS7:
	yum install -y bind-utils

displaycreds:
	$(eval FREEIPA_MASTER_PASS := $(shell cat FREEIPA_MASTER_PASS))
	$(eval FREEIPA_FQDN := $(shell cat FREEIPA_FQDN))
	-@echo "you should now login to your server at $(FREEIPA_FQDN) with user admin and pass= $(FREEIPA_MASTER_PASS)"

waitforport80:
	@echo "Waiting for port 80 to become available"
	@while ! curl --output /dev/null --silent --head --fail http://localhost; do sleep 10 && echo -n .; done;
	@echo "check port 80, it appears that now it is up!"

wait: waitforport80

untarMasterCreds:
	-@echo you need to copy FREEIPA_EJABBER_ERLANG_COOKIE FREEIPA_MASTER_PASS FREEIPA_EJABBER_LDAP_PASS from the parent server
	-@rm -Rf /exports/freeipa/datadir
	-@mkdir -p /exports/freeipa/datadir/data
	-@echo '/exports/freeipa/datadir/data' > FREEIPA_DATADIR
	-@echo attempting to get them now
	-@/bin/bash ./untar.sh
