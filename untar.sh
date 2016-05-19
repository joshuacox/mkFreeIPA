#!/bin/bash

if [ ! -f ../mkFreeIPA.tgz  ]; then
  (>&2 echo "../mkFreeIPA.tgz not found! you will need to copy this from the Master after completing prepMaster on the Master")
fi ;

if [ -f ../mkFreeIPA.tgz  ]; then
  cd ../; tar zxvf mkFreeIPA.tgz
  echo 0
fi ;
