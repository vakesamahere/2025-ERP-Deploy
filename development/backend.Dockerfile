# Dev image for backend development
FROM maven:3.9.9-sapmachine-22

# Set a stable workspace path (compose will mount code here)
WORKDIR /workspace

# Keep Maven repo path explicit (will be mounted via volume for caching)
ENV MAVEN_CONFIG=/root/.m2

# Common app and debug ports
EXPOSE 8080 5005
