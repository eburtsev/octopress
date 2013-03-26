---
layout: post
title: "Maven custom repository layout"
date: 2012-11-10 08:42
comments: true
categories: [maven, java]
---

Приветствую всех.

Хочу поделиться с сообществом небольшим велосипедом - расширением для мавена позволяющим получать доступ к репозиториям с кастомной структурой.

Для начала расскажу как я до такого докатился. В процессе работы над проектом пришла мысль о том зависимости JavaScript типа JQuery ничем не управляются, и при обновлении приходится качать библиотеки вручную, что совершенно не впечатляет. И вот так появилось дикое желание найти какой-нибудь менеджер зависимостей но для javascript. В первую очередь в своих поисках я наткнулся на [Bower](http://twitter.github.com/bower/) но необходимость введения дополнительного шага в процессе сборки отпугивало как node.js в зависимостях. Тут я вспомнил про CDN с коих можно невозбранно тянуть js-библиотеки (например jquery на Google CDN: [http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js](http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js)). Поскольку в проекте используется maven для сборки то логичной мыслью было натравить его на эти залежи библиотек... Но все оказалось не так просто. Дело в том что структура файловой системы CDN отличается от стандартной для для maven. После 2 часов поиска решения на просторах интернетов найдено не было,и решил я написать свой велосипед. Если я еще не утомил вас то прошу под кат.

<!-- more -->

В процессе поиска готовых решений было замечено что можно написать расширение для maven обрабатывающее кастомный тип репозиториев. Правда не смотря на то что везде писалось что сделать можно, как это сделать нигде написано не было. Только однажды промелькнуло то что для этой цели служит интерфейс RepositoryConnectorFactory. На скорую руку был набросан простенький класс реализующий данный интерфейс:

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

Однако после подключения расширения к проекту, чуда не случилось - расширение не вызывалось, а мавен продолжал ругаться на не поддерживаемый тип репозитория. Как в оказалось дальнейшем для правильной работы расширения необходимо сгенерировать описание компонента в файле META-INF/plexus/components.xml. Для создания которого, можно воспользоваться плагином plexus-component-metadata, который распарсит аннотации к классам и создаст этот волшебный файлик.
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
После включения генерации components.xml и установки плагина в локальный репозиторий все заработало.

Теперь расскажу как использовать это безобразие. В первую очередь подключаем репозиторий с плагином (пока что я выложил в своем репозитории, в дальнейшем буду думать как поместить в Maven Central):
``` xml pom.xml
	<pluginRepositories>
		<pluginRepository>
			<id>maven-burtsev-net</id>
			<url>http://maven.burtsev.net</url>
		</pluginRepository>
	</pluginRepositories>
```

И включаем расширение в секции build pom.xml:
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

Подключаем необходимые репозитории, например так:
``` xml pom.xml
	<repository>
		<id>google-cdn</id>
		<url>http://ajax.googleapis.com/ajax/libs/$groupId/$version/$artifactId${classifier(prefix:.)}.$extension</url>
		<layout>custom</layout>
	</repository>
```

В URL репозитория указываются подстановочные символы которые будут заменены на соответствующие параметры для закачиваемого артифакта. Привожу список всех поддерживаемых подстановочных символов: 

* $groupId
* $artifactId
* $version
* $classifier
* $extension

Для параметров значение которых может быть пустым доступен альтернативный синтаксис: ```${classifier(prefix:.)}```. Это сделано для того что бы не дублировать разделители в URL в случае пустого значения параметра.

После подключения репозитория подключаем зависомости например так:
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

Для копирования загруженных библиотек в папку веб приложения используем maven-dependency-plugin:
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

Собственно все. Проблема решена - мы добились возможности рулить JS зависимостями с помощью maven.

Исходные коды плагина можно найти здесь: [https://bitbucket.org/eburtsev/maven-custom-repository-layout](https://bitbucket.org/eburtsev/maven-custom-repository-layout)
Сам плагин можно использовать напрямую из моего репозитория maven: [http://maven.burtsev.net/](http://maven.burtsev.net/)
Пример проекта с использованием описываемого расширения [https://bitbucket.org/eburtsev/test-javascript-dependencies](https://bitbucket.org/eburtsev/test-javascript-dependencies)

