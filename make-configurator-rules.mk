# Constants
DESTDIR ?= $(error ERROR: Undefined variable DESTDIR)
HOMEDIR ?= $(error ERROR: Undefined variable HOMEDIR)
LIBDIR ?= $(error ERROR: Undefined variable LIBDIR)
NAME ?= $(error ERROR: Undefined variable NAME)
PREFIX ?= $(error ERROR: Undefined variable PREFIX)
SRCDIR_ROOT ?= $(error ERROR: Undefined variable SRCDIR_ROOT)
VERSION ?= $(error ERROR: Undefined variable VERSION)
WORKDIR_ROOT ?= $(error ERROR: Undefined variable WORKDIR_ROOT)

override PKGSUBDIR = $(NAME)/$(SRCDIR_ROOT)
override SRCDIR_CONFIG_FILES := $(shell cd $(SRCDIR_ROOT)/src && find . -type f)
override WORKDIR_DEPS = $(WORKDIR_ROOT)/deps
override WORKDIR_TEST = $(WORKDIR_ROOT)/test/$(NAME)/$(VERSION)

export

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
private_install: $(foreach f, $(SRCDIR_CONFIG_FILES), $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/$(f) $(DESTDIR)/$(HOMEDIR)/$(f))
	diff -r $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR) $(SRCDIR_ROOT)/src/
	$(MAKE) shared-hook-install WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) hook-install WORKDIR_ROOT=$(WORKDIR_ROOT)
	@echo "INFO: Installation complete"
	@echo

$(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/%: $(SRCDIR_ROOT)/src/%
	$(boxerbird::install-as-copy)

$(DESTDIR)/$(HOMEDIR)/%: $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)/%
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
	@$(foreach s, $(SRCDIR_CONFIG_FILES), \
		rm -v $(DESTDIR)/$(HOMEDIR)/$(s); \
		test ! -e $(DESTDIR)/$(HOMEDIR)/$(s); \
		rm -dv $(dir $(DESTDIR)/$(HOMEDIR)/$(s)) 2> /dev/null || true;\
	)
	@\rm -rdfv $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR) 2> /dev/null || true
	@\rm -dv $(dir $(DESTDIR)/$(LIBDIR)/$(PKGSUBDIR)) 2> /dev/null || true
	@\rm -dv $(DESTDIR)/$(LIBDIR) 2> /dev/null || true
	$(MAKE) shared-hook-uninstall WORKDIR_ROOT=$(WORKDIR_ROOT)
	$(MAKE) hook-uninstall WORKDIR_ROOT=$(WORKDIR_ROOT)
	@echo "INFO: Uninstallation complete"
	@echo
