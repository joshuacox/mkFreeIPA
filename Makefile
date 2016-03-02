.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs example temp prod

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

temp: TAG NAME IPA_SERVER_IP FREEIPA_FQDN FREEIPA_MASTER_PASS runtempCID

# after letting temp settle you can `make grab` and grab the data directory for persistence
prod: TAG NAME FREEIPA_FQDN FREEIPA_MASTER_PASS freeipaCID

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
	-@docker rm `cat runtempCID`
	-@rm runtempCID

rm: kill rm-image

clean: rmall

enter:
	docker exec -i -t `cat freeipaCID` /bin/bash

logs:
	docker logs -f `cat freeipaCID`

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
	docker cp `cat freeipaCID`:/data  - |sudo tar -C datadir/ -pxvf -
	echo `pwd`/datadir/data > FREEIPA_DATADIR

FREEIPA_FQDN:
	@while [ -z "$$FREEIPA_FQDN" ]; do \
		read -r -p "Enter the FQDN you wish to associate with this container [FREEIPA_FQDN]: " FREEIPA_FQDN; echo "$$FREEIPA_FQDN">>FREEIPA_FQDN; cat FREEIPA_FQDN; \
	done ;

IPA_SERVER_IP:
	@while [ -z "$$IPA_SERVER_IP" ]; do \
		read -r -p "Enter the public IP address of this container [IPA_SERVER_IP]: " IPA_SERVER_IP; echo "$$IPA_SERVER_IP">>IPA_SERVER_IP; cat IPA_SERVER_IP; \
	done ;

FREEIPA_MASTER_PASS:
	@while [ -z "$$FREEIPA_MASTER_PASS" ]; do \
		read -r -p "Enter the Master password you wish to associate with this container [FREEIPA_MASTER_PASS]: " FREEIPA_MASTER_PASS; echo "$$FREEIPA_MASTER_PASS">>FREEIPA_MASTER_PASS; cat FREEIPA_MASTER_PASS; \
	done ;

example:
	cp -i TAG.example TAG
