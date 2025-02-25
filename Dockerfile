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

# Install telnet and other useful networking tools
RUN apt-get update && \
    apt-get install -y telnet net-tools iputils-ping curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

WORKDIR /app

# Copy extracted layers from the build stage
COPY --from=extract --chown=appuser:appuser /build/target/extracted/dependencies/ ./
COPY --from=extract --chown=appuser:appuser /build/target/extracted/spring-boot-loader/ ./
COPY --from=extract --chown=appuser:appuser /build/target/extracted/snapshot-dependencies/ ./
COPY --from=extract --chown=appuser:appuser /build/target/extracted/application/ ./

# Switch to non-root user
USER appuser

# Set Spring specific properties
ENV SPRING_OUTPUT_ANSI_ENABLED=ALWAYS \
    JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
