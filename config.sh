#!/bin/bash
	dig -x `cat IPA_SERVER_IP` +short | sed -r 's/\\.$//' > FREEIPA_FQDN
