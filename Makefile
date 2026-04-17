# Default SHELL (/bin/sh) works on Termux via termux-exec path rewriting.
SCRIPTS := scripts

.PHONY: help install setup prereqs glibc-runner claude update uninstall doctor

help: ## Show this help
	@printf 'claude-termux — Makefile targets\n\n'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z][a-zA-Z0-9_-]*:.*##/ \
		{ printf "  \033[1;36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\n'

install: prereqs glibc-runner claude ## Full install: prereqs + glibc-runner + Claude Code

setup: install ## Alias for `install`

prereqs: ## apt update + full-upgrade, install curl/git/tur-repo
	@$(SHELL) $(SCRIPTS)/install-prereqs.sh

glibc-runner: ## Install glibc-runner (grun) from termux-glibc repo
	@$(SHELL) $(SCRIPTS)/install-glibc-runner.sh

claude: ## Install Claude Code and wrap its launcher with grun
	@$(SHELL) $(SCRIPTS)/install-claude.sh

update: ## Re-run bootstrap to update Claude Code; re-wrap launcher
	@$(SHELL) $(SCRIPTS)/update-claude.sh

uninstall: ## Remove Claude payload + this repo's state (keeps packages, auth)
	@$(SHELL) $(SCRIPTS)/uninstall-claude.sh

doctor: ## Diagnose the install
	@$(SHELL) $(SCRIPTS)/doctor.sh
