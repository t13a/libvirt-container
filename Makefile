export COMPOSE_PROJECT_NAME := libvirt

export LIBVIRT_IMAGE := libvirt

export SSH_AUTHORIZED_KEYS := $(shell cat ~/.ssh/id_rsa.pub)
export SSH_GID := $(shell id -g)
export SSH_HOST_PORT := 2222
export SSH_UID := $(shell id -u)
export SSH_USER := $(shell id -nu)

VOLUMES := libvirt_conf libvirt_data ssh_conf
VOLUME_NAME = $(addprefix $(COMPOSE_PROJECT_NAME)_,$(1))

.PHONY: all
all: build

.PHONY: up
up: ARGS = -d --build
up:
	docker-compose up $(ARGS)

.PHONY: exec
exec: CMD = sudo -u $(SSH_USER) -i
exec: ARGS = libvirt $(CMD)
exec:
	docker-compose exec $(ARGS)

include test.mk

.PHONY: clean
clean: $(CLEAN_TARGETS)
	docker-compose rm -fsv
	docker image rm -f $(LIBVIRT_IMAGE)
	docker volume rm -f $(foreach _,$(VOLUMES),$(call VOLUME_NAME,$(_)))

.PHONY: %
%:
	docker-compose $@ $(ARGS)
