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

override PKGSUBDIR = $(NAME)/$(SRCDIR_ROOT)
override WORKDIR_DEPS = $(WORKDIR_ROOT)/deps
override WORKDIR_TEST = $(WORKDIR_ROOT)/test/$(NAME)/$(VERSION)

override BINDIR_CONFIG_FILES := $(shell (cd $(SRCDIR_ROOT)/bin  && find . -type f) 2>/dev/null)
override HOMEDIR_CONFIG_FILES := $(shell (cd $(SRCDIR_ROOT)/home  && find . -type f) 2>>/dev/null)

# Error checking
ifneq ($(DESTDIR), $(abspath $(DESTDIR)))
$(error ERROR: Please specify DESTDIR as an absolute path)
endif

# Includes
BOXERBIRD_BRANCH := main
override BOXERBIRD.MK := $(WORKDIR_DEPS)/make-boxerbird/boxerbird.mk
$(BOXERBIRD.MK):
	@echo "Loading Boxerbird..."
	git clone --config advice.detachedHead=false --depth 1 \
			https://github.com/ic-designer/make-boxerbird.git --branch $(BOXERBIRD_BRANCH) \
			$(WORKDIR_DEPS)/make-boxerbird
	@echo
include $(BOXERBIRD.MK)

# Targets
.PHONY: private_clean
private_clean:
	@echo "INFO: Cleaning directories:"
	@$(if $(wildcard $(WORKDIR_DEPS)), rm -rfv $(WORKDIR_DEPS))
	@$(if $(wildcard $(WORKDIR_ROOT)), rm -rfv $(WORKDIR_ROOT))
	@$(if $(wildcard $(WORKDIR_TEST)), rm -rfv $(WORKDIR_TEST))
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
	$(boxerbird::install-as-copy)

$(DESTDIR)/$(BINDIR)/%: $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/bin/%
	$(boxerbird::install-as-link)

$(DESTDIR)/$(HOMEDIR)/%: $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/home/%
	$(boxerbird::install-as-link)


.PHONY: private_test
private_test :
	$(MAKE) install DESTDIR=$(abspath $(WORKDIR_TEST))/$(PKGSUBDIR) WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) uninstall DESTDIR=$(abspath $(WORKDIR_TEST))/$(PKGSUBDIR) WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) shared-hook-test WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) hook-test WORKDIR_ROOT=$(WORKDIR_ROOT)
	@echo "INFO: Testing complete"
	@echo


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
