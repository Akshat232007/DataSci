# Stage 1: Build the Maven Web Application
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

# Stage 2: Serve using Apache Tomcat 10.1 (Jakarta EE 10 / Servlet 6.0)
FROM tomcat:10.1-jdk17

# Remove default Tomcat web applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy built WAR as ROOT.war so it serves at the root URL (/)
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
