#
#   Copyright 2017 Carl Anderson
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

MKDIR := $(shell which mkdir)
RM := $(shell which rm)
CP := $(shell which cp)
INSTALL := $(shell which install)
CHMOD := $(shell which chmod)
PRINTF := $(shell which printf)
SED := $(shell which sed)
GZIP_BIN := $(shell which gzip)
GZIP := $(GZIP_BIN) -9 -c
TEE := $(shell which tee)
FIND := $(shell which find)
TAR := $(shell which tar)
RSYNC := $(shell which rsync)
HERE := $(shell pwd)
PYTHON_DIR := $(HERE)/python
FILES_DIR := $(HERE)/files
SHELL_DIR := $(HERE)/shell
SRC_DIR := $(HERE)/src
LOCAL_MAN_DIR := $(HERE)/man
PYTHON_MAKEFILE := $(PYTHON_DIR)/Makefile
REV := r1
VERSION  := 0.8
UPDATED  := 2017-03-15
RVERSION := $(VERSION)$(REV)
ETC_DIR  := /usr/local/etc/advanced-shell-history
LIB_DIR  := /usr/local/lib/advanced_shell_history
BIN_DIR  := /usr/local/bin
TMP_ROOT := /tmp
TMP_DIR  := $(TMP_ROOT)/ash-$(RVERSION)
TMP_FILE := $(TMP_DIR).tar.gz
MAN_DIR  := /usr/share/man/man1
SRC_DEST := $(HERE)
SHELL    := /bin/bash

BEGIN_URL := https://github.com/barabo/advanced-shell-history

.PHONY: all build build_c build_python clean fixperms install install_c install_python man mrproper src_tarball src_tarball_minimal uninstall
all:	build man

new:	clean all

filesystem:
	$(MKDIR) -p $(FILES_DIR)$(BIN_DIR)
	$(MKDIR) -p $(FILES_DIR)${MAN_DIR}
	$(MKDIR) -p $(FILES_DIR)$(LIB_DIR)/sh
	$(INSTALL) -D -m 0755 $(SHELL_DIR)/* $(FILES_DIR)$(LIB_DIR)/sh
	$(INSTALL) -D -m 0644 config $(FILES_DIR)$(ETC_DIR)/config
	$(INSTALL) -D -m 0644 queries $(FILES_DIR)$(ETC_DIR)/queries

build_python: filesystem
	@ $(PRINTF) "\nCompiling source code...\n"
	make -C $(PYTHON_DIR) -f $(PYTHON_MAKEFILE) VERSION="$(RVERSION)"
	$(INSTALL) -D -m 0755 $(PYTHON_DIR)/*.py -t $(FILES_DIR)$(BIN_DIR)
	$(INSTALL) -D -m 0755 python/advanced_shell_history/*.py $(FILES_DIR)$(LIB_DIR)

build_c: filesystem
	@ $(PRINTF) "\nCompiling source code...\n"
	@ make -C $(SRC_DIR) -f $(SRC_DIR)/Makefile VERSION="$(RVERSION)"
	$(INSTALL) -D -m 0755 $(SRC_DIR)/_ash_log $(FILES_DIR)$(BIN_DIR)/_ash_log
	$(INSTALL) -D -m 0755 $(SRC_DIR)/ash_query $(FILES_DIR)$(BIN_DIR)/ash_query

build: build_python build_c

man:
	@ $(PRINTF) "\nGenerating man pages...\n"
	$(SED) -e "s:__DATE__:${UPDATED}:" -e "s:__VERSION__:Version $(RVERSION):" $(LOCAL_MAN_DIR)/_ash_log.1 | $(GZIP) | $(TEE) $(FILES_DIR)$(MAN_DIR)/_ash_log.1.gz > $(FILES_DIR)$(MAN_DIR)/_ash_log.py.1.gz
	$(SED) -e "s:__DATE__:$(UPDATED):" -e "s:__VERSION__:Version $(RVERSION):" $(LOCAL_MAN_DIR)/ash_query.1 | $(GZIP) | $(TEE) $(FILES_DIR)$(MAN_DIR)/ash_query.1.gz > $(FILES_DIR)$(MAN_DIR)/ash_query.py.1.gz
	$(FIND) $(FILES_DIR)$(MAN_DIR) -iname '*ash*.1.gz' -exec $(CHMOD) 644 '{}' \;

fixperms:
	$(CHMOD) 644 files/${LIB_DIR}/* files/${ETC_DIR}/*

overlay.tar.gz: fixperms
	$(TAR) cpzf $(HERE)/overlay.tar.gz -C $(FILES_DIR) $$($(FIND) find $(FILES_DIR) \( -type f -o -type l \) -not -ipath '*/.git*' -printf '%P\n'
	)

install: build man overlay.tar.gz uninstall
	@ $(PRINTF) "\nInstalling files:\n"
	$(TAR) xpzv --no-same-owner -C / -f $(HERE)/overlay.tar.gz
	@ $(PRINTF) "\n 0/ - Install completed!\n<Y    See: $(BEGIN_URL)\n/ \\ \n"

install_python: build_python man overlay.tar.gz uninstall
	@ $(PRINTF) "\nInstalling Python Advanced Shell History...\n"
	@ $(PRINTF) "\nInstalling files:\n"
	$(TAR) xzpv --no-same-owner -C / -f $(HERE)/overlay.tar.gz
	@ $(PRINTF) "\n 0/ - Install completed!\n<Y    See: $(BEGIN_URL)\n/ \\ \n"

install_c: build_c man overlay.tar.gz uninstall
	@ $(PRINTF) "\nInstalling C++ Advanced Shell History...\n"
	@ $(PRINTF) "\nInstalling files:\n"
	$(TAR) -xzpv --no-same-owner -C / -f $(HERE)/overlay.tar.gz
	@ $(PRINTF) "\n 0/ - Install completed!\n<Y    See: $(BEGIN_URL)\n/ \\ \n"

uninstall:
	@ $(PRINTF) "\nUninstalling Advanced Shell History...\n"
	$(RM) -rf $(ETC_DIR) $(LIB_DIR) || true
	$(RM) -f $(BIN_DIR)/{_ash_log,ash_query}{,.py}
	$(RM) -f $(MAN_DIR)/{_ash_log,ash_query}{.1.gz,.py.1.gz}
	$(RM) -f $(MAN_DIR)/advanced_shell_history

tarball:
	$(MKDIR) -p $(TMP_DIR)
	$(RSYNC) -Ca * $(TMP_DIR)
	tar czpf $(TMP_FILE) -C $(TMP_ROOT) ash-$(RVERSION)/
	$(RM) -rf $(TMP_DIR)

src_tarball_minimal: mrproper tarball
	$(INSTALL) -D -m 0644 $(TMP_FILE) $(SRC_DEST)/ash-$(RVERSION)-minimal.tar.gz

src_tarball: clean tarball
	$(INSTALL) -D -m 0644 $(TMP_FILE) $(SRC_DEST)/ash-$(RVERSION).tar.gz

clean:
	@ $(PRINTF) "\nCleaning temp and trash files...\n"
	make -C $(SRC_DIR) -f $(SRC_DIR)/Makefile distclean
	$(RM) -rf $(FILES_DIR)${BIN_DIR}
	$(RM) -rf $(FILES_DIR)${ETC_DIR}
	$(RM) -rf $(FILES_DIR)${LIB_DIR}
	$(RM) -rf $(FILES_DIR)${MAN_DIR}
	$(FIND) $(PYTHON_DIR) -type f -name '*.pyc' -delete
	$(RM) -rf $(TMP_DIR) $(TMP_FILE) $(HERE)/overlay.tar.gz
