# Use Java 17 as the base image for dependency resolution
FROM eclipse-temurin:17-jdk-jammy AS deps

WORKDIR /build

# Copy the Maven wrapper with executable permissions
COPY --chmod=0755 mvnw mvnw
COPY .mvn/ .mvn/
COPY pom.xml pom.xml

# Download dependencies separately to leverage Docker's caching
RUN --mount=type=cache,target=/root/.m2 ./mvnw dependency:go-offline -DskipTests

################################################################################

# Build the application using the dependencies from the previous stage
FROM deps AS build

WORKDIR /build

COPY src src/
RUN --mount=type=cache,target=/root/.m2 ./mvnw package -DskipTests && \
    mv target/$(./mvnw help:evaluate -Dexpression=project.artifactId -q -DforceStdout)-$(./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout).jar target/app.jar

################################################################################

# Extract application layers using Spring Boot's layered JAR feature
FROM build AS extract

WORKDIR /build

RUN java -Djarmode=layertools -jar target/app.jar extract --destination target/extracted

################################################################################

# Use a lightweight JRE image for the final runtime stage
FROM eclipse-temurin:17-jre-jammy AS final

# Create a non-privileged user for running the application
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

WORKDIR /app

# Copy extracted layers from the build stage
COPY --from=extract /build/target/extracted/dependencies/ ./
COPY --from=extract /build/target/extracted/spring-boot-loader/ ./
COPY --from=extract /build/target/extracted/snapshot-dependencies/ ./
COPY --from=extract /build/target/extracted/application/ ./

EXPOSE 8080

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
