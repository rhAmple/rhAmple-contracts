.PHONY: clean
clean: ## Remove build artifacts
	@forge clean

.PHONY: build
build: ## Build project
	forge build

.PHONY: test
test: ## Run whole testsuite
	forge test -vvv

.PHONY: update
update: ## Update dependencies
	forge update

.PHONY: testDeployment
testDeployment: ## Run deployment tests
	forge test -vvv --match-contract "Deployment"

.PHONY: testOnlyOwner
testOnlyOwner: ## Run onlyOwner tests
	forge test -vvv --match-contract "OnlyOwner"

.PHONY: testButtonWrapper
testButtonWrapper: ## Run ButtonWrapper tests
	forge test -vvv --match-contract "ButtonWrapper"

.PHONY: testRestructure
testRestructure: ## Run restructure tests
	forge test -vvv --match-contract "Restructure"

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Run Debugger with:
# forge run ./src/test/<Contract>.t.sol --sig "<function>()" --debug
