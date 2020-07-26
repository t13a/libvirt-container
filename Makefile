export SSH_AUTHORIZED_KEYS := $(shell cat ~/.ssh/id_rsa.pub)

.PHONY: all
all: build

.PHONY: build
build:
	docker-compose build --parallel --pull

.PHONY: test
test:
	cd test && $(MAKE)

.PHONY: up
up:
	docker-compose up -d

.PHONY: down
down:
	docker-compose down

.PHONY: exec
exec:
	docker-compose exec -u libvirt-user libvirt bash

.PHONY: clean
clean:
	cd test && $(MAKE) clean
	docker-compose down --rmi local -v
