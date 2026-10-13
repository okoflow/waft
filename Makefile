CONFIG         ?= debug
INDEX_STORE     = $(if $(wildcard .build/out/v5),.build/out,.build/debug/index/store)
STRINGS_DIR     = $(CURDIR)/.build/strings
TOOLCHAIN_DIR   = $(shell xcrun --find swift | sed 's|/usr/bin/swift$$||')
TESTING_PLUGINS = $(TOOLCHAIN_DIR)/usr/lib/swift/host/plugins/testing
TESTING_LIBS    = $(TOOLCHAIN_DIR)/Library/Developer
GITLEAKS        = gitleaks git --no-banner --redact

.PHONY: help build test bundle run release format check format-check lint shellcheck spelling secrets secrets-staged periphery strings strings-update hooks signing clean

help: ## List the targets
	@awk 'BEGIN { FS = ":.*## " } /^[a-z0-9-]+:.*## / { printf "  %-14s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build the package and extract its localizable strings
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

format: ## Format Swift, shell, and the property lists
	swiftformat .
	shfmt -w scripts
	plutil -convert xml1 Packaging/Waft-Info.plist Packaging/Waft.entitlements

check: format-check lint shellcheck spelling secrets build test periphery strings ## Run every check
	@echo "make check: OK"

format-check: ## Fail on any formatting difference
	swiftformat . --lint
	shfmt -d scripts
	plutil -convert xml1 -o - Packaging/Waft-Info.plist | diff -u Packaging/Waft-Info.plist -
	plutil -convert xml1 -o - Packaging/Waft.entitlements | diff -u Packaging/Waft.entitlements -

lint: ## Lint the Swift code
	TOOLCHAIN_DIR=$(TOOLCHAIN_DIR) swiftlint lint --quiet

shellcheck: ## Lint the shell scripts
	shellcheck scripts/*.sh

spelling: ## Check the spelling in code and docs
	typos

secrets: ## Scan the git history for secrets
	$(GITLEAKS)

secrets-staged: ## Scan the staged changes for secrets
	$(GITLEAKS) --pre-commit --staged

periphery: test ## Fail on unused code
	periphery scan --index-store-path $(INDEX_STORE)

strings: build ## Check every translation against the strings in the code
	STRINGS_DIR=$(STRINGS_DIR) scripts/strings.sh check

strings-update: build ## Rewrite the English strings table from the code
	STRINGS_DIR=$(STRINGS_DIR) scripts/strings.sh update

hooks: ## Install the pre-commit hook
	lefthook install

signing: ## Create the stable code-signing identity once
	scripts/signing.sh

clean: ## Remove the build output
	rm -rf .build build
