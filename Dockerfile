# Stage 1: Build Nitter from the nimlang image
FROM nimlang/nim:2.0.0-alpine-regular as nim

# Install required dependencies
RUN apk --no-cache add libsass-dev pcre

# Set working directory for Nitter source code
WORKDIR /src/nitter

# Copy the nimble file and install dependencies
COPY nitter.nimble .
RUN nimble install -y --depsOnly

# Copy the rest of the source code
COPY . .

# Build the Nitter binary and handle other necessary tasks
RUN nimble build -d:danger -d:lto -d:strip \
    && nimble scss \
    && nimble md

# Stage 2: Set up the final image
FROM alpine:latest

# Set working directory
WORKDIR /src/

# Install runtime dependencies
RUN apk --no-cache add pcre ca-certificates

# Copy the built Nitter binary and necessary files from the previous stage
COPY --from=nim /src/nitter/nitter ./
COPY --from=nim /src/nitter/nitter.example.conf ./nitter.conf
COPY --from=nim /src/nitter/public ./public

# Expose the required port
EXPOSE 8080

# Create a non-root user and set it as the owner of the application
RUN adduser -h /src/ -D -s /bin/sh nitter
USER nitter

# Set the command to run the application
CMD ./nitter
