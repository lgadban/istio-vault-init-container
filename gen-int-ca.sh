#! /bin/bash

set -euo pipefail

export VAULT_TOKEN=$(vault write -field=token -address="http://vault.vault.svc.cluster.local:8200" \
  auth/kubernetes/login role=gen-int-ca-istio jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token))

vault write -address="http://vault.vault.svc.cluster.local:8200" \
  -format=json pki_int/intermediate/generate/exported \
  common_name="myvault.com Intermediate Authority" ttl=43800h | tee \
  >(jq -r .data.csr > /etc/cacerts/ca-cert.csr) \
  >(jq -r .data.private_key > /etc/cacerts/ca-key.pem)

vault write -format=json -address="http://vault.vault.svc.cluster.local:8200" pki/root/sign-intermediate \
  csr=@/etc/cacerts/ca-cert.csr format=pem_bundle ttl=43800h | tee \
  >(jq -r .data.certificate > /etc/cacerts/ca-cert.pem) \
  >(jq -r .data.issuing_ca > /etc/cacerts/root-cert.pem)

cat /etc/cacerts/ca-cert.pem /etc/cacerts/root-cert.pem > /etc/cacerts/cert-chain.pem

