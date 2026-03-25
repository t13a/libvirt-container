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
	docker compose -f molecule/default/docker-compose.yml up --build --abort-on-container-exit --exit-code-from test-runner

test-clean:
	docker compose -f molecule/default/docker-compose.yml down -v --rmi all --remove-orphans
