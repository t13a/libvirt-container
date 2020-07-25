export SSH_AUTHORIZED_KEYS := $(shell cat ~/.ssh/id_rsa.pub)

.PHONY: all
all: build

.PHONY: build
build:
	docker-compose build

.PHONY: test
test:
	cd test && $(MAKE) all e2e

.PHONY: test/clean
test/clean:
	cd test && $(MAKE) clean

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
clean: init test/clean
	docker-compose down --rmi local -v
	rm -rf .env
