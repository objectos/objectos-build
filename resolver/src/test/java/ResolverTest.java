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

import static org.testng.Assert.assertEquals;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import org.eclipse.aether.resolution.DependencyResolutionException;
import org.testng.annotations.Test;

public class ResolverTest {

  @Test
  public void resolveJacksonDatabind2() throws Exception {
    Path root;
    root = Files.createTempDirectory("resolver-test-");

    Path repository;
    repository = root.resolve("repository");

    Path resolution;
    resolution = root.resolve("resolution");

    try {
      Resolver resolver;
      resolver = new Resolver();

      String dependency;
      dependency = "com.fasterxml.jackson.core/jackson-databind/2.16.1";

      String[] args;
      args = new String[] {
          "--local-repo",
          repository.toString(),
          "--remote-repo",
          "https://repo.maven.apache.org/maven2/",
          "--resolution-dir",
          resolution.toString(),
          dependency
      };

      resolver.parseArgs(args);

      assertEquals(resolver.localRepositoryPath, repository);
      assertEquals(resolver.resolutionPath, resolution);
      assertEquals(resolver.requestedDependency, dependency);

      resolver.resolve();

      Path res;
      res = resolution.resolve(dependency);

      assertEquals(
          Files.readString(res),

          """
          ${REPO}/com/fasterxml/jackson/core/jackson-annotations/2.16.1/jackson-annotations-2.16.1.jar
          ${REPO}/com/fasterxml/jackson/core/jackson-core/2.16.1/jackson-core-2.16.1.jar
          ${REPO}/com/fasterxml/jackson/core/jackson-databind/2.16.1/jackson-databind-2.16.1.jar
          """.replace("${REPO}", repository.toString())
      );
    } finally {
      rmdir(root);
    }
  }

  @Test
  public void resolveTestNg771() throws Exception {
    Path root;
    root = Files.createTempDirectory("resolver-test-");

    Path repository;
    repository = root.resolve("repository");

    Path resolution;
    resolution = root.resolve("resolution");

    try {
      Resolver resolver;
      resolver = new Resolver();

      String dependency;
      dependency = "org.testng/testng/7.7.1";

      String[] args;
      args = new String[] {
          "--local-repo",
          repository.toString(),
          "--remote-repo",
          "https://repo.maven.apache.org/maven2/",
          "--resolution-dir",
          resolution.toString(),
          dependency
      };

      resolver.parseArgs(args);

      assertEquals(resolver.localRepositoryPath, repository);
      assertEquals(resolver.resolutionPath, resolution);
      assertEquals(resolver.requestedDependency, dependency);

      resolver.resolve();

      isRegularFile(repository, "com/beust/jcommander/1.82/jcommander-1.82.jar");
      isRegularFile(repository, "org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar");
      isRegularFile(repository, "org/testng/testng/7.7.1/testng-7.7.1.jar");
      isRegularFile(repository, "org/webjars/jquery/3.6.1/jquery-3.6.1.jar");

      Path res;
      res = resolution.resolve(dependency);

      assertEquals(
          Files.readString(res),

          """
          ${REPO}/com/beust/jcommander/1.82/jcommander-1.82.jar
          ${REPO}/org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar
          ${REPO}/org/testng/testng/7.7.1/testng-7.7.1.jar
          ${REPO}/org/webjars/jquery/3.6.1/jquery-3.6.1.jar
          """.replace("${REPO}", repository.toString())
      );
    } finally {
      rmdir(root);
    }
  }

  @Test
  public void resolveWay017Snapshot() throws IOException, DependencyResolutionException {
    Path root;
    root = Files.createTempDirectory("resolver-test-");

    Path repository;
    repository = root.resolve("repository");

    Path resolution;
    resolution = root.resolve("resolution");

    try {
      Resolver resolver;
      resolver = new Resolver();

      String dependency;
      dependency = "br.com.objectos/objectos.way/0.1.11-SNAPSHOT";

      String[] args;
      args = new String[] {
          "--local-repo",
          repository.toString(),
          "--remote-repo",
          "https://repo.maven.apache.org/maven2/",
          "--remote-repo",
          "https://oss.sonatype.org/content/repositories/snapshots",
          "--resolution-dir",
          resolution.toString(),
          dependency
      };

      resolver.parseArgs(args);

      assertEquals(resolver.localRepositoryPath, repository);
      assertEquals(resolver.resolutionPath, resolution);
      assertEquals(resolver.requestedDependency, dependency);

      resolver.resolve();

      isRegularFile(repository, "br/com/objectos/objectos.way/0.1.11-SNAPSHOT/objectos.way-0.1.11-SNAPSHOT.jar");
      isRegularFile(repository, "br/com/objectos/objectos.way/0.1.11-SNAPSHOT/objectos.way-0.1.11-SNAPSHOT.pom");

      Path res;
      res = resolution.resolve(dependency);

      assertEquals(
          Files.readString(res),

          """
          ${REPO}/br/com/objectos/objectos.way/0.1.11-SNAPSHOT/objectos.way-0.1.11-SNAPSHOT.jar
          """.replace("${REPO}", repository.toString())
      );
    } finally {
      rmdir(root);
    }
  }

  @Test
  public void resolveLocal() throws Exception {
    Path root;
    root = Files.createTempDirectory("resolver-test-");

    Path repository;
    repository = root.resolve("repository");

    Path resolution;
    resolution = root.resolve("resolution");

    try {
      Resolver resolver;
      resolver = new Resolver();

      String dependency;
      dependency = "com.example/test/1.0.0";

      String[] args;
      args = new String[] {
          "--local-repo",
          repository.toString(),
          "--resolution-dir",
          resolution.toString(),
          dependency
      };

      resolver.parseArgs(args);

      Path testPom;
      testPom = repository.resolve(Path.of("com", "example", "test", "1.0.0", "test-1.0.0.pom"));

      Files.createDirectories(testPom.getParent());

      Files.writeString(
          testPom,

          """
          <project>

          	<modelVersion>4.0.0</modelVersion>

          	<groupId>com.example</groupId>
          	<artifactId>test</artifactId>
          	<version>1.0.0</version>

          	<dependencies>
          		<dependency>
          			<groupId>org.slf4j</groupId>
          			<artifactId>slf4j-api</artifactId>
          			<version>1.7.36</version>
          		</dependency>
          	</dependencies>

          </project>
          """
      );

      Path testJar;
      testJar = repository.resolve(Path.of("com", "example", "test", "1.0.0", "test-1.0.0.jar"));

      Files.writeString(testJar, "dummy");

      assertEquals(resolver.localRepositoryPath, repository);
      assertEquals(resolver.resolutionPath, resolution);
      assertEquals(resolver.requestedDependency, dependency);

      resolver.resolve();

      isRegularFile(repository, "org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar");

      Path res;
      res = resolution.resolve(dependency);

      assertEquals(
          Files.readString(res),

          """
          ${REPO}/com/example/test/1.0.0/test-1.0.0.jar
          ${REPO}/org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar
          """.replace("${REPO}", repository.toString())
      );
    } finally {
      rmdir(root);
    }
  }

  private void isRegularFile(Path dir, String path) {
    Path file;
    file = dir.resolve(path);

    assertEquals(Files.isRegularFile(file), true);
  }

  private void rmdir(Path root) throws IOException {
    var rm = new SimpleFileVisitor<Path>() {
      @Override
      public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
        Files.delete(dir);
        return FileVisitResult.CONTINUE;
      }

      @Override
      public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
        Files.delete(file);
        return FileVisitResult.CONTINUE;
      }
    };

    Files.walkFileTree(root, rm);
  }

}