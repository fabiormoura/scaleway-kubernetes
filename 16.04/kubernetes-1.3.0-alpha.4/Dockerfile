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

# Disable systemd and go back to upstart
# kubernets does not have configuration files for systemd in ubuntu yet
RUN apt-get --force-yes install -y -q upstart-sysv && \
    update-initramfs -u && \ 
    apt-get clean


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
    mv /usr/src/flannel/bin/* /opt/bin/ && \
    rm -rf /usr/src/flannel

# Install kubernetes
RUN cd /usr/src && \
    wget https://github.com/kubernetes/kubernetes/releases/download/v1.3.0-alpha.4/kubernetes.tar.gz && \
    tar zxvf kubernetes.tar.gz kubernetes/server/kubernetes-server-linux-arm.tar.gz

RUN cd /usr/src/kubernetes/server && tar zxvf kubernetes-server-linux-arm.tar.gz kubernetes/server/bin && cd kubernetes/server/bin && \
    cp federated-apiserver hyperkube kube-apiserver kube-controller-manager kubectl kubelet kubemark kube-proxy kube-scheduler /opt/bin/ && \
    rm -rf /usr/src/kubernetes && rm -rf /usr/src/kubernetes.tar.gz

RUN cd /usr/src && wget https://github.com/kubernetes/kubernetes/archive/v1.3.0-alpha.4.tar.gz && \
    tar zxvf v1.3.0-alpha.4.tar.gz


RUN cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/minion/init_conf && cp * /etc/init/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/minion/init_scripts && cp * /etc/init.d/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/minion-flannel/init_conf && cp * /etc/init/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/minion-flannel/init_scripts && cp * /etc/init.d/


RUN cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/master/init_conf && cp * /etc/init/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/master/init_scripts && cp * /etc/init.d/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/master-flannel/init_conf && cp * /etc/init/ && \
    cd /usr/src/kubernetes-1.3.0-alpha.4/cluster/ubuntu/master-flannel/init_scripts && cp * /etc/init.d/

# For some reason flannel does not come with execution permisison
RUN chmod +x /etc/init.d/flannel

# Copy installation files required for configuring master
RUN mkdir -p /root/kube/cluster/lib

RUN cd /usr/src/kubernetes-1.3.0-alpha.4/cluster && cp saltbase/salt/generate-cert/make-ca-cert.sh /root/kube/ && \
    cp ubuntu/reconfDocker.sh /root/kube/ && \
    cp ubuntu/config-default.sh /root/kube/ && \
    cp common.sh /root/kube/cluster && \
    cp lib/* /root/kube/cluster/lib/ && \
    cp kubectl.sh /root/kube/cluster/ && \
    cp kube-util.sh /root/kube/cluster


RUN cd /root/kube/ && curl -L -O https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz

# Copy installation files required for configuring minion

RUN rm -rf /usr/src/kubernetes-1.3.0-alpha.4 && rm -rf /usr/src/kubernetes-1.3.0-alpha.4/

# Add file used to configure master and minion nodes correctly
ADD ./overlay/root/kube/configure.sh /root/kube/

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
