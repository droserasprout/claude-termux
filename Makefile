# Default SHELL (/bin/sh) works on Termux via termux-exec path rewriting.
SCRIPTS := scripts

.PHONY: help install setup all \
        prereqs glibc-runner claude update uninstall doctor \
        tmux termux-api trigger-permissions dev-tools claude-md

##@ Meta

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5); next } \
		/^[a-zA-Z][a-zA-Z0-9_-]*:.*##/ { printf "  \033[1;36m%-20s\033[0m %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST)

install: prereqs glibc-runner claude ## Core install: prereqs + grun + Claude Code
setup: install ## Alias for `install`
all: install tmux termux-api dev-tools ## Everything: core + extras

##@ Core

prereqs: ## apt update + full-upgrade, install curl/git/tur-repo
	@$(SHELL) $(SCRIPTS)/install-prereqs.sh

glibc-runner: ## Install glibc-runner (grun) from termux-glibc
	@$(SHELL) $(SCRIPTS)/install-glibc-runner.sh

claude: ## Install Claude Code and wrap its launcher with grun
	@$(SHELL) $(SCRIPTS)/install-claude.sh

update: ## Re-run bootstrap to update Claude Code; re-wrap launcher
	@$(SHELL) $(SCRIPTS)/update-claude.sh

uninstall: ## Remove Claude payload + repo state (keeps packages, auth)
	@$(SHELL) $(SCRIPTS)/uninstall-claude.sh

doctor: ## Diagnose the install
	@$(SHELL) $(SCRIPTS)/doctor.sh

##@ Extras

tmux: ## Install tmux + configs/tmux.conf + claude-tmux helper
	@$(SHELL) $(SCRIPTS)/install-tmux.sh

termux-api: ## Install termux-api client (companion app must be sideloaded)
	@$(SHELL) $(SCRIPTS)/install-termux-api.sh

trigger-permissions: termux-api ## Fire every Android permission popup once
	@$(SHELL) $(SCRIPTS)/trigger-permissions.sh

dev-tools: ## Install gh + openssh, configure git identity, generate ssh key
	@$(SHELL) $(SCRIPTS)/install-dev-tools.sh

claude-md: ## Install configs/CLAUDE.md to ~/.claude/CLAUDE.md (Termux profile memory)
	@$(SHELL) $(SCRIPTS)/install-claude-md.sh
