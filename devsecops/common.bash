#! /bin/bash

CLUSTER="${1:-dev-cluster}"

TMP="./tmp"
OUTFOLDER="./converted"

FLUXNS="flux-system"
SOURCE_SECRETS="./secrets"
SOPSYAML=".sops.yaml"
rm -rf $TMP
mkdir -p $TMP

OUTSECRET=$OUTFOLDER/$CLUSTER/secrets
rm -rf $OUTSECRET
mkdir -p $OUTSECRET
INSECRET=../$CLUSTER/secrets

