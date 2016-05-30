NAME =			ubuntu-kubernetes
VERSION =		16.04/1.3.0-alpha.4
TITLE =			Ubuntu + Kubernetes
DESCRIPTION =		Ubuntu + Kubernetes
SOURCE_URL =		https://github.com/fabiormoura/scaleway-ubuntu-kubernetes

IMAGE_VOLUME_SIZE =	50G
IMAGE_BOOTSCRIPT =	stable
IMAGE_NAME =		Ubuntu + Kubernetes 


## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
