SSH_AUTHORIZED_KEYS ?= $(shell cat ~/.ssh/id_rsa.pub 2>/dev/null)
export SSH_AUTHORIZED_KEYS

.PHONY: all build up down exec clean test

all: build

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

exec:
	docker compose exec libvirt bash

clean:
	docker compose down -v --rmi all --remove-orphans

test:
	@echo "TODO: implement test target"
