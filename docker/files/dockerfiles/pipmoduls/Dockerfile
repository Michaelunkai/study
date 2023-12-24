# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install required packages
RUN pip install --no-cache-dir \
    wolframalpha \
    pyttsx3 \
    tk \
    jsonlib \
    random2 \
    SpeechRecognition \
    DateTime \
    wikipedia \
    webbrowser \
    pyjokes \
    feedparser \
    twilio \
    clint \
    ecapture \
    beautifulsoup4

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
