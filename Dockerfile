# Use a base image
FROM alpine:3.19

# Install rsync
RUN apk --no-cache add rsync

# Set the working directory
WORKDIR /app

# Copy everything within the current path to /home/
COPY . /home/

# Default runtime options
CMD ["rsync", "-aP", "/home/", "/home/"]
