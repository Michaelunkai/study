# Use a specific Alpine version to avoid potential issues with 'latest'
FROM alpine:3.18

# Update the APK index and change the repository mirror to avoid issues
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk update && \
    apk upgrade

# Install rsync
RUN apk --no-cache add rsync

# Set the working directory
WORKDIR /app

# Copy everything within the current path to /home/
COPY . /home/

# Default runtime options
CMD ["rsync", "-aP", "/home/", "/home/"]
