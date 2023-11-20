#
# Copyright (C) 2023 Objectos Software LTDA.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# test execution options
#

define TEST_RUN_TASK

## test runtime dependencies
# $(1)TEST_RUNTIME_DEPS =

## test runtime required resolutions
$(1)TEST_RUNTIME_RESOLUTIONS = $$(call to-resolutions,$$($(1)TEST_RUNTIME_DEPS))

## test runtime required jars
$(1)TEST_RUNTIME_JARS = $$(call to-jars,$$($(1)TEST_RUNTIME_DEPS))

## test runtime module-path
$(1)TEST_RUNTIME_MODULE_PATH = $$(call module-path,$$($(1)TEST_RUNTIME_JARS))

## test main class
ifndef $(1)TEST_MAIN
$(1)TEST_MAIN = $$($(1)MODULE).RunTests
endif

## test runtime output path
$(1)TEST_RUNTIME_OUTPUT = $$($(1)WORK)/test-output

## test java command
$(1)TEST_JAVAX = $$(JAVA)
$(1)TEST_JAVAX += --module-path $$($(1)TEST_RUNTIME_MODULE_PATH)
ifdef $(1)TEST_JAVAX_MODULES
$(1)TEST_JAVAX += $$(foreach mod,$$($(1)TEST_JAVAX_MODULES),--add-modules $$(mod))
else
$(1)TEST_JAVAX += --add-modules org.testng
endif
$(1)TEST_JAVAX += --add-reads $$($(1)MODULE)=org.testng
ifdef $(1)TEST_JAVAX_READS
$(1)TEST_JAVAX += $$(foreach mod,$$($(1)TEST_JAVAX_READS),--add-reads $$($(1)MODULE)=$$(mod))
endif
ifdef $(1)TEST_JAVAX_EXPORTS
$(1)TEST_JAVAX += $$(foreach pkg,$$($(1)TEST_JAVAX_EXPORTS),--add-exports $$($(1)MODULE)/$$(pkg)=org.testng)
endif
ifeq ($$($(1)ENABLE_PREVIEW),1)
$(1)TEST_JAVAX += --enable-preview
endif
$(1)TEST_JAVAX += --patch-module $$($(1)MODULE)=$$($(1)TEST_CLASS_OUTPUT)
$(1)TEST_JAVAX += --module $$($(1)MODULE)/$$($(1)TEST_MAIN)
$(1)TEST_JAVAX += $$($(1)TEST_RUNTIME_OUTPUT)

## test execution marker
$(1)TEST_RUN_MARKER = $$($(1)TEST_RUNTIME_OUTPUT)/index.html

## test execution requirements
$(1)TEST_RUNTIME_REQS  = $$($(1)TEST_RUNTIME_RESOLUTIONS)
$(1)TEST_RUNTIME_REQS += $$($(1)TEST_COMPILE_MARKER)

#
# test execution targets
#

.PHONY: $(2)test
$(2)test: $$($(1)TEST_RUN_MARKER)

.PHONY: $(2)test-runtime-jars
$(2)test-runtime-jars: $$($(1)TEST_RUNTIME_JARS)

$$($(1)TEST_RUN_MARKER): $$($(1)TEST_RUNTIME_REQS)
	$$(MAKE) $(2)compile-jars 
	$$($(1)TEST_JAVAX)

endef
