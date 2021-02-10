FROM ubuntu:latest

RUN apt-get update && \
      apt-get install -y curl unzip jq

RUN curl https://releases.hashicorp.com/vault/1.6.2/vault_1.6.2_linux_amd64.zip \
      -o vault.zip

RUN unzip vault.zip && mv vault /usr/local/bin/

COPY gen-int-ca.sh /usr/local/bin/
CMD gen-int-ca.sh
