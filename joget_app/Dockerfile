# Use a lightweight JDK base image
FROM openjdk:17-jdk-slim

# Set working directory
WORKDIR /app

# Copy the fat JAR to the container
COPY target/joget_app-1.0-SNAPSHOT.jar app.jar

# Set default command
CMD ["java", "-jar", "app.jar"]
