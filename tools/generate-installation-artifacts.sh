#!/usr/bin/env bash
set -e

mkdir -p installation-artifacts
mkdir -p installation-artifacts/cluster
mkdir -p installation-artifacts/cluster/lib
mkdir -p sources

# Install packages
apt-get -q update                   \
 && apt-get --force-yes -y -qq upgrade  \
 && apt-get --force-yes install -y -q build-essential tar \
 && apt-get clean

# Install Go
apt-get -y install golang

pushd sources

# Install Etcd
git clone https://github.com/coreos/etcd.git -b release-2.2 && \
pushd etcd && ./build && cp bin/* ../../installation-artifacts/

popd

# Install flannel
git clone https://github.com/coreos/flannel.git && \
pushd flannel && ./build && chmod +x bin/flanneld && \
cp bin/* ../../installation-artifacts/

popd

# Install kubernetes
wget https://github.com/kubernetes/kubernetes/releases/download/v1.3.0-alpha.4/kubernetes.tar.gz && \
tar zxvf kubernetes.tar.gz kubernetes/server/kubernetes-server-linux-amd64.tar.gz && \
pushd kubernetes
mv server/kubernetes-server-linux-amd64.tar.gz . && \
tar zxvf kubernetes-server-linux-amd64.tar.gz kubernetes/server/bin && \
cp kubernetes/server/bin/* . && cp federated-apiserver hyperkube kube-apiserver kube-controller-manager kubectl kubelet kubemark kube-proxy kube-scheduler ../../installation-artifacts/

popd

wget https://github.com/kubernetes/kubernetes/archive/v1.3.0-alpha.4.tar.gz && \
tar zxvf v1.3.0-alpha.4.tar.gz

pushd kubernetes-1.3.0-alpha.4

cp cluster/ubuntu/minion/init_conf/* ../../installation-artifacts && \
cp cluster/ubuntu/minion/init_scripts/* ../../installation-artifacts && \
cp cluster/ubuntu/minion-flannel/init_conf/* ../../installation-artifacts && \
cp cluster/ubuntu/minion-flannel/init_scripts/* ../../installation-artifacts && \

cp cluster/ubuntu/master/init_conf/* ../../installation-artifacts && \
cp cluster/ubuntu/master/init_scripts/* ../../installation-artifacts && \
cp cluster/ubuntu/master-flannel/init_conf/* ../../installation-artifacts && \
cp cluster/ubuntu/master-flannel/init_scripts/* ../../installation-artifacts && \

cp cluster/saltbase/salt/generate-cert/make-ca-cert.sh ../../installation-artifacts && \
cp cluster/ubuntu/reconfDocker.sh ../../installation-artifacts && \
cp cluster/ubuntu/config-default.sh ../../installation-artifacts && \
cp cluster/common.sh ../../installation-artifacts/cluster && \
cp cluster/lib/* ../../installation-artifacts/cluster/lib && \
cp cluster/kubectl.sh ../../installation-artifacts/cluster/ && \
cp cluster/kube-util.sh ../../installation-artifacts/cluster/

popd

curl -L -O https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz

cp easy-rsa.tar.gz ../installation-artifacts

popd
