# Config
export

# Constants
NAME ?= $(error ERROR: Undefined variable NAME)
VERSION ?= $(error ERROR: Undefined variable VERSION)

DESTDIR ?= $(error ERROR: Undefined variable DESTDIR)
HOMEDIR ?= $(error ERROR: Undefined variable HOMEDIR)
PREFIX ?= $(error ERROR: Undefined variable PREFIX)
BINDIR ?= $(error ERROR: Undefined variable BINDIR)
LIBDIR ?= $(error ERROR: Undefined variable LIBDIR)

SRCDIR_ROOT ?= $(error ERROR: Undefined variable SRCDIR_ROOT)
WORKDIR_ROOT ?= $(error ERROR: Undefined variable WORKDIR_ROOT)
WORKDIR_DEPS ?= $(error ERROR: Undefined variable WORKDIR_DEPS)

override PKGSUBDIR = $(NAME)/$(SRCDIR_ROOT)
override BINDIR_CONFIG_FILES := $(shell (cd $(SRCDIR_ROOT)/bin  && find . -type f) 2>/dev/null)
override HOMEDIR_CONFIG_FILES := $(shell (cd $(SRCDIR_ROOT)/home  && find . -type f) 2>>/dev/null)

# Error checking
ifneq ($(DESTDIR), $(abspath $(DESTDIR)))
$(error ERROR: Please specify DESTDIR as an absolute path)
endif

# Targets
.PHONY: private_clean
private_clean:
	@echo "INFO: Cleaning directories:"
	@$(if $(wildcard $(WORKDIR_DEPS)), rm -rfv $(WORKDIR_DEPS))
	@$(if $(wildcard $(WORKDIR_ROOT)), rm -rfv $(WORKDIR_ROOT))
	@echo "INFO: Cleaning complete"
	@echo


.PHONY: private_install
private_install: \
			$(foreach f, $(BINDIR_CONFIG_FILES), $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/bin/$(f) $(DESTDIR)/$(BINDIR)/$(f)) \
			$(foreach f, $(HOMEDIR_CONFIG_FILES), $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/home/$(f) $(DESTDIR)/$(HOMEDIR)/$(f))
	@$(if $(wildcard $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/bin), diff -r $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/bin $(SRCDIR_ROOT)/bin)
	@$(if $(wildcard $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/home), diff -r $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/home $(SRCDIR_ROOT)/home)
	$(MAKE) shared-hook-install WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) hook-install WORKDIR_ROOT=$(WORKDIR_ROOT)
	@echo "INFO: Installation complete"
	@echo

$(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/%: $(SRCDIR_ROOT)/%
	$(bowerbird::install-as-copy)

$(DESTDIR)/$(BINDIR)/%: $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/bin/%
	$(bowerbird::install-as-link)

$(DESTDIR)/$(HOMEDIR)/%: $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/home/%
	$(bowerbird::install-as-link)


.PHONY: private_uninstall
private_uninstall:
	@echo "INFO: Uninstalling $(NAME)"
	@$(foreach s, $(BINDIR_CONFIG_FILES), \
		rm -v $(DESTDIR)/$(BINDIR)/$(s); \
		test ! -e $(DESTDIR)/$(BINDIR)/$(s); \
		rm -dv $(dir $(DESTDIR)/$(BINDIR)/$(s)) 2> /dev/null || true; \
	)
	@$(foreach s, $(HOMEDIR_CONFIG_FILES), \
		rm -v $(DESTDIR)/$(HOMEDIR)/$(s); \
		test ! -e $(DESTDIR)/$(HOMEDIR)/$(s); \
		rm -dv $(dir $(DESTDIR)/$(HOMEDIR)/$(s)) 2> /dev/null || true; \
	)
	@\rm -rdfv $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR) 2> /dev/null || true
	@\rm -dv $(dir $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)) 2> /dev/null || true
	@\rm -dv $(DESTDIR)/$(LIBDIR) 2> /dev/null || true
	$(MAKE) shared-hook-uninstall WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) hook-uninstall WORKDIR_ROOT=$(WORKDIR_ROOT)
	@echo "INFO: Uninstallation complete"
	@echo
