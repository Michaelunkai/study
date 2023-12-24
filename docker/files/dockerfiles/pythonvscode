FROM python

# Install required dependencies for VSCode
RUN apt-get update && \
    apt-get install -y \
        curl \
        gpg \
        apt-transport-https \
        libx11-xcb1 \
        libxcb-dri3-0 \
        libdrm-intel1 \
        libdrm-radeon1 \
        libasound2 \
        libatk1.0-0 \
        libgtk-3-0 \
        libnss3 \
        libxss1 \
        libxkbfile1 \
        libsecret-1-0

# Download and install VSCode
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    apt-get update && \
    apt-get install -y code

# Set the working directory
WORKDIR /app

# Copy the application code into the container
COPY . /app

# Default command to run your application
CMD ["python3", "app.py"]
