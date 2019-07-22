OUT_DIR := out

export COMPOSE_PROJECT_NAME := libvirt

export IMAGE := libvirt

export SSH_AUTHORIZED_KEYS := $(shell cat ~/.ssh/id_rsa.pub)
export SSH_GID := $(shell id -g)
export SSH_HOST_PORT := 2222
export SSH_UID := $(shell id -u)
export SSH_USER := $(shell id -nu)

VOLUMES := libvirt_conf libvirt_data ssh_conf

.PHONY: all
all: build

include test.mk

.PHONY: clean
clean:
	docker-compose rm -fsv
	docker image rm -f $(IMAGE)
	docker volume rm -f $(foreach _,$(VOLUMES),$(addprefix $(COMPOSE_PROJECT_NAME)_,$(_)))
	rm -rf $(OUT_DIR)

.PHONY: %
exec: CMD = bash
exec: ARGS = -u $(SSH_USER) libvirt $(CMD)
up: ARGS = -d --build
%:
	docker-compose $@ $(ARGS)
