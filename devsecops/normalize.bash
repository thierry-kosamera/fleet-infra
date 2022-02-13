#! /bin/bash
. common.bash

if ! command -v sops &> /dev/null
then
    echo "!! 'sops' command could not be found, please install - https://github.com/mozilla/sops"
    exit
fi

########################## MAIN KUSTOMIZATION ########################################################
# literals to convert
INFOLDER_CLUSTER=../$CLUSTER
OUTFOLDER_CLUSTER=$OUTFOLDER
#replace literals
yq '.secretGenerator[0].literals[]' $INFOLDER_CLUSTER/kustomization.yaml >$TMP/api-secret.env
yq '.secretGenerator[6].literals[]' $INFOLDER_CLUSTER/kustomization.yaml >$TMP/aws-secrets-tls.env
sops -e --input-type=env --config $OUTFOLDER/$SOPSYAML $TMP/api-secret.env >$OUTSECRET/api-secret.env
sops -e --input-type=env --config $OUTFOLDER/$SOPSYAML $TMP/aws-secrets-tls.env >$OUTSECRET/aws-secrets-tls.env

cp  ./blueprints/cluster/kustomization.yaml $OUTFOLDER_CLUSTER/.

#these contains secrets but are config maps ???
cp $INFOLDER_CLUSTER/opensearch-dashboards-configmap.yaml $OUTFOLDER_CLUSTER/.
cp $INFOLDER_CLUSTER/opensearch-securityconfig.yaml $OUTFOLDER_CLUSTER/.
cp -R $INFOLDER_CLUSTER/config $OUTFOLDER_CLUSTER/.

tosops=(
"$INFOLDER_CLUSTER/consumer.server.cer.pem"
"$INFOLDER_CLUSTER/consumer.client.key.pem"
"$INFOLDER_CLUSTER/consumer.client.cer.pem"
"$INFOLDER_CLUSTER/consumer.server.cer.pem.base64"
"$INFOLDER_CLUSTER/consumer.client.key.pem.base64"
"$INFOLDER_CLUSTER/consumer.client.cer.pem.base64"
"$INFOLDER_CLUSTER/kibana.yml"
"$INFOLDER_CLUSTER/config.yml"
"$INFOLDER_CLUSTER/action_groups.yml"
"$INFOLDER_CLUSTER/internal_users.yml"
"$INFOLDER_CLUSTER/nodes_dn.yml"
"$INFOLDER_CLUSTER/roles.yml"
"$INFOLDER_CLUSTER/roles_mapping.yml"
"$INFOLDER_CLUSTER/tenants.yml"
"$INFOLDER_CLUSTER/whitelist.yml"
)
for i in "${tosops[@]}"; do
    # cp "$i" $OUTSECRET/.
    echo encrypting $i
    # should be put in secrets => only one customization?
    sops -e --config $OUTFOLDER/$SOPSYAML $i >$OUTFOLDER_CLUSTER/$(basename $i)
done
#opensearch-securityconfig.yaml SECRET
# opensearch-dashboards-configmap.yaml OK
########################## BASE ########################################################
INFOLDER_BASE=../base
OUTFOLDER_BASE=$OUTFOLDER/base
mkdir -p $OUTFOLDER_BASE
# mongo-replicas => SECRETS in mongo.yaml / HELM SOURCE?
# aws-load-balancer-controller 1 secret aws-alb-controller.yaml
# external-dns external-dns.yaml has secret in env
# opendistro-kibana-v1.11.0 od.yaml secret /helm -
# postgresql template/secret helm
# tls-certs-renew command line to create secrets renew-certs-cronjob.yaml
# opensearch  /secrets in al templates
to_copy_as_is=(
kustomization.yaml
argo  
logstash
redis
elasticsearch-exporter
kafka-exporter
prometheus-dashboard
dgraph
prometheus-rules
strimzi-kafka-operator
beats-job
)
for i in "${to_copy_as_is[@]}"; do
    cp -R $INFOLDER_BASE/$i $OUTFOLDER_BASE/.
done
########################## ML ########################################################
INFOLDER_ML=../ml
OUTFOLDER_ML=$OUTFOLDER/ml
#we copy all - even if there are not all in use No generation of secrets here
cp -R $INFOLDER_ML $OUTFOLDER_ML
########################## MS ########################################################
INFOLDER_MS=../ms
OUTFOLDER_MS=$OUTFOLDER/ms
mkdir -p $OUTFOLDER_MS
to_copy_as_is=(
    kustomization.yaml
    packetai-system-namespace.yaml
    api-deployment.yaml
    api-svc.yaml
    api-ingress.yaml
    accounts-deployment.yaml
    accounts-svc.yaml
    accounts-ingress.yaml
    frontend-deployment.yaml
    frontend-svc.yaml
    frontend-ingress.yaml
    topologyservice-deployment.yaml
    topologyservice-v2-deployment.yaml
    activator-deployment.yaml
    processservice-deployment.yaml
    technoservice-deployment.yaml
    ingestservice-deployment.yaml
    ingest-svc.yaml
    ingest-ingress.yaml
    awsservice-sts.yaml
    awsservice-svc.yaml
    incident-manager-deployment.yaml
    incident-manager-svc.yaml
    lco-sts.yaml
    beats-ingester-deployment.yaml
    beats-ingester-svc.yaml
    beats-ingester-ingress.yaml
    dgraph-schema-updater-job.yaml
)
for i in "${to_copy_as_is[@]}"; do
    cp $INFOLDER_MS/$i $OUTFOLDER_MS/.
done


########################## SECRETS ########################################################
mystring1=`grep -i kafka ../$CLUSTER/secrets/kustomization.yaml |head -1`
# echo $mystring1
regex='\b*- (.*)=(.*)'
[[ $mystring1 =~ $regex ]]
# echo uu${BASH_REMATCH[1]} 
# echo ${BASH_REMATCH[2]}  
echo ${BASH_REMATCH[2]}>$TMP/${BASH_REMATCH[1]}

tosops=(
"$TMP/${BASH_REMATCH[1]}"
"$INSECRET/cacert"
"$INSECRET/crt"
"$INSECRET/key"
"$INSECRET/keystore.jks"
"$INSECRET/truststore.jks"
"$INSECRET/mongo-secret-mongo.yaml"
"$INSECRET/logstash-env.yaml"
"$INSECRET/ml-env.yaml"
"$INSECRET/s3-secret.yaml"
)
for i in "${tosops[@]}"; do
    # cp "$i" $OUTSECRET/.
    echo encrypting $i
    sops -e --config $OUTFOLDER/$SOPSYAML $i >$OUTSECRET/$(basename $i)
done
cp ./blueprints/cluster/secrets/kustomization.yaml $OUTSECRET/.




#cleanup
 rm -rf $TMP