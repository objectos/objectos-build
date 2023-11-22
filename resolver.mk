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
# Dependencies related options & functions
#

define RESOLVER_SRC
/*
 * Copyright (C) 2023 Objectos Software LTDA.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import org.apache.maven.repository.internal.MavenRepositorySystemUtils;
import org.eclipse.aether.AbstractRepositoryListener;
import org.eclipse.aether.DefaultRepositorySystemSession;
import org.eclipse.aether.RepositoryEvent;
import org.eclipse.aether.RepositoryListener;
import org.eclipse.aether.RepositorySystem;
import org.eclipse.aether.RepositorySystemSession;
import org.eclipse.aether.artifact.Artifact;
import org.eclipse.aether.artifact.DefaultArtifact;
import org.eclipse.aether.collection.CollectRequest;
import org.eclipse.aether.graph.Dependency;
import org.eclipse.aether.repository.LocalRepository;
import org.eclipse.aether.repository.LocalRepositoryManager;
import org.eclipse.aether.repository.RemoteRepository;
import org.eclipse.aether.resolution.ArtifactResult;
import org.eclipse.aether.resolution.DependencyRequest;
import org.eclipse.aether.resolution.DependencyResolutionException;
import org.eclipse.aether.resolution.DependencyResult;
import org.eclipse.aether.supplier.RepositorySystemSupplier;
import org.eclipse.aether.util.artifact.JavaScopes;

public class Resolver {

  Path localRepositoryPath;

  Path resolutionPath;

  String dependency;

  Artifact requestedArtifact;

  Resolver() {}

  public static void main(String[] args) {
    try {
      Resolver resolver;
      resolver = new Resolver();

      resolver.parseArgs(args);

      resolver.resolve();
    } catch (Exception e) {
      e.printStackTrace();

      System.exit(1);
    }
  }

  final void parseArgs(String[] args) {
    int index;
    index = 0;

    int length;
    length = args.length;

    int requestedCount;
    requestedCount = 0;

    while (index < length) {
      String arg;
      arg = args[index++];

      switch (arg) {
        case "--local-repo" -> {
          if (index < length) {
            String name;
            name = args[index++];

            localRepositoryPath = Path.of(name);
          }
        }

        case "--resolution-dir" -> {
          if (index < length) {
            String name;
            name = args[index++];

            resolutionPath = Path.of(name);
          }
        }

        default -> {
          requestedCount++;

          dependency = arg;
        }
      }
    }

    List<String> errors;
    errors = new ArrayList<>();

    if (localRepositoryPath == null) {
      errors.add("[ERROR] missing required option --local-repo [dir]");
    }

    if (resolutionPath == null) {
      errors.add("[ERROR] missing required option --resolution-dir [dir]");
    }

    if (requestedCount == 0) {
      errors.add("[ERROR] missing required option groupId/artifactId/version");
    }

    if (requestedCount > 1) {
      errors.add("[ERROR] multiple artifacts requested. Resolving only one artifact is supported.");
    }

    if (!errors.isEmpty()) {
      String msg;
      msg = errors.stream().collect(Collectors.joining("\n"));

      throw new IllegalArgumentException(msg);
    }

    String gav;
    gav = dependency.replace('/', ':');

    requestedArtifact = new DefaultArtifact(gav);
  }

  final void resolve() throws DependencyResolutionException, IOException {
    // RepositorySystem

    RepositorySystem repositorySystem;
    repositorySystem = newRepositorySystem();

    // RepositorySystemSession

    RepositorySystemSession session;
    session = newRepositorySystemSession(repositorySystem);

    // CollectRequest

    CollectRequest collectRequest;
    collectRequest = new CollectRequest();

    List<Dependency> dependencies;
    dependencies = createDependencies();

    collectRequest.setDependencies(dependencies);

    RemoteRepository central;
    central = new RemoteRepository.Builder("central", "default", "https://repo.maven.apache.org/maven2/").build();

    List<RemoteRepository> repositories;
    repositories = List.of(central);

    collectRequest.setRepositories(repositories);

    // DependencyRequest

    DependencyRequest dependencyRequest;
    dependencyRequest = new DependencyRequest(collectRequest, null);

    DependencyResult dependencyResult;
    dependencyResult = repositorySystem.resolveDependencies(session, dependencyRequest);

    List<ArtifactResult> artifacts;
    artifacts = dependencyResult.getArtifactResults();

    String contents = artifacts.stream()
        .map(ArtifactResult::getArtifact)
        .map(Artifact::getFile)
        .map(File::toPath)
        .map(path -> localRepositoryPath.relativize(path))
        .map(Path::toString)
        .sorted()
        .collect(Collectors.joining("\n", "", "\n"));

    Path targetFile;
    targetFile = resolutionPath.resolve(dependency);

    Files.createDirectories(targetFile.getParent());

    Files.writeString(
        targetFile, contents, StandardCharsets.UTF_8,
        StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING
    );
  }

  private RepositorySystem newRepositorySystem() {
    RepositorySystemSupplier repositorySystemSupplier;
    repositorySystemSupplier = new RepositorySystemSupplier();

    return repositorySystemSupplier.get();
  }

  private RepositorySystemSession newRepositorySystemSession(RepositorySystem repositorySystem) {
    DefaultRepositorySystemSession session;
    session = MavenRepositorySystemUtils.newSession();

    File localRepositoryFile;
    localRepositoryFile = localRepositoryPath.toFile();

    LocalRepository localRepository;
    localRepository = new LocalRepository(localRepositoryFile);

    LocalRepositoryManager localRepositoryManager;
    localRepositoryManager = repositorySystem.newLocalRepositoryManager(session, localRepository);

    session.setLocalRepositoryManager(localRepositoryManager);

    RepositoryListener repositoryListener;
    repositoryListener = new ThisRepositoryListener();

    session.setRepositoryListener(repositoryListener);

    return session;
  }

  private List<Dependency> createDependencies() {
    String scope;
    scope = JavaScopes.COMPILE;

    Dependency dependency;
    dependency = new Dependency(requestedArtifact, scope);

    return List.of(dependency);
  }

}

final class ThisRepositoryListener extends AbstractRepositoryListener {

  @Override
  public final void artifactDownloading(RepositoryEvent event) {
    Artifact artifact;
    artifact = event.getArtifact();

    log("Downloading", artifact);
  }

  private void log(String action, Artifact artifact) {
    System.out.println(action + " " + artifact);
  }

}
endef

## Resolver.java path
RESOLVER_JAVA = $(OBJECTOS_DIR)/Resolver.java

## Resolver.java deps
RESOLVER_DEPS  = commons-codec/commons-codec/1.16.0
RESOLVER_DEPS += org.apache.commons/commons-lang3/3.12.0
RESOLVER_DEPS += org.apache.httpcomponents/httpclient/4.5.14
RESOLVER_DEPS += org.apache.httpcomponents/httpcore/4.4.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-api/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-connector-basic/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-impl/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-named-locks/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-spi/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-supplier/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-transport-file/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-transport-http/1.9.16
RESOLVER_DEPS += org.apache.maven.resolver/maven-resolver-util/1.9.16
RESOLVER_DEPS += org.apache.maven/maven-artifact/3.9.4
RESOLVER_DEPS += org.apache.maven/maven-builder-support/3.9.4
RESOLVER_DEPS += org.apache.maven/maven-model-builder/3.9.4
RESOLVER_DEPS += org.apache.maven/maven-model/3.9.4
RESOLVER_DEPS += org.apache.maven/maven-repository-metadata/3.9.4
RESOLVER_DEPS += org.apache.maven/maven-resolver-provider/3.9.4
RESOLVER_DEPS += org.codehaus.plexus/plexus-interpolation/1.26
RESOLVER_DEPS += org.codehaus.plexus/plexus-utils/3.5.1
RESOLVER_DEPS += org.slf4j/jcl-over-slf4j/1.7.36
RESOLVER_DEPS += org.slf4j/slf4j-api/1.7.36
RESOLVER_DEPS += org.slf4j/slf4j-nop/1.7.36

## dep-to-jar
word-solidus = $(word $(2), $(subst $(solidus),$(space),$(1)))
mk-resolved-jar = $(call mk-dependency,$(call word-solidus,$(1),1),$(call word-solidus,$(1),2),$(call word-solidus,$(1),3))
dep-to-jar = $(foreach dep,$(1),$(LOCAL_REPO_PATH)/$(call mk-resolved-jar,$(dep)))

## Resolver.java jars
RESOLVER_DEPS_JARS = $(call dep-to-jar,$(RESOLVER_DEPS))

## resolve java command
RESOLVEX  = $(JAVA)
RESOLVEX += --class-path $(call class-path,$(RESOLVER_DEPS_JARS))
RESOLVEX += $(RESOLVER_JAVA)
RESOLVEX += --local-repo $(LOCAL_REPO_PATH)
RESOLVEX += --resolution-dir $(RESOLUTION_DIR)

#
# resolver rules
#

$(RESOLVER_JAVA): export src = $(RESOLVER_SRC)
$(RESOLVER_JAVA):
	mkdir --parents $(@D)
	echo "$${src}" > $@
