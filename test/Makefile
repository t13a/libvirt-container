
.PHONY: all
all: build e2e

.PHONY: build
build:
	docker-compose build --pull

.PHONY: e2e
e2e:
	env SUT_CMD='bats -T .' docker-compose up \
		--abort-on-container-exit \
		--exit-code-from sut
	docker-compose down

.PHONY: up
up:
	docker-compose up -d

.PHONY: down
down:
	docker-compose down

.PHONY: exec
exec:
	docker-compose exec sut bash

.PHONY: clean
clean:
	docker-compose down --rmi local
