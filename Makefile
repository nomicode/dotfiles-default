# =============================================================================
# Dotfiles build
# =============================================================================

.EXPORT_ALL_VARIABLES:

# POSIX locale
LC_ALL = C

# ANSI formatting
B = [1m
U = [4m
RED = [0;31m
RST = [0m

TOP_DIR = $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# Collect files for check/format targets
SH_CHANGED  := $(shell git diff --name-only HEAD 2>/dev/null | grep '\.sh$$')
YML_CHANGED := $(shell git diff --name-only HEAD 2>/dev/null | grep '\.ya\?ml$$')
SH_ALL      := $(shell find . -name '*.sh' -not -path './.git/*' 2>/dev/null)
YML_ALL     := $(shell find . \( -name '*.yaml' -o -name '*.yml' \) -not -path './.git/*' 2>/dev/null)

# Primary targets
# =============================================================================

.PHONY: help
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = help

help:
	@ printf 'Usage: \e$(B)make\e$(RST) [ target ]\n\n'
	@ printf 'Available targets:\n\n'
	@ grep -E '^.PHONY: [a-z-]+ #' Makefile | \
		sed -E 's,^.PHONY: ([a-z-]+) # (.*),\1#\2,' | \
		column -s '#' -t | \
		sed -E "s,^([a-z-]+),  \x1b$(B)\1\x1b$(RST),"


.PHONY: install # Install dotfiles via dotbot
# -----------------------------------------------------------------------------

install:
	./install

.PHONY: upgrade # Upgrade dotbot to latest version
# -----------------------------------------------------------------------------

upgrade:
	git submodule update --remote dotbot
	git add dotbot
	git commit -m "chore: upgrade dotbot submodule"

.PHONY: check # Check new and changed files
# -----------------------------------------------------------------------------

check:
	$(if $(SH_CHANGED),  shellcheck $(SH_CHANGED))
	$(if $(YML_CHANGED), yamllint $(YML_CHANGED))
	$(if $(SH_CHANGED),  shfmt -d $(SH_CHANGED))

.PHONY: check-all # Check all files in the repository
# -----------------------------------------------------------------------------

check-all:
	$(if $(SH_ALL),  shellcheck $(SH_ALL))
	$(if $(YML_ALL), yamllint $(YML_ALL))
	$(if $(SH_ALL),  shfmt -d $(SH_ALL))

.PHONY: format # Format new and changed shell files
# -----------------------------------------------------------------------------

format:
	$(if $(SH_CHANGED), shfmt -w $(SH_CHANGED))

.PHONY: format-all # Format all shell files in the repository
# -----------------------------------------------------------------------------

format-all:
	$(if $(SH_ALL), shfmt -w $(SH_ALL))

# Clean
# -----------------------------------------------------------------------------

.PHONY: clean # Remove build artifacts and broken symlinks
clean: _rm-broken-links _rm-empty-dirs

.PHONY: _rm-broken-links
_rm-broken-links:
	find ~ -maxdepth 3 -xtype l -delete 2>/dev/null || true

.PHONY: _rm-empty-dirs
_rm-empty-dirs: _git-clean
	find . -type d -empty -delete

.PHONY: _git-clean
# Remove files that match `.gitignore` (but keep untracked files)
_git-clean:
	git clean -f -d -X
