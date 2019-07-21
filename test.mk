PRINT = @echo -e "\e[1;34m"[test] $(1)"\e[0m"

SSH_DIR := $(OUT_DIR)/ssh
SSH_KEY := $(SSH_DIR)/id_rsa
SSH_KEY_PUB := $(SSH_DIR)/id_rsa.pub
SSH_OPTIONS := \
	StrictHostKeyChecking=no \
	UserKnownHostsFile=/dev/null
SSH_CMD = ssh \
	-i $(SSH_KEY) \
	$(foreach _,$(SSH_OPTIONS),$(addprefix -o ,$(_))) \
	-p $(SSH_HOST_PORT) \
	$(SSH_USER)@127.0.0.1 \
	$(1)

SCP_CMD = scp \
	-i $(SSH_KEY) \
	$(foreach _,$(SSH_OPTIONS),$(addprefix -o ,$(_))) \
	-P $(SSH_HOST_PORT) \
	$(1) \
	$(SSH_USER)@127.0.0.1:$(2)

TEST_SCRIPT := test.sh
TESTS := \
	fetch-ubuntu \
	gen-disk \
	gen-cidata \
	create-network \
	create-machine \
	wait-login-prompt \
	connect-via-ssh
TEST_TARGET_PREFIX := test-
TEST_TARGET = $(TEST_TARGET_PREFIX)$(1)
TEST_TARGETS := $(foreach _,$(TESTS),$(call TEST_TARGET,$(_)))

INTERVAL_SECS := 1
MAX_RETRY := 60
TIMEOUT_SECS := 600

.PHONY: test
test: test-up test-up-wait scp-ssh-key scp-ssh-key-pub scp-test-script $(TEST_TARGETS)

.PHONY: test-up
test-up: SSH_AUTHORIZED_KEYS = $(shell cat $(SSH_KEY_PUB))
test-up: $(SSH_DIR)
	$(call PRINT,Bringing up test container...)
	docker-compose up -d --build

.PHONY: test-up-wait
test-up-wait:
	while ! $(call SSH_CMD,exit); do \
		if [ $${RETRY:-0} -le $(MAX_RETRY) ]; then \
			RETRY=$$(($${RETRY:-0} + 1)); \
			echo "Failed ($${RETRY:-0}/$(MAX_RETRY)), retry after $(INTERVAL_SECS) second(s)..." >&2; \
			sleep $(INTERVAL_SECS); \
		else \
			echo "Failed" >&2; \
			exit 1; \
		fi \
	done

$(SSH_DIR):
	$(call PRINT,Generating SSH keys...)
	mkdir -p $(SSH_DIR)
	ssh-keygen -t rsa -N '' -C test -f $(SSH_KEY)

.PHONY: scp-ssh-key
scp-ssh-key:
	$(call PRINT,Copying SSH secret key...)
	$(call SCP_CMD,$(SSH_KEY),~)

.PHONY: scp-ssh-key-pub
scp-ssh-key-pub:
	$(call PRINT,Copying SSH public key...)
	$(call SCP_CMD,$(SSH_KEY_PUB),~)

.PHONY: scp-test-script
scp-test-script:
	$(call PRINT,Copying test script...)
	$(call SCP_CMD,$(TEST_SCRIPT),~)

.PHONY: $(TEST_TARGETS)
$(TEST_TARGETS):
	$(call PRINT,Running test '$(@:$(TEST_TARGET_PREFIX)%=%)'...)
	$(call SSH_CMD,env TIMEOUT_SECS=$(TIMEOUT_SECS) ~/$(TEST_SCRIPT) $(@:$(TEST_TARGET_PREFIX)%=%))
