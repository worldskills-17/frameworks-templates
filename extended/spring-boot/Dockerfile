# spring-boot - multi-stage Maven build. MAVEN_MIRROR points at the offline Nexus
# Maven proxy during competition builds; defaults to Maven Central for local ones.
FROM maven:3.9-eclipse-temurin-21 AS build
ARG MAVEN_MIRROR=https://repo.maven.apache.org/maven2
WORKDIR /app
# Point Maven at the mirror (a Nexus proxy of Maven Central when offline).
RUN mkdir -p /root/.m2 && \
    printf '<settings><mirrors><mirror><id>ws-mirror</id><name>ws</name><url>%s</url><mirrorOf>central</mirrorOf></mirror></mirrors></settings>' "$MAVEN_MIRROR" > /root/.m2/settings.xml
COPY pom.xml ./
RUN mvn -B -s /root/.m2/settings.xml dependency:go-offline -DskipTests || true
COPY src ./src
RUN mvn -B -s /root/.m2/settings.xml package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/app.jar /app/app.jar
EXPOSE 80
CMD ["java", "-jar", "/app/app.jar"]
