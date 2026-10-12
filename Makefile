CONFIG         ?= debug
INDEX_STORE     = $(if $(wildcard .build/out/v5),.build/out,.build/debug/index/store)
STRINGS_DIR     = $(CURDIR)/.build/strings
TOOLCHAIN_DIR   = $(shell xcrun --find swift | sed 's|/usr/bin/swift$$||')
TESTING_PLUGINS = $(TOOLCHAIN_DIR)/usr/lib/swift/host/plugins/testing
TESTING_LIBS    = $(TOOLCHAIN_DIR)/Library/Developer

.PHONY: help build test bundle run release format check format-check lint periphery secrets shellcheck strings strings-update hooks signing clean

help: ## List targets
	@awk 'BEGIN { FS = ":.*## " } /^[a-z0-9-]+:.*## / { printf "  %-14s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build every target and extract its localizable strings
	mkdir -p $(STRINGS_DIR)
	swift build --configuration $(CONFIG) -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc $(STRINGS_DIR)

test: ## Run the tests
	swift test -Xswiftc -plugin-path -Xswiftc $(TESTING_PLUGINS) -Xswiftc -F -Xswiftc $(TESTING_LIBS)/Frameworks -Xlinker -rpath -Xlinker $(TESTING_LIBS)/Frameworks -Xlinker -rpath -Xlinker $(TESTING_LIBS)/usr/lib

bundle: ## Build and sign build/Waft.app
	scripts/bundle.sh $(CONFIG)

run: bundle ## Build, sign, and open Waft
	open build/Waft.app

release: ## Build, notarize, and package a release with NOTES into build/release
	scripts/release.sh "$(NOTES)"

format: ## Format Swift, shell, and the property list
	swiftformat .
	shfmt -w scripts
	plutil -convert xml1 Packaging/Waft-Info.plist

check: format-check lint build test periphery secrets shellcheck strings ## Run every check that CI runs
	@echo "make check: OK"

format-check: ## Fail on any formatting difference
	swiftformat . --lint
	shfmt -d scripts
	plutil -convert xml1 -o - Packaging/Waft-Info.plist | diff -u Packaging/Waft-Info.plist -

lint: ## Lint Swift sources in strict mode
	TOOLCHAIN_DIR=$(TOOLCHAIN_DIR) swiftlint lint --quiet

periphery: test ## Fail on unused code
	periphery scan --strict --quiet --retain-codable-properties --index-store-path $(INDEX_STORE)

secrets: ## Scan the git history for secrets
	gitleaks git --no-banner --redact

shellcheck: ## Lint shell scripts
	shellcheck scripts/*.sh

strings: build ## Check every translation against the strings in the code
	scripts/strings.sh check

strings-update: build ## Rewrite the English strings table from the code
	scripts/strings.sh update

hooks: ## Install the git pre-commit hooks
	lefthook install

signing: ## Create the stable code-signing identity once
	scripts/setup-signing.sh

clean: ## Remove the build output
	rm -rf .build build
