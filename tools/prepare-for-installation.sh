#!/usr/bin/env bash
set -e

function prepare() {
	case "$1" in
		master)
			configure
			copy-for-master
			;;
		minion)
			configure
			copy-for-minion
			;;

		*)
			echo "Usage: $0 {master|minion}"
			exit 1
			;;
	esac
}

function configure() {
# Install packages
	apt-get -q update                   \
		&& apt-get --force-yes -y -qq upgrade  \
		&& apt-get --force-yes install -y -q build-essential tar \
		&& apt-get clean

# Disable systemd and go back to upstart
# kubernets does not have configuration files for systemd in ubuntu yet
		apt-get --force-yes install -y -q upstart-sysv && update-initramfs -u && apt-get clean


# Install Go
		apt-get -y install golang

# Used to connect to glusterfs volume cluster storage
		apt-get install -y glusterfs-client

		mkdir -p /opt/bin
                rm -rf /root/kube
		mkdir -p /root/kube
}

function copy-for-master() {
	cp configure.sh /root/kube/
	tar zxvf installation-artifacts.tar.gz
	pushd installation-artifacts

	mv cluster /root/kube/
	mv config-default.sh /root/kube/
	mv easy-rsa.tar.gz /root/kube/
	mv make-ca-cert.sh /root/kube/
	mv reconfDocker.sh /root/kube/

	mv master/bin/* /opt/bin/
	mv master/init_conf/* /etc/init/
	mv master/init_scripts/* /etc/init.d/

	popd

	rm -rf installation-artifacts/
}

function copy-for-minion() {
	cp configure.sh /root/kube/
	tar zxvf installation-artifacts.tar.gz
	pushd installation-artifacts

	mv cluster /root/kube/
	mv config-default.sh /root/kube/
	mv easy-rsa.tar.gz /root/kube/
	mv make-ca-cert.sh /root/kube/
	mv reconfDocker.sh /root/kube/

	mv minion/bin/* /opt/bin/
	mv minion/init_conf/* /etc/init/
	mv minion/init_scripts/* /etc/init.d/

	popd

	rm -rf installation-artifacts/
}
prepare "$@"
