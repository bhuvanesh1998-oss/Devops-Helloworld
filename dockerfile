# Use a base image with Java runtime
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the packaged JAR file into the container
COPY ./target/HelloWorld-uk-0.0.1-SNAPSHOT.jar app.jar

# Specify the command to run the JAR file
ENTRYPOINT ["java", "-jar", "app.jar"]

# Optional: Expose the port your application runs on (default 8080)
EXPOSE 8083