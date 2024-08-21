ifneq (,$(wildcard ./.env))
    include .env
    export
endif

cmd-exists-%:
	@hash $(*) > /dev/null 2>&1 || \
		(echo "ERROR: '$(*)' must be installed and available on your PATH."; exit 1)


.PHONY: check_valid_key
check_valid_key:
	@if echo "${PRIVATE_KEY}" | grep -Eq '^[0-9a-fA-F]{64}$$'; then \
		echo "Valid private key"; \
	else \
		echo "Invalid private key"; \
		exit 1; \
	fi

.PHONY: init fmt build clean rebuild test test-unit test-integration test-fuzz test-invariant test-gas trace remappings coverage
init: cmd-exists-forge
	@find ./script/sh -type f -exec chmod u+x {} +
	git submodule deinit --force .
	git submodule update --init --recursive
	forge install

fmt: cmd-exists-forge
	forge fmt

doc: cmd-exists-forge
	@./script/sh/forge-doc-gen.sh

build: cmd-exists-forge
	forge build

clean: cmd-exists-forge
	forge clean

rebuild: clean build

test: cmd-exists-forge
	forge test -vv

test-unit: cmd-exists-forge
	forge test --match-path "test/unit/*.sol"

test-integration: cmd-exists-forge
	forge test --match-path "test/integration/*.sol"

test-fuzz: cmd-exists-forge
	FOUNDRY_PROFILE=fuzz forge test --match-path "test/fuzz/*.sol"

test-invariant: cmd-exists-forge
	FOUNDRY_PROFILE=invariant forge test --match-path "test/invariant/*.sol"

test-gas: cmd-exists-forge
	FOUNDRY_PROFILE=optimized forge test -vv --gas-report
	FOUNDRY_PROFILE=optimized forge snapshot

trace: cmd-exists-forge
	forge test -vvvv

remappings: cmd-exists-forge
	forge remappings > remappings.txt

coverage: cmd-exists-forge
	@./script/sh/coverage.sh 

.PHONY: fork 
fork: cmd-exists-anvil
	anvil --fork-url ${ETHEREUM_RPC} --fork-block-number ${BLOCK_NUMBER_MAINNET}

.PHONY: deploy-token
deploy-token: cmd-exists-forge
	@./script/sh/deploy-token.sh $(c)

.PHONY: deploy-staking
deploy-staking: cmd-exists-forge
	@./script/sh/deploy-staking.sh $(c)
