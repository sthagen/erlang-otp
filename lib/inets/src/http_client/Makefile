#
# %CopyrightBegin%
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright Ericsson AB 2005-2025. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# %CopyrightEnd%
#
#

include $(ERL_TOP)/make/target.mk
EBIN = ../../ebin
include $(ERL_TOP)/make/$(TARGET)/otp.mk


# ----------------------------------------------------
# Application version
# ----------------------------------------------------
include ../../vsn.mk

VSN = $(INETS_VSN)


# ----------------------------------------------------
# Release directory specification
# ----------------------------------------------------
RELSYSDIR = $(RELEASE_PATH)/lib/$(APPLICATION)-$(VSN)


# ----------------------------------------------------
# Target Specs
# ----------------------------------------------------
MODULES = \
	httpc \
	httpc_cookie \
	httpc_handler \
	httpc_manager \
	httpc_sup \
	httpc_handler_sup \
	httpc_profile_sup \
	httpc_response \
	httpc_request \

HRL_FILES = httpc_internal.hrl

ERL_FILES = $(MODULES:%=%.erl)

TARGET_FILES= $(MODULES:%=$(EBIN)/%.$(EMULATOR)) 

DEPDIR=deps
DEP_FILE=$(DEPDIR)/http_client.d
$(shell mkdir -p $(dir $(DEP_FILE)) >/dev/null)

ifeq ($(TARGET), win32)
  # Native path without C: ignore driveletter case
  ERL_TOP_NATIVE = $(shell w32_path.sh -m $(ERL_TOP) | sed "s@[a-zA-Z]:@:@")
else
  ERL_TOP_NATIVE = $(ERL_TOP)
endif


# ----------------------------------------------------
# FLAGS
# ----------------------------------------------------

include ../inets_app/inets.mk

ERL_COMPILE_FLAGS += \
	$(INETS_FLAGS) \
	$(INETS_ERL_COMPILE_FLAGS) \
	-I../../include \
	-I../inets_app \
	-I../http_lib


# ----------------------------------------------------
# Targets
# ----------------------------------------------------

$(TYPES): $(TARGET_FILES) $(DEP_FILE)

deps: $(DEP_FILE)

clean:
	rm -f $(TARGET_FILES)
	rm -f core
	rm -rf $(DEPDIR)

docs:

# Release Target
# ---------------------------------------------------- 
include $(ERL_TOP)/make/otp_release_targets.mk

release_spec: opt
	$(INSTALL_DIR)  "$(RELSYSDIR)/src"
	$(INSTALL_DIR)  "$(RELSYSDIR)/src/http_client"
	$(INSTALL_DATA) $(HRL_FILES) $(ERL_FILES) "$(RELSYSDIR)/src/http_client"
	$(INSTALL_DIR)  "$(RELSYSDIR)/ebin"
	$(INSTALL_DATA) $(TARGET_FILES) "$(RELSYSDIR)/ebin"

release_docs_spec:

info:
	@echo "APPLICATION       = $(APPLICATION)"
	@echo "INETS_DEBUG       = $(INETS_DEBUG)"
	@echo "INETS_FLAGS       = $(INETS_FLAGS)"
	@echo "ERL_COMPILE_FLAGS = $(ERL_COMPILE_FLAGS)"

$(DEP_FILE): $(ERL_FILES)
	@echo SED $(TARGET) $(ERL_TOP_NATIVE)
	$(gen_verbose)erlc -M $(ERL_FILES) \
	| perl -pe "s@ [a-zA-Z]?$(ERL_TOP_NATIVE)/(?:bootstrap/)?lib/([^/]+)@ ../../../\1@g" 2> /dev/null \
	| sed "s/\.$(EMULATOR)/\.$$\(EMULATOR\)/" \
	| sed 's@^httpc@$$(EBIN)/httpc@' \
	> $(DEP_FILE)


# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------
-include $(DEP_FILE)

