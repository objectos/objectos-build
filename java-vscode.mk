#
# Copyright (C) 2023-2024 Objectos Software LTDA.
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
# Generates a pom.xml so that VS Code can import a project
#

ifndef COMPILE_MARKER
$(error Required java-compile.mk was not included)
endif

ifndef TEST_COMPILE_MARKER
$(error Required java-test-compile.mk was not included)
endif

## generate the dependency tag
define VSCODE_DEPENDENCY
		<dependency>
			<groupId>$(1)</groupId>
			<artifactId>$(2)</artifactId>
			<version>$(3)</version>
			<scope>$(4)</scope>
		</dependency>

endef

mk-vscode-dep = $(call VSCODE_DEPENDENCY,$(call word-solidus,$(1),1),$(call word-solidus,$(1),2),$(call word-solidus,$(1),3),$(2))

## let's generate at the root of the project
VSCODE_FILE := pom.xml

## path to .mvn directory
VSCODE_MVNDIR := .mvn

## maven local settings file
VSCODE_LOCAL_SETTINGS := $(VSCODE_MVNDIR)/local-settings.xml

## maven local settings contents
define VSCODE_LOCAL_SETTINGS_CONTENTS :=
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>$(abspath $(LOCAL_REPO))</localRepository>
</settings>
endef

## mvn maven config file
VSCODE_MAVEN_CONFIG := $(VSCODE_MVNDIR)/maven.config

## mvn maven config contents
VSCODE_MAVEN_CONFIG_CONTENTS := --settings ./$(VSCODE_LOCAL_SETTINGS)

## assemble the compile deps
VSCODE_DEPS := $(foreach dep,$(COMPILE_DEPS),$(call mk-vscode-dep,$(dep),compile))

## assemble the test deps
VSCODE_DEPS += $(foreach dep,$(TEST_COMPILE_DEPS),$(call mk-vscode-dep,$(dep),test))

ifdef JAVA_RELEASE
VSCODE_COMPILER_RELEASE := <maven.compiler.release>$(JAVA_RELEASE)</maven.compiler.release>
endif

## the pom template
define VSCODE_CONTENTS =
<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright (C) 2023-2024 Objectos Software LTDA.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
<!-- This file was generated by vscode.mk. Do not edit! -->
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">

	<modelVersion>4.0.0</modelVersion>
	
	<groupId>$(GROUP_ID)</groupId>
	<artifactId>$(ARTIFACT_ID)</artifactId>
	<version>$(VERSION)</version>
	<name>$(GROUP_ID):$(ARTIFACT_ID)</name>

	<build>
		<directory>$${project.basedir}/work</directory>
		<outputDirectory>$${project.build.directory}/main</outputDirectory>		
		<testOutputDirectory>$${project.build.directory}/test</testOutputDirectory>
		<sourceDirectory>$${project.basedir}/main</sourceDirectory>
		<testSourceDirectory>$${project.basedir}/test</testSourceDirectory>
	</build>

	<properties>
		$(VSCODE_COMPILER_RELEASE)
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding> 
	</properties>
 
	<dependencies>
$(VSCODE_DEPS)	</dependencies>

</project>
endef

## force dep resolving
VSCODE_REQS := $(COMPILE_RESOLUTION_FILES)
VSCODE_REQS += $(TEST_COMPILE_RESOLUTION_FILES)

## required files
VSCODE_FILE_REQS := $(VSCODE_FILE)
VSCODE_FILE_REQS += $(VSCODE_LOCAL_SETTINGS)
VSCODE_FILE_REQS += $(VSCODE_MAVEN_CONFIG)

.PHONY: vscode
vscode: $(VSCODE_REQS) $(VSCODE_FILE_REQS)

.PHONY: vscode@clean
vscode@clean:
	rm -f $(VSCODE_FILE_REQS)

$(VSCODE_FILE): Makefile
	$(file > $@,$(VSCODE_CONTENTS))

$(VSCODE_MVNDIR):
	mkdir $@

$(VSCODE_LOCAL_SETTINGS): | $(VSCODE_MVNDIR)
	$(file > $@,$(VSCODE_LOCAL_SETTINGS_CONTENTS))

$(VSCODE_MAVEN_CONFIG): | $(VSCODE_MVNDIR)
	$(file > $@,$(VSCODE_MAVEN_CONFIG_CONTENTS))
