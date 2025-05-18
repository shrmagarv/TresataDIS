FROM eclipse-temurin:21-jdk-alpine as build
WORKDIR /workspace/app

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Make the Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (this layer will be cached unless pom.xml changes)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN ./mvnw package -DskipTests

# Extract the built application for the final image
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../../../target/*.jar)

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
VOLUME /tmp

# Copy the built application from the build stage
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

# Create data directory for file storage
RUN mkdir -p /app/data
VOLUME /app/data

ENTRYPOINT ["java","-cp","app:app/lib/*","com.shrmagarv.tresatadis.TresataDisApplication"]

EXPOSE 8080
