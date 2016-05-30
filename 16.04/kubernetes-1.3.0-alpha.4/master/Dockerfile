## -*- docker-image-name: "scaleway/ubuntu-kubernetes:xenial" -*-
FROM scaleway/docker:armhf-latest
MAINTAINER Fabio Maia

# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter


# Install packages
RUN apt-get -q update                   \
 && apt-get --force-yes -y -qq upgrade  \
 && apt-get --force-yes install -y -q build-essential tar \
 && apt-get clean


# Install Go
RUN apt-get -y install golang && \
    echo "export GOPATH=/usr/src/go_workspace" >> ~/.bashrc && \
    mkdir /usr/src/go_workspace

# kubelet expects the loader to be in this location
RUN ln -s /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3

RUN mkdir -p /opt/bin

# Install Etcd
RUN cd /usr/src/ && git clone https://github.com/coreos/etcd.git -b release-2.2 && \
    cd /usr/src/etcd && \
    ./build && \
    mv /usr/src/etcd/bin/* /opt/bin/ && \
    rm -rf /usr/src/etcd

# Install flannel
RUN cd /usr/src && \
    git clone https://github.com/coreos/flannel.git && \
    cd flannel && ./build && \
    cp /usr/src/flannel/bin/* /usr/bin/ && \
    rm -rf /usr/src/flannel

# Install kubernetes
RUN cd /usr/src && \
    wget https://github.com/kubernetes/kubernetes/releases/download/v1.3.0-alpha.4/kubernetes.tar.gz && \
    tar zxvf kubernetes.tar.gz kubernetes/server/kubernetes-server-linux-arm.tar.gz

RUN cd /usr/src/kubernetes/server && tar zxvf kubernetes-server-linux-arm.tar.gz kubernetes/server/bin && cd kubernetes/server/bin && \
    cp federated-apiserver hyperkube kube-apiserver kube-controller-manager kubectl kubelet kubemark kube-proxy kube-scheduler /opt/bin/ && \
    rm -rf /usr/src/kubernetes && rm -rf /usr/src/kubernetes.tar.gz

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
