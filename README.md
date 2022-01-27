# POC Sops secrets with Flux v2
https://fluxcd.io/docs/guides/mozilla-sops/

For this POC: 
- GPG public key (to encrypt) is stored in ./poc/.sops.pub.asc 
- GPG and age private key (for this DEMO only of course :-) in the secret resource is @ poc/secret_sops-gpg.yaml
- secrets should be placed in the secrets folder,*outside* of clusters/mycluster (flux SOPS issue as of today)
- private keys (age and/or gpg) must be initialized once as secret resources - They are in poc/secrets_sops-xxx.yaml. Default is to encrypt both in gpg and age, but decrypt only in age. (gpg could be seen as a rescue decryption method). In production, these resources and pribate key must be stord offline in a safe place (and not in the repo of course)
``` bash
# to create a sops secret (it is assumed sops cli is installed, and this repo si cloned on a local dev computer)
cd cluster/mycluster
kubectl create secret generic mysecret \
--from-literal=user=admin \
--from-literal=password=change-me \
--dry-run=client \
-o yaml > ../../secrets/mysecret.yaml
sops -e -i ../../secrets/mysecret.yaml
#then commit/push and let flux does the reconciliation.
```
In the poc, secrets are mounted as env and as volume. Important: a change of the secret value is not [updated](https://kubernetes.io/docs/concepts/configuration/secret/#mounted-secrets-are-updated-automatically) in an env variable, but it is in a mounted file.  
Watch out when you use a flux Kustomization CRD with a patch (e.g podinfo-kustomization.yaml) - yaml Indentation is critical (watch kubectl get events for messages like "kustomize build failed: trouble configuring builtin PatchTransformer with config ...").  

## SOPS Kustomize Secret generator

- encrypt the files with sops
- don't use literals - convert into files or .env
- for .env file use the envs in Kustomize and the --input-type=env during encryption
- for json use --input-type=json


