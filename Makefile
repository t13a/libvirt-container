DOCKER_HOSTNAME := libvirt
DOCKER_NAME := libvirt
DOCKER_TAG := libvirt

LIBVIRT_CONF_HOST_DIR := libvirt-conf
LIBVIRT_DATA_HOST_DIR := libvirt-data

SSH_USER := $(shell id -nu)
SSH_UID := $(shell id -u)
SSH_GID := $(shell id -g)
SSH_AUTHORIZED_KEYS := $(HOME)/.ssh/id_rsa.pub
SSH_CONF_HOST_DIR := ssh-conf
SSH_HOST_PORT := 2222

HOST_DIRS := \
	$(LIBVIRT_CONF_HOST_DIR) \
	$(LIBVIRT_DATA_HOST_DIR) \
	$(SSH_CONF_HOST_DIR)

.PHONY: all
all: build

.PHONY: build
build:
	docker build -t $(DOCKER_TAG) .

.PHONY: up
up: build
	mkdir -p $(HOST_DIRS)
	docker run \
		-d \
		-e SSH_USER=$(SSH_USER) \
		-e SSH_UID=$(SSH_UID) \
		-e SSH_GID=$(SSH_GID) \
		-h $(DOCKER_HOSTNAME) \
		--name $(DOCKER_NAME) \
		-p $(SSH_HOST_PORT):22 \
		--privileged \
		--rm \
		-v $(abspath $(LIBVIRT_CONF_HOST_DIR)):/etc/libvirt:z \
		-v $(abspath $(LIBVIRT_DATA_HOST_DIR)):/var/lib/libvirt:z \
		-v $(abspath $(SSH_AUTHORIZED_KEYS)):/home/$(SSH_USER)/.ssh/authorized_keys:z \
		-v $(abspath $(SSH_CONF_HOST_DIR)):/etc/ssh:z \
		-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
		$(DOCKER_TAG)

.PHONY: down
down:
	docker stop $(DOCKER_NAME)

.PHONY: exec
exec:
	docker exec -it $(DOCKER_NAME) $(or $(CMD),sudo -u $(SSH_USER) -i)

.PHONY: clean
clean:
	docker rmi -f $(DOCKER_TAG)
	rm -rf $(HOST_DIRS)
