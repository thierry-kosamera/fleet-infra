#! /bin/bash
. common.bash

if ! command -v age &> /dev/null
then
    echo "!! 'age' command could not be found - Please install it:"
    echo "brew install age"
    echo "or check https://github.com/FiloSottile/age#installation"
    exit
fi
if ! command -v kubectl &> /dev/null
then
    echo "!! 'kubectl' command could not be found"
    exit
fi

if [ -f "$OUTFOLDER/$SOPSYAML" ]; then
    echo "An encryption key is already active - Delete $OUTFOLDER/$SOPSYAML if you want to use a new encryption key"
    rm -rf $TMP
    exit
# else 
#     echo "$FILE does not exist."
fi

age-keygen -o $TMP/age.agekey
PUBK=`age-keygen -y $TMP/age.agekey`


cat >$OUTFOLDER/$SOPSYAML <<EOF 
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    age: $PUBK
  - age: $PUBK
EOF

# for the next command you need to have permission to write a secret in the flux-system NS
# --save-config ?
kubectl create secret generic sops-age \
--namespace=$FLUXNS \
--from-file=$TMP/age.agekey \
--dry-run=client \
-o yaml

# Safer: pipe age-keygen to kubectl above  (add =/dev/stdin) to avoid writing the priv key on disk
# pub key is written on stderr
# get the privkey from the cluster and store it safely offline

cat >$TMP/secrets-decryptor-age.yaml <<EOF
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: secrets-decryptor
  namespace: $FLUXNS
spec:
  interval: 10m
  path: $SOURCE_SECRETS
  prune: true
  sourceRef:
    kind: GitRepository
    name: $FLUXNS
  decryption:
    provider: sops
    secretRef:
      name: sops-age
EOF

echo Applying secrets-decryptor Kustomization ...
kubectl apply -f $TMP/secrets-decryptor-age.yaml 

#cleanup
rm -rf $TMP