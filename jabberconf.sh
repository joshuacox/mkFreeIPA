#!/bin/bash
cp -i templates/jabber.ldif.tpl jabber.ldif
FREEIPA_TLD=$(cat FREEIPA_TLD)
FREEIPA_SLD=$(cat FREEIPA_SLD)
FREEIPA_EJABBER_LDAP_PASS=$(cat FREEIPA_EJABBER_LDAP_PASS)
sed -i "s/REPLACEME_TLD/$FREEIPA_TLD/g" jabber.ldif
sed -i "s/REPLACEME_SLD/$FREEIPA_SLD/g" jabber.ldif
sed -i "s/REPLACEME_PASS/$FREEIPA_EJABBER_LDAP_PASS/g" jabber.ldif
