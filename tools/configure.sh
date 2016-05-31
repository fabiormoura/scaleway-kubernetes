#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A library of helper functions that each provider hosting Kubernetes
# must implement to use cluster/kube-*.sh scripts.
set -e

MASTER_IP="10.1.1.1"
MINION_IP="10.1.1.2" 
KUBE_ROOT=/root/kube
export KUBECTL_PATH=/opt/bin/kubectl
export DOCKER_OPTS="--storage-driver aufs"

# Create /root/kube/default/etcd with proper contents.
# $1: The one IP address where the etcd leader listens.
function create-etcd-opts() {
  cat <<EOF > /root/kube/default/etcd
ETCD_OPTS="\
 -name infra\
 -listen-client-urls http://127.0.0.1:4001,http://${1}:4001\
 -advertise-client-urls http://${1}:4001"
EOF
}

# Create /root/kube/default/kube-apiserver with proper contents.
# $1: CIDR block for service addresses.
# $2: Admission Controllers to invoke in the API server.
# $3: A port range to reserve for services with NodePort visibility.
# $4: The IP address on which to advertise the apiserver to members of the cluster.
function create-kube-apiserver-opts() {
  cat <<EOF > /root/kube/default/kube-apiserver
KUBE_APISERVER_OPTS="\
 --insecure-bind-address=0.0.0.0\
 --insecure-port=8080\
 --etcd-servers=http://127.0.0.1:4001\
 --logtostderr=true\
 --service-cluster-ip-range=${1}\
 --admission-control=${2}\
 --service-node-port-range=${3}\
 --advertise-address=${4}\
 --client-ca-file=/srv/kubernetes/ca.crt\
 --tls-cert-file=/srv/kubernetes/server.cert\
 --tls-private-key-file=/srv/kubernetes/server.key"
EOF
}

# Create /root/kube/default/kube-controller-manager with proper contents.
function create-kube-controller-manager-opts() {
  cat <<EOF > /root/kube/default/kube-controller-manager
KUBE_CONTROLLER_MANAGER_OPTS="\
 --master=127.0.0.1:8080\
 --root-ca-file=/srv/kubernetes/ca.crt\
 --service-account-private-key-file=/srv/kubernetes/server.key\
 --logtostderr=true"
EOF

}

# Create /root/kube/default/kube-scheduler with proper contents.
function create-kube-scheduler-opts() {
  cat <<EOF > /root/kube/default/kube-scheduler
KUBE_SCHEDULER_OPTS="\
 --logtostderr=true\
 --master=127.0.0.1:8080"
EOF

}

# Create /root/kube/default/kubelet with proper contents.
# $1: The hostname or IP address by which the kubelet will identify itself.
# $2: The one hostname or IP address at which the API server is reached (insecurely).
# $3: If non-empty then the DNS server IP to configure in each pod.
# $4: If non-empty then added to each pod's domain search list.
# $5: Pathname of the kubelet config file or directory.
# $6: If empty then flannel is used otherwise CNI is used.
function create-kubelet-opts() {
  if [ -n "$6" ] ; then
      cni_opts=" --network-plugin=cni --network-plugin-dir=/etc/cni/net.d"
  else
      cni_opts=""
  fi
  cat <<EOF > /root/kube/default/kubelet
KUBELET_OPTS="\
 --hostname-override=${1} \
 --api-servers=http://${2}:8080 \
 --logtostderr=true \
 --cluster-dns=${3} \
 --cluster-domain=${4} \
 --config=${5} \
 $cni_opts"
EOF
}

# Create /root/kube/default/kube-proxy with proper contents.
# $1: The hostname or IP address by which the node is identified.
# $2: The one hostname or IP address at which the API server is reached (insecurely).
function create-kube-proxy-opts() {
  cat <<EOF > /root/kube/default/kube-proxy
KUBE_PROXY_OPTS="\
 --hostname-override=${1} \
 --master=http://${2}:8080 \
 --logtostderr=true \
 ${3}"
EOF

}

# Create /root/kube/default/flanneld with proper contents.
# $1: The one hostname or IP address at which the etcd leader listens.
function create-flanneld-opts() {
  cat <<EOF > /root/kube/default/flanneld
FLANNEL_OPTS="--etcd-endpoints=http://${1}:4001 \
 --ip-masq \
 --iface=${2}"
EOF
}

# Detect the IP for the master
#
# Assumed vars:
#   MASTER_NAME
# Vars set:
#   KUBE_MASTER_IP
function detect-master() {
  source "${KUBE_CONFIG_FILE}"

  export KUBE_MASTER="${MASTER_IP}"
  export KUBE_MASTER_IP="${MASTER_IP}"
  echo "Using master ${MASTER_IP}"
}

# Instantiate a kubernetes cluster on ubuntu
function kube-up() {
  export KUBE_CONFIG_FILE=${KUBE_CONFIG_FILE:-/root/kube/config-default.sh}
  source "${KUBE_CONFIG_FILE}"

  case "$1" in
  	master)
  		provision-master

	    wait	    
	    detect-master
	    export CONTEXT="ubuntu"
	    export KUBE_SERVER="http://${KUBE_MASTER_IP}:8080"

	    source "${KUBE_ROOT}/cluster/common.sh"

	    # set kubernetes user and password
	    load-or-gen-kube-basicauth

	    create-kubeconfig
		echo "Master installation is complete"
  		;;
	masterandminion)
	    provision-masterandnode
        wait	    
        detect-master
        export CONTEXT="ubuntu"
        export KUBE_SERVER="http://${KUBE_MASTER_IP}:8080"

        source "${KUBE_ROOT}/cluster/common.sh"

         # set kubernetes user and password
         load-or-gen-kube-basicauth

         create-kubeconfig
	     echo "Master and node installation is complete"
	    ;;	
  	minion)
  		provision-node "$MINION_IP"
  		;;  	
  	*)
  		echo "Usage: $0 {master|minion|masterandminion}"
  		exit 1
  		;;
  esac
}

function provision-masterandnode() {

  echo -e "\nDeploying master and node on machine ${MASTER_IP}"

  mkdir -p /root/kube/default
  NEED_RECONFIG_DOCKER=true
  CNI_PLUGIN_CONF=''
  EXTRA_SANS=(
    IP:${MASTER_IP}
    IP:${SERVICE_CLUSTER_IP_RANGE%.*}.1
    DNS:kubernetes
    DNS:kubernetes.default
    DNS:kubernetes.default.svc
    DNS:kubernetes.default.svc.cluster.local
  )

  EXTRA_SANS=$(echo "${EXTRA_SANS[@]}" | tr ' ' ,)

  create-etcd-opts ${MASTER_IP}
  create-kube-apiserver-opts ${SERVICE_CLUSTER_IP_RANGE} ${ADMISSION_CONTROL} ${SERVICE_NODE_PORT_RANGE} ${MASTER_IP}
  create-kube-controller-manager-opts
  create-kube-scheduler-opts
  create-kubelet-opts ${MASTER_IP} ${MASTER_IP} ${DNS_SERVER_IP} ${DNS_DOMAIN} ${KUBELET_CONFIG} ${CNI_PLUGIN_CONF}
  create-kube-proxy-opts ${MASTER_IP} ${MASTER_IP} ${KUBE_PROXY_EXTRA_OPTS}
  create-flanneld-opts '127.0.0.1' ${MASTER_IP}
  cp ~/kube/default/* /etc/default/
  groupadd -f -r kube-cert
  ${PROXY_SETTING} ~/kube/make-ca-cert.sh ${MASTER_IP} ${EXTRA_SANS}
  ~/kube/reconfDocker.sh ai
  
  service etcd restart
  service flanneld restart
  service kube-apiserver restart
  service kube-controller-manager restart 
  service kube-scheduler restart 
  service kubelet   restart
  service kube-proxy restart
}

function provision-master() {
  mkdir -p /root/kube/default
  NEED_RECONFIG_DOCKER=true
  CNI_PLUGIN_CONF=''
  EXTRA_SANS=(
    IP:$MASTER_IP
    IP:${SERVICE_CLUSTER_IP_RANGE%.*}.1
    DNS:kubernetes
    DNS:kubernetes.default
    DNS:kubernetes.default.svc
    DNS:kubernetes.default.svc.cluster.local
  )

 EXTRA_SANS=$(echo "${EXTRA_SANS[@]}" | tr ' ' ,)
 
 create-etcd-opts ${MASTER_IP}
 create-kube-apiserver-opts ${SERVICE_CLUSTER_IP_RANGE} ${ADMISSION_CONTROL} ${SERVICE_NODE_PORT_RANGE} ${MASTER_IP}
 create-kube-controller-manager-opts
 create-kube-scheduler-opts
 create-flanneld-opts '127.0.0.1' ${MASTER_IP}
 cp /root/kube/default/* /etc/default/
 
 groupadd -f -r kube-cert
 ${PROXY_SETTING} /root/kube/make-ca-cert.sh $MASTER_IP $EXTRA_SANS

 service etcd restart
 service kube-apiserver restart
 service kube-controller-manager restart 
 service kube-scheduler restart 
 service kubelet    stop || rm -f /etc/init.d/kubelet || /etc/init/kubelet.conf || true
 service kube-proxy stop || rm -f /etc/init.d/kube-proxy || /etc/init/kube-proxy.conf || true
 /root/kube/reconfDocker.sh a
}

function provision-node() {

  echo -e "\nDeploying node on machine ${1#*@}"

  mkdir -p /root/kube/default
  NEED_RECONFIG_DOCKER=true
  CNI_PLUGIN_CONF=''
  create-kubelet-opts ${1#*@} ${MASTER_IP} ${DNS_SERVER_IP} ${DNS_DOMAIN} ${KUBELET_CONFIG} ${CNI_PLUGIN_CONF}
  create-kube-proxy-opts ${1#*@} ${MASTER_IP} ${KUBE_PROXY_EXTRA_OPTS}
  create-flanneld-opts ${MASTER_IP} ${1#*@}

  cp /root/kube/default/* /etc/default/
  
  service flanneld restart
  service kubelet    restart
  service kube-proxy restart
  
  /root/kube/reconfDocker.sh i
}

kube-up "$@"
