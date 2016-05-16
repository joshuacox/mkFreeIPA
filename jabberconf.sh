#!/bin/bash
mkdir -p portal
cp -i templates/jabber.ldif.tpl portal/jabber.ldif
FREEIPA_TLD=$(cat FREEIPA_TLD)
FREEIPA_SLD=$(cat FREEIPA_SLD)
FREEIPA_EJABBER_LDAP_PASS=$(cat FREEIPA_EJABBER_LDAP_PASS)
sed -i "s/REPLACEME_TLD/$FREEIPA_TLD/g" portal/jabber.ldif
sed -i "s/REPLACEME_SLD/$FREEIPA_SLD/g" portal/jabber.ldif
sed -i "s/REPLACEME_PASS/$FREEIPA_EJABBER_LDAP_PASS/g" portal/jabber.ldif
