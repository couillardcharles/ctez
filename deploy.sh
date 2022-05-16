#!/usr/bin/env bash
set -x

mkdir _build

# Modify as need to deploy on different networks
LIGO="docker run --rm -v "${PWD}":"${PWD}" -w "${PWD}" ligolang/ligo:0.42.0"
TZC="tezos-client -E https://ithacanet.ecadinfra.com/"

deployment_key="alice"
deployment_key_address=`tz1THJRdgsBA11ffM76p4PQm7jxHuwMZ8vQy`

DEPLOYMENT_DATE=$(date '+%Y-%m-%d')

# Build and deploy ctez
$LIGO compile contract ctez.mligo -e main -p ithaca > _build/ctez.tz
$LIGO compile storage ctez.mligo -e main -p ithaca "$(sed s/DEPLOYMENT_DATE/${DEPLOYMENT_DATE}/ < ctez_initial_storage.mligo)" > _build/ctez_storage.tz
$TZC originate contract ctez transferring 0 from $deployment_key running 'file:_build/ctez.tz' --init "$(<_build/ctez_storage.tz)" --burn-cap 10
CTEZ_ADDRESS=`$TZC show known contract ctez`

# Build and deploy the fa12 for ctez
$LIGO compile contract fa12.mligo -e main -p ithaca > _build/fa12.tz
$LIGO compile storage fa12.mligo -e main -p ithaca "$(sed s/ADMIN_ADDRESS/$CTEZ_ADDRESS/ < fa12_ctez_initial_storage.mligo)" > _build/fa12_ctez_storage.tz
$TZC originate contract fa12_ctez transferring 0 from $deployment_key running 'file:_build/fa12.tz' --init "$(<_build/fa12_ctez_storage.tz)" --burn-cap 10
FA12_CTEZ_ADDRESS=`$TZC show known contract fa12_ctez`

# Build and deploy cfmm
$LIGO compile contract cfmm_tez_ctez.mligo -e main -p ithaca > _build/cfmm.tz
sed s/FA12_CTEZ/${FA12_CTEZ_ADDRESS}/ < cfmm_initial_storage.mligo | sed s/CTEZ_ADDRESS/${CTEZ_ADDRESS}/ > _build/cfmm_storage.mligo

$LIGO compile storage cfmm_tez_ctez.mligo -e main -p ithaca "$(<_build/cfmm_storage.mligo)" > _build/cfmm_storage.tz
$TZC originate contract cfmm transferring 0.000001 from $deployment_key running 'file:_build/cfmm.tz' --init "$(<_build/cfmm_storage.tz)" --burn-cap 10
CFMM_ADDRESS=`$TZC show known contract cfmm`

# Build and deploy the fa12 for the cfmm lqt, specifying the cfmm as admin
$LIGO compile storage fa12.mligo -e main -p ithaca "$(sed s/ADMIN_ADDRESS/$CFMM_ADDRESS/ < fa12_ctez_initial_storage.mligo)" > _build/fa12_lqt_storage.tz
$TZC originate contract fa12_lqt transferring 0 from $deployment_key running 'file:_build/fa12.tz' --init "$(<_build/fa12_lqt_storage.tz)" --burn-cap 10
FA12_LQT_ADDRESS=`$TZC show known contract fa12_lqt`

# Set the lqt fa12 address in the cfmm
$TZC transfer 0 from $deployment_key to cfmm --entrypoint setLqtAddress --arg "\"$FA12_LQT_ADDRESS\"" --burn-cap 10

# Set the ctez fa12 address and the cfmm address in the oven management contract
$TZC transfer 0 from $deployment_key to ctez --entrypoint set_addresses --arg "Pair \"$CFMM_ADDRESS\" \"$FA12_CTEZ_ADDRESS\"" --burn-cap 10
