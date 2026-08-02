# spring-boot

A [Spring Boot](https://spring.io/projects/spring-boot) 3 web application
(Java 21, Maven) with optional SQL database support, serving on port 80.

- Main class: `src/main/java/uk/worldskills/module/Application.java`
- Routes: `AppController.java` (`/`, `/health`, `/db-status`)

## Database (optional)

Set by the platform via `DATABASE_URL` (`mysql://...` or `postgresql://...`),
converted to a JDBC URL at runtime. Drivers bundled: MySQL
(`com.mysql:mysql-connector-j`) and PostgreSQL (`org.postgresql:postgresql`).
`DataSourceAutoConfiguration` is excluded so the app boots with no database.

## Packages

Maven reads a mirror from the `MAVEN_MIRROR` build argument (the offline Nexus
Maven proxy during the competition). Add dependencies to `pom.xml`.
