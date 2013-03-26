---
layout: post
title: "Maven custom repository layout"
date: 2012-11-10 08:42
comments: true
categories: [maven, java]
---

I've developed maven plugin to access repositories with custom structure. And I would share this solution with community.

Some time ago, I worked on java web project, and I used some JavaScript dependencies for it. 
I've throught about dependency management for javascript dependencies like JQuery. Ordinary JS dependencies is not management, so we need download new versions manually.
First I found [Bower](http://twitter.github.com/bower/) for javascript dependency management, but I afraid of node.js in dependencies for my project. I thought about CDNs which hosts js libraries. (for example jquery on Google CDN: [http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js](http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js)).
I using maven in my projec, so it will be good to use CDNs via maven... Because CDN's directories stricture is differs from standart maven layout, I decided to write own maven plugin to handle custom repository layout.

<!-- more -->

When I looked for solution I found that maven allows write plugins which handles custom repository types. But I found too less examples how to do it. I found only one thing: for create custom repository handler we needs to implement RepositoryConnectorFactory interface. I've created simple calss to test this approach:

``` java CustomRepositoryConnectorFactory.java
@Component(role = RepositoryConnectorFactory.class, hint = "custom")
public class CustomRepositoryConnectorFactory implements RepositoryConnectorFactory, Service {

        @Override
        public RepositoryConnector newInstance(RepositorySystemSession session,
                RemoteRepository repository) throws NoRepositoryConnectorException {
                System.out.println("CustomRepositoryConnectorFactory.newInstance()");
                return null;
        }

        @Override
        public int getPriority() {
                return 1;
        }

        @Override
        public void initService(ServiceLocator locator) {

        }
}
```

But this has not worked. To make it work we also need to generate maven component description in META-INF/plexus/components.xml file. To create this file there is plexus-component-metadata plugin, which parses annotations and creates this magic file.

``` xml components.xml
        <plugin>
                <groupId>org.codehaus.plexus</groupId>
                <artifactId>plexus-component-metadata</artifactId>
                <version>1.5.5</version>
                <executions>
                        <execution>
                                <goals>
                                        <goal>generate-metadata</goal>
                                </goals>
                        </execution>
                </executions>
        </plugin>
```
After components.xml generated and I installed plugin in my local repository all worked fine.

How to use it. First, add my maven repo in your pom.xml (for a while I host it in my own repo, but in future I want to move it to Maven Central):
``` xml pom.xml
	<pluginRepositories>
		<pluginRepository>
			<id>maven-burtsev-net</id>
			<url>http://maven.burtsev.net</url>
		</pluginRepository>
	</pluginRepositories>
```

Enable plugin in build section of pom.xml:
``` xml pom.xml
	<build>
		<extensions>
			<extension>
				<groupId>net.burtsev.maven</groupId>
				<artifactId>maven-custom-repository-layout</artifactId>
				<version>1.0</version>
			</extension>
		</extensions>
	</build>
```

Add some repositories, for example:
``` xml pom.xml
	<repository>
		<id>google-cdn</id>
		<url>http://ajax.googleapis.com/ajax/libs/$groupId/$version/$artifactId${classifier(prefix:.)}.$extension</url>
		<layout>custom</layout>
	</repository>
```

In repository URL we can use following wildcards which will replaced with appropriate values for each artifact: 

* $groupId
* $artifactId
* $version
* $classifier
* $extension

For parameter which can be empty there is alternate syntax: ```${classifier(prefix:.)}```. this syntax is useful for eliminate separators duplicates if value will empty.

After we configured repository we can add some dependencies, for example:
``` xml pom.xml
	<dependencies>
		<dependency>
			<groupId>jquery</groupId>
			<artifactId>jquery</artifactId>
			<version>1.8.2</version>
			<classifier>min</classifier>
			<type>js</type>
		</dependency>
	</dependencies>
```

I've used maven-dependency-plugin to copy downloaded libraries to webapp folder:
``` xml pom.xml
	<plugins>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-dependency-plugin</artifactId>
			<executions>
				<execution>
					<id>copy-dependencies</id>
					<phase>generate-resources</phase>
					<goals>
						<goal>copy-dependencies</goal>
					</goals>
					<configuration>
						<outputDirectory>${project.build.directory}/${project.build.finalName}/js</outputDirectory>
						<includeArtifactIds>jquery</includeArtifactIds>
						<includeTypes>js</includeTypes>
					</configuration>
				</execution>
			</executions>
		</plugin>
	</plugins>
```

That is it. Now we can manage JS dependencies with maven.

Sources can be found here: [https://bitbucket.org/eburtsev/maven-custom-repository-layout](https://bitbucket.org/eburtsev/maven-custom-repository-layout)
Plugin can be downloaded from my maven repository: [http://maven.burtsev.net/](http://maven.burtsev.net/)
Sample project uses this plugin [https://bitbucket.org/eburtsev/test-javascript-dependencies](https://bitbucket.org/eburtsev/test-javascript-dependencies)

