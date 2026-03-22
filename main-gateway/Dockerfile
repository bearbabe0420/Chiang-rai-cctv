# Multi-stage build: compile with Maven, run on slim JRE

# ── Build stage ────────────────────────────────────────────────────────
FROM maven:3.9.11-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml ./
RUN mvn -B -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests package \
    && JAR_FILE=$(ls target/*.jar | grep -v '\.original$' | head -n 1) \
    && cp "$JAR_FILE" /app/app.jar

# ── Runtime stage ──────────────────────────────────────────────────────
# Changed from eclipse-temurin:17-jre-jammy to nvidia/cuda
# This gives the container access to NVENC + NVDEC (libnvidia-encode, libnvcuvid)
# jammy = Ubuntu 22.04, matches the original base so nothing else changes
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS runtime
WORKDIR /app

# Install JRE 17 on top of the CUDA base
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    # Required for JavaCV/FFmpeg NVENC to find the encode library at runtime
    libnvidia-encode-525 \
    && rm -rf /var/lib/apt/lists/*

# Copy the fat jar from the build stage
COPY --from=build /app/app.jar /app/app.jar

ENV JAVA_OPTS=""
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]