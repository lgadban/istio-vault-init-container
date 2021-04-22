#! /bin/bash

set -euo pipefail

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault auth enable kubernetes'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault write auth/kubernetes/role/gen-int-ca-istio \
  bound_service_account_names=istiod-service-account \
  bound_service_account_namespaces=istio-system \
  policies=gen-int-ca-istio \
  ttl=2400h'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault secrets enable pki'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault write -format=json pki/root/generate/internal \
 common_name="pki-ca-root" ttl=187600h'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault secrets enable -path pki_int pki'

kubectl exec -n vault vault-0 -- /bin/sh -c 'vault policy write gen-int-ca-istio - <<EOF
path "pki_int/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "pki/cert/ca" {
  capabilities = ["read"]
}
path "pki/root/sign-intermediate" {
  capabilities = ["create", "read", "update", "list"]
}
EOF'



